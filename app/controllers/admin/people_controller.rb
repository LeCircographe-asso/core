module Admin
  class PeopleController < BaseController
    before_action :set_person, only: [:show, :edit, :update, :destroy]
    before_action :set_breadcrumbs

    def index
      # Afficher TOUTES les Person avec leurs informations
      @people = Person.includes(:user, :memberships => :membership_type, :book_of_entries => :subscription_plan)
                      .order(:last_name, :first_name)

      # Statistiques
      @total_people = Person.count
      @people_with_user = Person.joins(:user).count
      @people_without_user = Person.left_joins(:user).where(users: { id: nil }).count
      @people_with_active_membership = Person.joins(:memberships).where(memberships: { status: :active }).count
      @people_without_membership = Person.left_joins(:memberships).where(memberships: { id: nil }).count

      add_breadcrumb "Gestion des Personnes", nil
    end

    def show
      # Charger toutes les associations nécessaires
      @memberships = @person.memberships.includes(:membership_type).order(created_at: :desc)
      @current_membership = @person.current_membership
      @book_of_entries = @person.book_of_entries.includes(:subscription_plan).order(created_at: :desc)
      @payments = @person.payments.includes(:payment_lines, :recorded_by).order(created_at: :desc)
      
      # Données pour les formulaires
      @membership_types = MembershipType.all
      @subscription_plans = SubscriptionPlan.all
      @users = User.all # Pour lier un compte existant

      add_breadcrumb "Gestion des Personnes", admin_people_path
      add_breadcrumb @person.full_name, nil
    end

    def new
      @person = Person.new
      @membership_types = MembershipType.all
      add_breadcrumb "Nouvelle personne", nil
    end

    def create
      # Utiliser le service People::Register pour créer Person + Membership
      result = People::Register.new(
        first_name: person_params[:first_name],
        last_name: person_params[:last_name],
        email: person_params[:email],
        phone: person_params[:phone],
        birth_date: person_params[:birth_date],
        address: person_params[:address],
        zip_code: person_params[:zip_code],
        town: person_params[:town],
        country: person_params[:country],
        emergency_contact_name: person_params[:emergency_contact_name],
        emergency_contact_phone: person_params[:emergency_contact_phone],
        notes: person_params[:notes],
        occupation: person_params[:occupation],
        specialty: person_params[:specialty],
        image_rights: person_params[:image_rights],
        get_involved: person_params[:get_involved],
        newsletter_subscribed: person_params[:newsletter_subscribed],
        dyslexic_font: person_params[:dyslexic_font],
        # Adhésion obligatoire
        membership_type_id: person_params[:membership_type_id],
        payment_method: person_params[:payment_method] || "cash",
        recorded_by_id: Current.user&.id,
        # Pas de compte User par défaut
        create_user_account: false
      ).call

      if result.success?
        redirect_to admin_person_path(result.user), notice: "Personne créée avec succès"
      else
        @person = Person.new(person_params)
        @membership_types = MembershipType.all
        flash.now[:alert] = result.errors.join(", ")
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @membership_types = MembershipType.all
      add_breadcrumb "Modifier personne", nil
    end

    def update
      if @person.update(person_params)
        redirect_to admin_person_path(@person), notice: "Personne mise à jour avec succès"
      else
        @membership_types = MembershipType.all
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      # Soft delete - anonymiser les données
      @person.user&.anonymize_personal_data
      @person.update!(
        first_name: "Deleted",
        last_name: "Person",
        email: "deleted_#{@person.id}@example.com",
        phone: nil,
        address: nil
      )
      
      redirect_to admin_people_path, notice: "Personne supprimée avec succès"
    end

    # Actions pour gérer les adhésions
    def create_membership
      @person = Person.find(params[:id])
      @membership_type = MembershipType.find(params[:membership_type_id])
      
      # Créer l'adhésion
      membership = @person.memberships.create!(
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
        payment_method: params[:payment_method] || :cash,
        status: :success,
        notes: "Adhésion #{@membership_type.name}"
      )

      # Créer la ligne de paiement
      PaymentLine.create!(
        payment: payment,
        item: membership,
        amount_cents: @membership_type.price_cents,
        description: "Adhésion #{@membership_type.name}"
      )

      redirect_to admin_person_path(@person), notice: "Adhésion créée avec succès"
    rescue => e
      redirect_to admin_person_path(@person), alert: "Erreur lors de la création de l'adhésion: #{e.message}"
    end

    # Actions pour gérer les cotisations
    def create_subscription
      @person = Person.find(params[:id])
      @subscription_plan = SubscriptionPlan.find(params[:subscription_plan_id])
      
      # Vérifier que la personne peut acheter des plans d'abonnement
      unless @person.can_buy_subscription_plans?
        redirect_to admin_person_path(@person), alert: "Cette personne doit avoir une adhésion Cirque pour acheter des plans d'abonnement"
        return
      end

      # Créer le carnet d'entrées
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
        payment_method: params[:payment_method] || :cash,
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

      redirect_to admin_person_path(@person), notice: "Plan d'abonnement acheté avec succès"
    rescue => e
      redirect_to admin_person_path(@person), alert: "Erreur lors de l'achat du plan: #{e.message}"
    end

    # Action pour lier un compte User existant
    def link_user
      @person = Person.find(params[:id])
      @user = User.find(params[:user_id])
      
      # Vérifier que le User n'est pas déjà lié à une autre Person
      if @user.person.present?
        redirect_to admin_person_path(@person), alert: "Ce compte utilisateur est déjà lié à une autre personne"
        return
      end

      # Lier le User à la Person
      @user.update!(person: @person)
      
      redirect_to admin_person_path(@person), notice: "Compte utilisateur lié avec succès"
    rescue => e
      redirect_to admin_person_path(@person), alert: "Erreur lors de la liaison: #{e.message}"
    end

    # Action pour créer un nouveau compte User
    def create_user
      @person = Person.find(params[:id])
      
      # Vérifier qu'il n'y a pas déjà un compte User
      if @person.user.present?
        redirect_to admin_person_path(@person), alert: "Cette personne a déjà un compte utilisateur"
        return
      end

      # Créer le compte User
      user = User.create!(
        person: @person,
        email_address: @person.email,
        password: SecureRandom.hex(8), # Mot de passe temporaire
        password_confirmation: SecureRandom.hex(8),
        system_role: params[:system_role] || "user_connected",
        created_by_admin: true,
        cgu: true,
        privacy_policy: true
      )

      redirect_to admin_person_path(@person), notice: "Compte utilisateur créé avec succès. Mot de passe temporaire généré."
    rescue => e
      redirect_to admin_person_path(@person), alert: "Erreur lors de la création du compte: #{e.message}"
    end

    private

    def set_person
      @person = Person.find(params[:id])
    end

    def set_breadcrumbs
      add_breadcrumb "Administration", admin_root_path
    end

    def person_params
      params.require(:person).permit(
        :first_name, :last_name, :email, :phone, :birth_date, :address,
        :zip_code, :town, :country, :emergency_contact_name, :emergency_contact_phone,
        :notes, :occupation, :specialty, :image_rights, :get_involved,
        :newsletter_subscribed, :dyslexic_font, :membership_type_id, :payment_method
      )
    end
  end
end
