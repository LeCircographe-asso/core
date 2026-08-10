# frozen_string_literal: true

module Admin
  class ContributionsController < BaseController
    PURCHASE_ATTRS = %i[
      contribution_formula_id
      payment_method
      record_attendance
      attendance_date
      custom_amount_cents
      offer_reason
      donation_amount
    ].freeze

    before_action :set_person, only: %i[create upgrade]
    before_action :set_person_for_new, only: %i[new]
    before_action :set_breadcrumbs, only: %i[new create]

    def new
      unless @person
        redirect_to admin_members_path, alert: t(".person_required_alert") and return
      end

      unless @person.can_buy_contribution_formulas?
        flash[:alert] = t(".needs_circus_membership_alert")
        redirect_to admin_person_path(@person)
        return
      end

      @contribution_formulas = ContributionFormula.available_for(@person)
    end

    def create
      custom_amount = (contribution_purchase_params[:custom_amount_cents].to_i if contribution_purchase_params[:payment_method] == "offered")
      donation_cents = donation_cents_from(contribution_purchase_params)

      result = People::ContributionCreator.new(
        person: @person,
        contribution_formula_id: contribution_purchase_params[:contribution_formula_id],
        payment_method: contribution_purchase_params[:payment_method].presence || "cash",
        recorded_by_id: Current.user&.id,
        record_attendance: false,
        custom_amount_cents: custom_amount,
        offer_reason: contribution_purchase_params[:offer_reason],
        donation_cents: donation_cents
      ).call

      if result.success?
        redirect_to admin_person_path(@person), notice: t(".purchased")
      else
        redirect_to new_admin_contribution_path(person_id: @person.id),
                    alert: t(".purchase_failed_alert", message: result.message)
      end
    rescue StandardError => e
      flash[:alert] = t(".purchase_failed_alert", message: e.message)
      redirect_to new_admin_contribution_path(person_id: @person.id)
    end

    def upgrade
      result = build_contribution_upgrader.call

      if result.success?
        redirect_to admin_person_path(@person), notice: upgrade_notice_for(result)
      else
        redirect_to admin_person_path(@person), alert: upgrade_failure_message(result.message)
      end
    rescue StandardError => e
      redirect_to admin_person_path(@person), alert: upgrade_failure_message(e.message)
    end

    private

    def set_person
      @person = Person.find(params[:person_id])
    end

    def set_person_for_new
      @person = Person.find(params[:person_id]) if params[:person_id].present?
    end

    def set_breadcrumbs
      add_breadcrumb I18n.t("breadcrumbs.admin.common.administration"), admin_dashboard_index_path
      add_person_context_breadcrumbs(@person, I18n.t("breadcrumbs.admin.contributions.new_contribution")) if @person.present?
    end

    def admin_person_path(person)
      admin_member_path(person)
    end

    def contribution_purchase_params
      params.expect(contribution: PURCHASE_ATTRS).merge(recorded_by_id: Current.user.id)
    end

    def donation_cents_from(params_hash)
      return nil if params_hash[:donation_amount].blank?

      cents = (params_hash[:donation_amount].to_f * 100).to_i
      cents.positive? ? cents : nil
    end

    def build_contribution_upgrader
      People::ContributionUpgrader.new(
        person: @person,
        from_contribution_id: source_contribution_id,
        to_formula_id: target_formula_id,
        payment_method: params[:payment_method].presence || "cash",
        recorded_by_id: Current.user.id,
        offer_reason: params[:offer_reason]
      )
    end

    def source_contribution_id
      params[:from_contribution_id].presence || params[:from_book_id]
    end

    def target_formula_id
      params[:to_formula_id].presence || params[:to_plan_id]
    end

    def upgrade_notice_for(result)
      return t(".success_notice") unless result.credit_applied.positive?

      t(".success_notice") + t(".credit_applied_suffix", amount: (result.credit_applied / 100.0).round(2))
    end

    def upgrade_failure_message(message)
      t(".failure_alert", message: message)
    end
  end
end
