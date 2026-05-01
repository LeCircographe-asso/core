# frozen_string_literal: true

module Admin
  class DonationsController < BaseController
    before_action :set_breadcrumbs

    def new
      return unless assign_person_context!

      add_breadcrumb I18n.t("admin.donations.new.title"), nil
    end

    def create
      return unless assign_person_context!

      result = build_payment_creator.call

      if result.success?
        redirect_to admin_payment_path(result.payment), notice: t(".recorded")
      else
        render_creation_error(result.message)
      end
    rescue StandardError => e
      render_creation_error(e.message)
    end

    private

    def set_breadcrumbs
      add_breadcrumb I18n.t("breadcrumbs.admin.common.administration"), admin_dashboard_index_path
    end

    def assign_person_context!
      if params[:person_id].present?
        @person = Person.find(params[:person_id])
        @user = @person.user
        true
      elsif params[:user_id].present?
        @user = User.find(params[:user_id])
        @person = @user.person
        true
      else
        redirect_to admin_users_path, alert: I18n.t("admin.donations.new.missing_person")
        false
      end
    end

    def payment_params
      params.expect(payment: %i[payment_amount payment_date payment_type status donation total_payment user_id person_id])
    end

    def build_payment_creator
      People::PaymentCreator.new(
        person: @person,
        amount_cents: payment_amount_cents,
        payment_method: "cash",
        recorded_by_id: Current.user&.id,
        item_type: "Donation",
        item_id: @person.id,
        description: "Donation",
        notes: "Donation"
      )
    end

    def payment_amount_cents
      (payment_params[:payment_amount].to_f * 100).to_i
    end

    def render_creation_error(message)
      flash[:alert] = "Erreur lors de la création de la donation: #{message}"
      add_breadcrumb I18n.t("admin.donations.new.title"), nil
      render :new, status: :unprocessable_content
    end
  end
end
