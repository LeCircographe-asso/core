# frozen_string_literal: true

module Admin
  module Users
    # Admin::Users::PaymentsController handles payment management
    # for specific users/persons. This controller is responsible for:
    # - Creating new payments
    # - Processing payments
    # - Managing payment-related operations
    class PaymentsController < BaseController
      before_action :set_person
      before_action :set_breadcrumbs

      # GET /admin/users/person_1/payments
      def index
        @payments = @person.payments.includes(:payment_lines, :recorded_by)
                           .order(created_at: :desc)
                           .page(params[:page])
      end

      # GET /admin/users/person_1/payments/1
      def show
        @payment = @person.payments.find(params[:id])
      end

      # GET /admin/users/person_1/payments/new
      def new
        @payment = @person.payments.build
        @payment.recorded_by = Current.user
        @membership_types = MembershipType.all
        @contribution_formulas = ContributionFormula.all
      end

      # POST /admin/users/person_1/payments
      def create
        normalized_lines = normalize_payment_lines(params[:payment_lines])

        total_cents = if normalized_lines.any?
                        normalized_lines.sum { |line| line[:amount_cents].to_i }
        else
                        payment_params[:total_cents].to_i
        end

        service_params = {
          person: @person,
          payment_method: payment_params[:payment_method] || "cash",
          recorded_by_id: Current.user&.id,
          notes: payment_params[:notes]
        }

        if normalized_lines.any?
          service_params[:payment_lines] = normalized_lines
          service_params[:total_cents] = total_cents
        else
          first_line = normalized_lines.first
          service_params[:amount_cents] = total_cents
          service_params[:item_type] = first_line ? first_line[:item_type] : "Donation"
          service_params[:item_id] = first_line ? first_line[:item_id] : @person.id
          service_params[:description] = first_line ? first_line[:description] : "Paiement"
        end

        result = People::PaymentCreator.new(service_params).call

        if result.success?
          redirect_to admin_person_path(@person), notice: t(".success")
        else
          @membership_types = MembershipType.all
          @contribution_formulas = ContributionFormula.all
          flash.now[:alert] = t(".failure_alert", message: result.message)
          render :new, status: :unprocessable_content
        end
      rescue StandardError => e
        @membership_types = MembershipType.all
        @contribution_formulas = ContributionFormula.all
        flash.now[:alert] = t(".failure_alert", message: e.message)
        render :new, status: :unprocessable_content
      end

      # PATCH /admin/users/person_1/payments/1
      def update
        @payment = @person.payments.find(params[:id])

        total_cents = payment_params[:total_cents]
        total_cents = (total_cents.to_f * 100).to_i if total_cents.present?

        result = People::PaymentUpdater.new(
          payment_id: @payment.id,
          total_cents: total_cents || @payment.total_cents,
          payment_method: payment_params[:payment_method] || @payment.payment_method,
          status: payment_params[:status] || @payment.status,
          notes: payment_params[:notes] || @payment.notes,
          updated_by_id: Current.user.id
        ).call

        if result.success?
          redirect_to admin_person_path(@person), notice: t(".success")
        else
          redirect_to admin_person_path(@person), alert: t(".failure_alert", message: result.message)
        end
      end

      # DELETE /admin/users/person_1/payments/1
      def destroy
        @payment = @person.payments.find(params[:id])

        result = People::PaymentCanceller.new(
          payment_id: @payment.id,
          deleted_by_id: Current.user.id,
          reason: "Suppression via interface admin"
        ).call

        if result.success?
          redirect_to admin_person_path(@person), notice: t(".destroyed")
        else
          redirect_to admin_person_path(@person), alert: t(".failure_alert", message: result.message)
        end
      end

      # POST /admin/users/person_1/payments/1/process
      def process_payment
        @payment = @person.payments.find(params[:id])

        begin
          if @payment.pending?
            result = People::PaymentUpdater.new(
              payment_id: @payment.id,
              status: "success",
              updated_by_id: Current.user.id
            ).call

            if result.success?
              redirect_to admin_person_path(@person), notice: t(".processed")
            else
              redirect_to admin_person_path(@person), alert: t(".failure_alert", message: result.message)
            end
          else
            redirect_to admin_person_path(@person), notice: t(".already_processed")
          end
        rescue StandardError => e
          redirect_to admin_person_path(@person), alert: t(".failure_alert", message: e.message)
        end
      end

      private

      def set_person
        identifier = params[:person_id].presence || params[:user_id].presence
        raise ActiveRecord::RecordNotFound, "person identifier missing" if identifier.blank?

        if Admin::Users::PersonRouteKey.person_identifier?(identifier)
          person_id = Admin::Users::PersonRouteKey.extract(identifier)
          @person = Person.find(person_id)
        else
          user = User.find(identifier)
          @person = user.person || Person.find(identifier)
        end
      end

      def set_breadcrumbs
        add_breadcrumb I18n.t("breadcrumbs.admin.users.members_list"), admin_users_path
        add_breadcrumb @person.full_name, admin_person_path(@person)
        add_breadcrumb I18n.t("breadcrumbs.admin.payments.management"), nil
      end

      def admin_person_path(person)
        admin_user_path(Admin::Users::PersonRouteKey.call(person))
      end

      def payment_params
        params.expect(
          payment: %i[total_cents
                      payment_method
                      status
                      notes
                      recorded_by_id]
        )
      end

      def normalize_payment_lines(lines_param)
        Array(lines_param).compact_blank.map do |line|
          line = line.to_unsafe_h if line.respond_to?(:to_unsafe_h)
          line.symbolize_keys
        end
      end
    end
  end
end
