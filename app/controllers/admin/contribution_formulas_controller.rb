# frozen_string_literal: true

module Admin
  class ContributionFormulasController < BaseController
    before_action :set_contribution_formula, only: %i[show edit update destroy change_price archive unarchive]
    before_action :set_breadcrumbs
    before_action :require_admin_rights, only: %i[new create edit update destroy change_price archive unarchive]

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
      @contribution_formula = ContributionFormula.new(
        effective_from: Date.current,
        rate_kind: "standard",
        version: 1,
        created_by_user: Current.user
      )
      add_breadcrumb I18n.t("breadcrumbs.admin.contribution_formulas.new_formula"), nil
    end

    def edit
      add_breadcrumb I18n.t("breadcrumbs.admin.contribution_formulas.edit_named", name: @contribution_formula.name), nil
    end

    def create
      @contribution_formula = ContributionFormula.new(contribution_formula_create_params.merge(created_by_user: Current.user))

      if @contribution_formula.save
        redirect_to admin_contribution_formulas_path, notice: t(".success")
      else
        flash.now[:alert] = @contribution_formula.errors.full_messages.to_sentence
        render :new, status: :unprocessable_content
      end
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

    def unarchive
      @contribution_formula.unarchive!(user: Current.user)
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

    def set_contribution_formula
      @contribution_formula = ContributionFormula.find(params[:id])
    end

    def set_breadcrumbs
      add_breadcrumb I18n.t("breadcrumbs.admin.common.dashboard"), admin_dashboard_index_path
      add_breadcrumb I18n.t("breadcrumbs.admin.contribution_formulas.catalog"), admin_contribution_formulas_path
    end

    def contribution_formula_create_params
      params.expect(contribution_formula: %i[name description duration rate_kind membership_type_id price_euros sessions_count validity_days effective_from])
    end

    # Édition classique : nom/description seulement. duration/rate_kind/
    # membership_type_id/sessions_count/validity_days définissent ce que
    # signifie la formule pour les Contribution déjà achetées — les changer en
    # place réinterpréterait silencieusement un achat passé. Prix : #change_price.
    def contribution_formula_update_params
      params.expect(contribution_formula: %i[name description])
    end
  end
end
