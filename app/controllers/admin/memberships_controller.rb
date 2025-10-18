module Admin
  class MembershipsController < BaseController
    before_action :set_person, only: [:show, :edit, :update, :destroy]
    before_action :set_breadcrumbs

    def index
      @people = Person.includes(:memberships, :user).all
      add_breadcrumb "Gestion des Adhésions", nil
    end

    def show
      @membership = @person.current_membership
      @membership_types = MembershipType.all
      @subscription_plans = SubscriptionPlan.all
      
      add_breadcrumb "Liste d'adhérents", admin_users_path
      add_breadcrumb @person.full_name, admin_user_path("person_#{@person.id}")
      add_breadcrumb "Adhésion", nil
    end

    def new
      @person = Person.find(params[:person_id]) if params[:person_id]
      @membership_types = MembershipType.all
      add_breadcrumb "Nouvelle adhésion", nil
    end

    def create
      @person = Person.find(membership_params[:person_id])
      @membership_type = MembershipType.find(membership_params[:membership_type_id])
      
      # Créer l'adhésion
      @membership = @person.memberships.create!(
        membership_type: @membership_type,
        started_at: Date.current,
        ended_at: 1.year.from_now,
        status: :active,
        first_joined_at: Date.current
      )

      # Créer le paiement
      payment = Payment.create!(
        person: @person,
        recorded_by: Current.user,
        total_cents: @membership_type.price_cents,
        payment_method: membership_params[:payment_method] || :cash,
        status: :success,
        notes: "Adhésion #{@membership_type.name}"
      )

      # Créer la ligne de paiement
      PaymentLine.create!(
        payment: payment,
        item: @membership,
        amount_cents: @membership_type.price_cents,
        description: "Adhésion #{@membership_type.name}"
      )

      redirect_to admin_membership_path(@membership), notice: "Adhésion créée avec succès"
    rescue => e
      flash[:alert] = "Erreur lors de la création de l'adhésion: #{e.message}"
      redirect_to new_admin_membership_path(person_id: @person.id)
    end

    def edit
      @membership = @person.current_membership
      @membership_types = MembershipType.all
      add_breadcrumb "Modifier adhésion", nil
    end

    def update
      @membership = @person.current_membership
      @membership_type = MembershipType.find(membership_params[:membership_type_id])
      
      # Mettre à jour l'adhésion
      @membership.update!(
        membership_type: @membership_type,
        started_at: membership_params[:started_at] || @membership.started_at,
        ended_at: membership_params[:ended_at] || @membership.ended_at
      )

      redirect_to admin_membership_path(@membership), notice: "Adhésion mise à jour avec succès"
    rescue => e
      flash[:alert] = "Erreur lors de la mise à jour: #{e.message}"
      redirect_to edit_admin_membership_path(@membership)
    end

    def destroy
      @membership = @person.current_membership
      @membership.update!(status: :inactive)
      
      redirect_to admin_memberships_path, notice: "Adhésion désactivée avec succès"
    end

    private

    def set_person
      @person = Person.find(params[:id])
    end

    def set_breadcrumbs
      add_breadcrumb "Administration", admin_root_path
    end

    def membership_params
      params.require(:membership).permit(:person_id, :membership_type_id, :payment_method, :started_at, :ended_at)
    end
  end
end
