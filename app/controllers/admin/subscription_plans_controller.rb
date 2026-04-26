module Admin
  class SubscriptionPlansController < BaseController
    before_action :set_subscription_plan, only: [ :show, :edit, :update, :destroy ]
    before_action :set_person, only: [ :new, :create ]
    before_action :set_breadcrumbs
    before_action :require_super_admin, only: [ :edit, :update, :destroy ]

    def index
      @subscription_plans = SubscriptionPlan.includes(:membership_type).all.order(:duration, :price_cents)
    add_breadcrumb "Plans de cotisation", nil
    end

    def show
      @book_of_entries = @subscription_plan.book_of_entries.includes(:person)
      add_breadcrumb "Plan: #{@subscription_plan.name}", nil
    end

    def new
      @person = Person.find(params[:person_id]) if params[:person_id]

      # Vérifier que la personne peut acheter des plans de cotisation
      unless @person&.can_buy_subscription_plans?
        flash[:alert] = "Cette personne doit avoir une adhésion Cirque pour acheter des plans de cotisation"
        redirect_to admin_users_path
        return
      end

      # Filtrer les plans de cotisation selon le type d'adhésion de la personne
      @subscription_plans = SubscriptionPlan.available_for(@person)

      add_breadcrumb "Nouvelle cotisation", nil
    end

    def edit
      add_breadcrumb "Modifier: #{@subscription_plan.name}", nil
    end

    def update
      if @subscription_plan.update(subscription_plan_params)
        redirect_to admin_subscription_plans_path, notice: "Plan de cotisation mis à jour avec succès !"
      else
        flash.now[:alert] = @subscription_plan.errors.full_messages.to_sentence
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      if @subscription_plan.destroy
        redirect_to admin_subscription_plans_path, notice: "Plan de cotisation supprimé avec succès !"
      else
        redirect_to admin_subscription_plans_path, alert: @subscription_plan.errors.full_messages.to_sentence
      end
    end

    def create
      @person = Person.find(subscription_purchase_params[:person_id])

      custom_amount = if subscription_purchase_params[:payment_method] == "offered"
                        subscription_purchase_params[:custom_amount_cents]&.to_i || 0
      end
      donation_cents = donation_cents_from(subscription_purchase_params)

      result = People::SubscriptionCreator.new(
        person: @person,
        subscription_plan_id: subscription_purchase_params[:subscription_plan_id],
        payment_method: subscription_purchase_params[:payment_method].presence || "cash",
        recorded_by_id: Current.user&.id,
        record_attendance: false,
        custom_amount_cents: custom_amount,
        offer_reason: subscription_purchase_params[:offer_reason],
        donation_cents: donation_cents
      ).call

      if result.success?
        redirect_to admin_user_path("person_#{@person.id}"), notice: "Plan de cotisation acheté avec succès !"
      else
        redirect_to new_admin_subscription_plan_path(person_id: @person.id),
                    alert: "Erreur lors de l'achat du plan: #{result.message}"
      end
    rescue => e
      flash[:alert] = "Erreur lors de l'achat du plan: #{e.message}"
      redirect_to new_admin_subscription_plan_path(person_id: @person.id)
    end

    private

    def require_super_admin
      unless Current.user&.super_admin?
        redirect_to admin_subscription_plans_path, alert: "Seul le super-admin peut modifier ou supprimer des cotisations."
      end
    end

    def set_subscription_plan
      @subscription_plan = SubscriptionPlan.find(params[:id])
    end

    def set_person
      @person = Person.find(params[:person_id]) if params[:person_id]
    end

    def set_breadcrumbs
      add_breadcrumb "Administration", admin_dashboard_index_path
      add_breadcrumb "Plans de cotisation", admin_subscription_plans_path
    end

    def subscription_params
      params.require(:subscription_plan).permit(:person_id, :subscription_plan_id, :payment_method)
    end

    def subscription_plan_params
      params.require(:subscription_plan).permit(:name, :duration, :price_cents, :description, :membership_type_id, :sessions_count, :validity_days)
    end

    def subscription_purchase_params
      params.require(:subscription_plan).permit(:person_id, :subscription_plan_id, :payment_method, :record_attendance, :attendance_date, :custom_amount_cents, :offer_reason, :donation_amount).merge(
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
