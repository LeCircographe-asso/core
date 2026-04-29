module Admin
  class SubscriptionPlansController < BaseController
    before_action :set_contribution_formula, only: %i[show edit update destroy]
    before_action :set_person, only: %i[new create]
    before_action :set_breadcrumbs
    before_action :require_super_admin, only: %i[edit update destroy]

    def index
      @contribution_formulas = ContributionFormula.includes(:membership_type).all.order(:duration, :price_cents)
      add_breadcrumb 'Plans de cotisation', nil
    end

    def show
      @contributions = @contribution_formula.contributions.includes(:person)
      add_breadcrumb "Plan: #{@contribution_formula.name}", nil
    end

    def new
      @person = Person.find(params[:person_id]) if params[:person_id]

      unless @person&.can_buy_contribution_formulas?
        flash[:alert] = 'Cette personne doit avoir une adhésion Cirque pour acheter des plans de cotisation'
        redirect_to admin_users_path
        return
      end

      @contribution_formulas = ContributionFormula.available_for(@person)

      add_breadcrumb 'Nouvelle cotisation', nil
    end

    def edit
      add_breadcrumb "Modifier: #{@contribution_formula.name}", nil
    end

    def create
      @person = Person.find(contribution_purchase_params[:person_id])

      custom_amount = (contribution_purchase_params[:custom_amount_cents]&.to_i || 0 if contribution_purchase_params[:payment_method] == 'offered')
      donation_cents = donation_cents_from(contribution_purchase_params)

      result = People::ContributionCreator.new(
        person: @person,
        contribution_formula_id: contribution_purchase_params[:contribution_formula_id] || contribution_purchase_params[:subscription_plan_id],
        payment_method: contribution_purchase_params[:payment_method].presence || 'cash',
        recorded_by_id: Current.user&.id,
        record_attendance: false,
        custom_amount_cents: custom_amount,
        offer_reason: contribution_purchase_params[:offer_reason],
        donation_cents: donation_cents
      ).call

      if result.success?
        redirect_to admin_user_path("person_#{@person.id}"), notice: 'Plan de cotisation acheté avec succès !'
      else
        redirect_to new_admin_subscription_plan_path(person_id: @person.id),
                    alert: "Erreur lors de l'achat du plan: #{result.message}"
      end
    rescue StandardError => e
      flash[:alert] = "Erreur lors de l'achat du plan: #{e.message}"
      redirect_to new_admin_subscription_plan_path(person_id: @person.id)
    end

    def update
      if @contribution_formula.update(contribution_formula_params)
        redirect_to admin_subscription_plans_path, notice: 'Plan de cotisation mis à jour avec succès !'
      else
        flash.now[:alert] = @contribution_formula.errors.full_messages.to_sentence
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      if @contribution_formula.destroy
        redirect_to admin_subscription_plans_path, notice: 'Plan de cotisation supprimé avec succès !'
      else
        redirect_to admin_subscription_plans_path, alert: @contribution_formula.errors.full_messages.to_sentence
      end
    end

    private

    def require_super_admin
      return if Current.user&.super_admin?

      redirect_to admin_subscription_plans_path, alert: 'Seul le super-admin peut modifier ou supprimer des cotisations.'
    end

    def set_contribution_formula
      @contribution_formula = ContributionFormula.find(params[:id])
    end

    def set_person
      @person = Person.find(params[:person_id]) if params[:person_id]
    end

    def set_breadcrumbs
      add_breadcrumb 'Administration', admin_dashboard_index_path
      add_breadcrumb 'Plans de cotisation', admin_subscription_plans_path
    end

    def contribution_formula_params
      params.require(:contribution_formula).permit(:name, :duration, :price_cents, :description, :membership_type_id, :sessions_count, :validity_days).tap do |permitted|
        legacy = params[:subscription_plan]
        permitted.merge!(legacy.permit(:name, :duration, :price_cents, :description, :membership_type_id, :sessions_count, :validity_days)) if legacy.respond_to?(:permit)
      end
    rescue ActionController::ParameterMissing
      params.require(:subscription_plan).permit(:name, :duration, :price_cents, :description, :membership_type_id, :sessions_count, :validity_days)
    end

    def contribution_purchase_params
      key = params.key?(:contribution_formula) ? :contribution_formula : :subscription_plan
      params.require(key).permit(:person_id, :contribution_formula_id, :subscription_plan_id, :payment_method, :record_attendance, :attendance_date, :custom_amount_cents, :offer_reason, :donation_amount).merge(
        recorded_by_id: Current.user.id
      )
    end

    def donation_cents_from(params_hash)
      return nil if params_hash[:donation_amount].blank?

      cents = (params_hash[:donation_amount].to_f * 100).to_i
      cents.positive? ? cents : nil
    end
  end
end
