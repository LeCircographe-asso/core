module Admin
  class SubscriptionPlansController < BaseController
    before_action :set_subscription_plan, only: [ :show, :edit, :update, :destroy ]
    before_action :set_person, only: [ :new, :create ]
    before_action :set_breadcrumbs

    def index
      @subscription_plans = SubscriptionPlan.includes(:membership_type).all.order(:duration, :price_cents)
      add_breadcrumb "Plans d'Abonnement", nil
    end

    def show
      @book_of_entries = @subscription_plan.book_of_entries.includes(:person)
      add_breadcrumb "Plan: #{@subscription_plan.name}", nil
    end

    def new
      @person = Person.find(params[:person_id]) if params[:person_id]

      # Vérifier que la personne peut acheter des plans d'abonnement
      unless @person&.can_buy_subscription_plans?
        flash[:alert] = "Cette personne doit avoir une adhésion Cirque pour acheter des plans d'abonnement"
        redirect_to admin_users_path
        return
      end

      # Filtrer les plans d'abonnement selon le type d'adhésion de la personne
      if @person&.current_membership&.membership_type&.circus?
        @subscription_plans = SubscriptionPlan.joins(:membership_type)
                                            .where(membership_types: { category: [ :circus_full, :circus_reduced ] })
                                            .current_versions
                                            .order(:duration, :price_cents)
      else
        @subscription_plans = []
      end

      add_breadcrumb "Nouvel abonnement", nil
    end

    def edit
      add_breadcrumb "Modifier: #{@subscription_plan.name}", nil
    end

    def update
      if @subscription_plan.update(subscription_plan_params)
        redirect_to admin_subscription_plans_path, notice: "Plan d'abonnement mis à jour avec succès !"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      # Seul le super_admin peut supprimer des cotisations
      unless Current.user&.system_role == "super_admin"
        redirect_to admin_subscription_plans_path, alert: "Seul le super-admin peut supprimer des cotisations."
        return
      end

      if @subscription_plan.book_of_entries.any?
        redirect_to admin_subscription_plans_path, alert: "Impossible de supprimer ce plan car il est utilisé par des carnets d'entrées."
      else
        @subscription_plan.destroy
        redirect_to admin_subscription_plans_path, notice: "Plan d'abonnement supprimé avec succès !"
      end
    end

    def create
      @person = Person.find(subscription_purchase_params[:person_id])
      subscription_plan = SubscriptionPlan.find(subscription_purchase_params[:subscription_plan_id])

      begin
        result = @person.create_subscription!(
          subscription_plan,
          payment_method: subscription_purchase_params[:payment_method],
          recorded_by: Current.user,
          record_attendance: subscription_purchase_params[:record_attendance]
        )

        redirect_to admin_user_path("person_#{@person.id}"), notice: "Plan d'abonnement acheté avec succès !"
      rescue => e
        flash[:alert] = "Erreur lors de l'achat du plan: #{e.message}"
        redirect_to new_admin_subscription_plan_path(person_id: @person.id)
      end
    end

    private

    def set_subscription_plan
      @subscription_plan = SubscriptionPlan.find(params[:id])
    end

    def set_person
      @person = Person.find(params[:person_id]) if params[:person_id]
    end

    def set_breadcrumbs
      add_breadcrumb "Administration", admin_dashboard_index_path
      add_breadcrumb "Plans d'Abonnement", admin_subscription_plans_path
    end

    def subscription_params
      params.require(:subscription_plan).permit(:person_id, :subscription_plan_id, :payment_method)
    end

    def subscription_plan_params
      params.require(:subscription_plan).permit(:name, :duration, :price_cents, :description, :membership_type_id, :sessions_count, :validity_days)
    end

    def subscription_purchase_params
      params.require(:subscription_plan).permit(:person_id, :subscription_plan_id, :payment_method, :record_attendance, :attendance_date).merge(
        recorded_by_id: Current.user.id
      )
    end
  end
end
