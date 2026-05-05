# frozen_string_literal: true

module Admin
  class ContributionFormulasController < BaseController
    FORMULA_ATTRS = %i[name duration rate_kind price_cents description membership_type_id sessions_count validity_days].freeze
    PURCHASE_ATTRS = %i[
      person_id
      contribution_formula_id
      payment_method
      record_attendance
      attendance_date
      custom_amount_cents
      offer_reason
      donation_amount
    ].freeze

    before_action :set_contribution_formula, only: %i[show edit update destroy]
    before_action :set_person, only: %i[new create]
    before_action :set_breadcrumbs
    before_action :require_super_admin, only: %i[edit update destroy]

    def index
      @contribution_formulas = ContributionFormula.includes(:membership_type).order(:duration, :price_cents)
      add_breadcrumb I18n.t("breadcrumbs.admin.contribution_formulas.catalog"), nil
    end

    def show
      @contributions = @contribution_formula.contributions.includes(:person)
      add_breadcrumb I18n.t("breadcrumbs.admin.contribution_formulas.formula_named", name: @contribution_formula.name), nil
    end

    def new
      @person = Person.find(params[:person_id]) if params[:person_id]

      unless @person&.can_buy_contribution_formulas?
        flash[:alert] = t(".needs_circus_membership_alert")
        redirect_to admin_person_path(@person)
        return
      end

      @contribution_formulas = ContributionFormula.available_for(@person)

      add_breadcrumb I18n.t("breadcrumbs.admin.contribution_formulas.new_contribution"), nil
    end

    def edit
      add_breadcrumb I18n.t("breadcrumbs.admin.contribution_formulas.edit_named", name: @contribution_formula.name), nil
    end

    def create
      @person = Person.find(contribution_purchase_params[:person_id])

      custom_amount = (contribution_purchase_params[:custom_amount_cents].to_i if contribution_purchase_params[:payment_method] == "offered")
      donation_cents = donation_cents_from(contribution_purchase_params)

      result = People::ContributionCreator.new(
        person: @person,
        contribution_formula_id: contribution_formula_id_from_purchase_params,
        payment_method: contribution_purchase_params[:payment_method].presence || "cash",
        recorded_by_id: Current.user&.id,
        record_attendance: false,
        custom_amount_cents: custom_amount,
        offer_reason: contribution_purchase_params[:offer_reason],
        donation_cents: donation_cents
      ).call

      if result.success?
        redirect_to admin_member_path(@person), notice: t(".purchased")
      else
        redirect_to new_admin_contribution_formula_path(person_id: @person.id),
                    alert: t(".purchase_failed_alert", message: result.message)
      end
    rescue StandardError => e
      flash[:alert] = t(".purchase_failed_alert", message: e.message)
      redirect_to new_admin_contribution_formula_path(person_id: @person.id)
    end

    def update
      if @contribution_formula.update(contribution_formula_params)
        redirect_to admin_contribution_formulas_path, notice: t(".updated")
      else
        flash.now[:alert] = @contribution_formula.errors.full_messages.to_sentence
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      if @contribution_formula.destroy
        redirect_to admin_contribution_formulas_path, notice: t(".destroyed")
      else
        redirect_to admin_contribution_formulas_path, alert: @contribution_formula.errors.full_messages.to_sentence
      end
    end

    private

    def contribution_formula_id_from_purchase_params
      contribution_purchase_params[:contribution_formula_id]
    end

    def require_super_admin
      return if Current.user&.super_admin?

      redirect_to admin_contribution_formulas_path, alert: I18n.t("admin.contribution_formulas.require_super_admin.forbidden")
    end

    def set_contribution_formula
      @contribution_formula = ContributionFormula.find(params[:id])
    end

    def set_person
      @person = Person.find(params[:person_id]) if params[:person_id]
    end

    def set_breadcrumbs
      add_breadcrumb I18n.t("breadcrumbs.admin.common.administration"), admin_dashboard_index_path
      if @person.present?
        add_person_context_breadcrumbs(@person, I18n.t("breadcrumbs.admin.contribution_formulas.new_contribution"))
      else
        add_breadcrumb I18n.t("breadcrumbs.admin.contribution_formulas.catalog"), admin_contribution_formulas_path
      end
    end

    def contribution_formula_params
      params.expect(contribution_formula: FORMULA_ATTRS)
    end

    def contribution_purchase_params
      params.expect(contribution_formula: PURCHASE_ATTRS).merge(recorded_by_id: Current.user.id)
    end

    def donation_cents_from(params_hash)
      return nil if params_hash[:donation_amount].blank?

      cents = (params_hash[:donation_amount].to_f * 100).to_i
      cents.positive? ? cents : nil
    end
  end
end
