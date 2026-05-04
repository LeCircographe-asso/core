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

      # GET /admin/users/person_1/payments
      def index
        redirect_to filtered_payments_path
      end

      # GET /admin/users/person_1/payments/1
      def show
        redirect_to filtered_payments_path
      end

      # GET /admin/users/person_1/payments/new
      def new
        redirect_to filtered_payments_path
      end

      # POST /admin/users/person_1/payments
      def create
        normalized_lines = normalize_payment_lines(params[:payment_lines])
        lines = normalized_lines.presence || direct_payment_lines
        total_cents = lines.sum { |line| line[:amount_cents].to_i }

        result = People::PaymentRecorder.new(
          person: @person,
          payment_method: payment_params[:payment_method] || "cash",
          recorded_by: Current.user,
          status: "success",
          notes: payment_params[:notes],
          total_cents: total_cents,
          payment_lines: lines
        ).call

        if result.success?
          redirect_to filtered_payments_path, notice: t(".success")
        else
          redirect_to filtered_payments_path, alert: t(".failure_alert", message: result.message)
        end
      rescue StandardError => e
        redirect_to filtered_payments_path, alert: t(".failure_alert", message: e.message)
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
          redirect_to filtered_payments_path, notice: t(".success")
        else
          redirect_to filtered_payments_path, alert: t(".failure_alert", message: result.message)
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
          redirect_to filtered_payments_path, notice: t(".destroyed")
        else
          redirect_to filtered_payments_path, alert: t(".failure_alert", message: result.message)
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
              redirect_to filtered_payments_path, notice: t(".processed")
            else
              redirect_to filtered_payments_path, alert: t(".failure_alert", message: result.message)
            end
          else
            redirect_to filtered_payments_path, notice: t(".already_processed")
          end
        rescue StandardError => e
          redirect_to filtered_payments_path, alert: t(".failure_alert", message: e.message)
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

      def direct_payment_lines
        [
          {
            item_type: "Donation",
            amount_cents: payment_params[:total_cents].to_i,
            description: "Paiement direct"
          }
        ]
      end

      def filtered_payments_path
        admin_payments_path(person_id: @person.id)
      end
    end
  end
end
