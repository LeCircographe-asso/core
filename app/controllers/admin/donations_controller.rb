# frozen_string_literal: true

module Admin
  class DonationsController < BaseController
    def new
      return unless assign_person_context!

      set_breadcrumbs
    end

    def create
      return unless assign_person_context!

      result = build_payment_recorder.call

      if result.success?
        redirect_to admin_payments_path(person_id: @person.id), notice: t(".recorded")
      else
        render_creation_error(result.message)
      end
    rescue StandardError => e
      render_creation_error(e.message)
    end

    private

    def set_breadcrumbs
      add_breadcrumb I18n.t("breadcrumbs.admin.common.dashboard"), admin_dashboard_index_path
      add_person_context_breadcrumbs(@person, I18n.t("admin.donations.new.title"))
    end

    def assign_person_context!
      if params[:person_id].present?
        @person = Person.find(params.expect(:person_id))
        @user = @person.user
        true
      elsif params[:user_id].present?
        @user = User.find(params.expect(:user_id))
        @person = @user.person
        true
      else
        redirect_to admin_members_path, alert: I18n.t("admin.donations.new.missing_person")
        false
      end
    end

    def payment_params
      params.expect(payment: %i[payment_amount payment_date payment_type status donation total_payment user_id person_id])
    end

    def build_payment_recorder
      People::PaymentRecorder.new(
        person: @person,
        payment_method: "cash",
        recorded_by: Current.user,
        status: "success",
        notes: "Donation",
        total_cents: payment_amount_cents,
        payment_lines: [
          {
            item_type: "Donation",
            amount_cents: payment_amount_cents,
            description: "Donation"
          }
        ]
      )
    end

    def payment_amount_cents
      (payment_params[:payment_amount].to_f * 100).to_i
    end

    def render_creation_error(message)
      flash[:alert] = "Erreur lors de la création de la donation: #{message}"
      set_breadcrumbs
      render :new, status: :unprocessable_content
    end
  end
end
