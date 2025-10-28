module Admin
  class MembershipsController < BaseController
    before_action :set_person, only: [ :show, :edit, :update, :destroy ]
    before_action :set_person_for_create, only: [ :create ]
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

      # Gérer l'upgrade d'adhésion
      if params[:upgrade] == "true" && @person&.current_membership&.basic?
        # Pour l'upgrade, on ne propose que les types Circus
        @membership_types = MembershipType.circus_types.current_versions.order(:price_cents)
        @is_upgrade = true
        @current_membership = @person.current_membership
        add_breadcrumb "Upgrade vers Cirque", nil
      else
        # Pour une nouvelle adhésion, on propose tous les types
        @membership_types = MembershipType.current_versions.order(:price_cents)
        @is_upgrade = false
        add_breadcrumb "Nouvelle adhésion", nil
      end
    end

    def create
      @person = Person.find(membership_purchase_params[:person_id])
      membership_type = MembershipType.find(membership_purchase_params[:membership_type_id])

      begin
        # Vérifier si c'est un upgrade
        if params[:upgrade] == "true" && @person.current_membership&.basic?
          # Utiliser la méthode métier centralisée
          custom_amount = membership_purchase_params[:payment_method] == "offered" ? 
                         (membership_purchase_params[:custom_amount_cents]&.to_i || 0) : nil
          
          result = @person.upgrade_membership!(
            membership_type,
            payment_method: membership_purchase_params[:payment_method],
            recorded_by: Current.user,
            custom_amount_cents: custom_amount,
            offer_reason: membership_purchase_params[:offer_reason]
          )

          message = if membership_purchase_params[:payment_method] == "offered"
            "Adhésion upgradée avec succès ! #{membership_type.name} - Offert"
          else
            price_difference = membership_type.price_cents - @person.current_membership.membership_type.price_cents
            "Adhésion upgradée avec succès ! #{membership_type.name} - Différence: #{(price_difference / 100.0).round(2)}€"
          end

          redirect_to admin_user_path("person_#{@person.id}"), notice: message
        else
          # Création d'une nouvelle adhésion
          custom_amount = membership_purchase_params[:payment_method] == "offered" ? 
                         (membership_purchase_params[:custom_amount_cents]&.to_i || 0) : nil
          
          result = @person.create_membership!(
            membership_type,
            payment_method: membership_purchase_params[:payment_method],
            recorded_by: Current.user,
            custom_amount_cents: custom_amount,
            offer_reason: membership_purchase_params[:offer_reason]
          )

          redirect_to admin_user_path("person_#{@person.id}"),
                      notice: "Adhésion créée avec succès ! Vous pouvez maintenant ajouter une cotisation depuis la fiche utilisateur."
        end
      rescue => e
        flash[:alert] = "Erreur lors de la création de l'adhésion: #{e.message}"
        redirect_to new_admin_membership_path(person_id: @person.id, upgrade: params[:upgrade])
      end
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

    def set_person_for_create
      @person = Person.find(membership_purchase_params[:person_id])
    end

    def set_breadcrumbs
      add_breadcrumb "Administration", admin_dashboard_index_path
    end

    def membership_params
      params.require(:membership).permit(:person_id, :membership_type_id, :payment_method, :started_at, :ended_at)
    end

    def membership_purchase_params
      params.require(:membership).permit(:person_id, :membership_type_id, :payment_method, :custom_amount_cents, :offer_reason).merge(
        recorded_by_id: Current.user.id
      )
    end
  end
end
