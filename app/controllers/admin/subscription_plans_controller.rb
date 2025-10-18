module Admin
  class SubscriptionPlansController < BaseController
    before_action :set_person, only: [:show, :new, :create]
    before_action :set_breadcrumbs

    def index
      @subscription_plans = SubscriptionPlan.includes(:membership_type).all
      add_breadcrumb "Plans d'Abonnement", nil
    end

    def show
      @subscription_plan = SubscriptionPlan.find(params[:id])
      @book_of_entries = @subscription_plan.book_of_entries.includes(:person)
      add_breadcrumb "Plan: #{@subscription_plan.name}", nil
    end

    def new
      @subscription_plans = SubscriptionPlan.all
      @person = Person.find(params[:person_id]) if params[:person_id]
      
      # Vérifier que la personne peut acheter des plans d'abonnement
      unless @person&.can_buy_subscription_plans?
        flash[:alert] = "Cette personne doit avoir une adhésion Cirque pour acheter des plans d'abonnement"
        redirect_to admin_users_path
        return
      end
      
      add_breadcrumb "Nouvel abonnement", nil
    end

    def create
      @person = Person.find(subscription_params[:person_id])
      @subscription_plan = SubscriptionPlan.find(subscription_params[:subscription_plan_id])
      
      # Créer le carnet d'entrées (BookOfEntry)
      book_of_entry = @person.book_of_entries.create!(
        subscription_plan: @subscription_plan,
        sessions_remaining: @subscription_plan.sessions_count || 0,
        purchased_at: Time.current,
        expires_at: @subscription_plan.validity_days.days.from_now,
        status: :active
      )

      # Créer le paiement
      payment = Payment.create!(
        person: @person,
        recorded_by: Current.user,
        total_cents: @subscription_plan.price_cents,
        payment_method: subscription_params[:payment_method] || :cash,
        status: :success,
        notes: "Plan d'abonnement #{@subscription_plan.name}"
      )

      # Créer la ligne de paiement
      PaymentLine.create!(
        payment: payment,
        item: book_of_entry,
        amount_cents: @subscription_plan.price_cents,
        description: "Plan d'abonnement #{@subscription_plan.name}"
      )

      redirect_to admin_subscription_plan_path(@subscription_plan), notice: "Plan d'abonnement acheté avec succès"
    rescue => e
      flash[:alert] = "Erreur lors de l'achat du plan: #{e.message}"
      redirect_to new_admin_subscription_plan_path(person_id: @person.id)
    end

    private

    def set_person
      @person = Person.find(params[:person_id]) if params[:person_id]
    end

    def set_breadcrumbs
      add_breadcrumb "Administration", admin_root_path
    end

    def subscription_params
      params.require(:subscription_plan).permit(:person_id, :subscription_plan_id, :payment_method)
    end
  end
end
