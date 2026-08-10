# frozen_string_literal: true

module Admin
  class ContributionFormulasController < BaseController
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

    before_action :set_contribution_formula, only: %i[show edit update destroy change_price archive]
    before_action :set_person, only: %i[new create]
    before_action :set_breadcrumbs
    before_action :require_super_admin, only: %i[edit update destroy change_price archive]

    def index
      @contribution_formulas = ContributionFormula.current_versions.includes(:membership_type).order(:duration, :price_cents)
      @archived_contribution_formulas = ContributionFormula.where.not(effective_until: nil).includes(:membership_type).order(effective_until: :desc)
      add_breadcrumb I18n.t("breadcrumbs.admin.contribution_formulas.catalog"), nil
    end

    def show
      @contributions = @contribution_formula.contributions.includes(:person)
      add_breadcrumb I18n.t("breadcrumbs.admin.contribution_formulas.formula_named", name: @contribution_formula.name), nil
    end

    def new
      unless @person&.can_buy_contribution_formulas?
        flash[:alert] = t(".needs_circus_membership_alert")
        redirect_to(@person ? admin_person_path(@person) : admin_members_path)
        return
      end

      @contribution_formulas = ContributionFormula.available_for(@person)
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

    # Édition classique : jamais le prix, la version ou effective_from — ces
    # champs identifient la ligne pour l'historique/la compta, ils passent
    # uniquement par #change_price (create_price_change!). Voir docs/architecture/models.md §4.8.
    def update
      if @contribution_formula.update(contribution_formula_update_params)
        redirect_to admin_contribution_formulas_path, notice: t(".updated")
      else
        flash.now[:alert] = @contribution_formula.errors.full_messages.to_sentence
        render :edit, status: :unprocessable_content
      end
    end

    def change_price
      new_price_cents = (params[:price].to_f * 100).round

      @contribution_formula.create_price_change!(new_price_cents, reason: params[:reason], user: Current.user)
      redirect_to admin_contribution_formulas_path, notice: t(".success")
    rescue ActiveRecord::RecordInvalid => e
      redirect_to edit_admin_contribution_formula_path(@contribution_formula), alert: t(".failure", message: e.message)
    end

    def archive
      @contribution_formula.archive!(user: Current.user)
      redirect_to admin_contribution_formulas_path, notice: t(".success")
    rescue ActiveRecord::RecordInvalid => e
      redirect_to admin_contribution_formulas_path, alert: t(".failure", message: e.message)
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

    # Édition classique : nom/description seulement. duration/rate_kind/
    # membership_type_id/sessions_count/validity_days définissent ce que
    # signifie la formule pour les Contribution déjà achetées — les changer en
    # place réinterpréterait silencieusement un achat passé. Prix : #change_price.
    def contribution_formula_update_params
      params.expect(contribution_formula: %i[name description])
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
