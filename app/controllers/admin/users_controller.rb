module Admin
  # Admin::UsersController handles user management for administrators.
  # This controller provides full CRUD functionality and management features
  # for all users in the system, including higher-privileged operations like
  # user creation, restoration of deleted users, and role management.
  #
  # The public UsersController in contrast only handles self-service actions
  # for individual users managing their own profiles.
  class UsersController < BaseController
    include RoleHelper
    before_action :set_user, only: %i[ show edit update destroy ]
    before_action :set_breadcrumbs, except: %i[ index new ]
    before_action :check_deletion_permissions, only: [ :destroy ]

    # GET /admin/users or /admin/users.json
    def index
      # Afficher TOUTES les Person (avec ou sans User)
      @people = Person.includes(:user, :memberships, :payments).order(:last_name, :first_name)

      # Statistiques pour le dashboard
      @total_people = Person.count
      @people_with_user = Person.joins(:user).count
      @people_without_user = Person.left_joins(:user).where(users: { id: nil }).count
      @new_users_yesterday = UserService.new_users_count
      @basic_memberships = MembershipService.membership_type_count(:Basic)
      @circus_memberships = MembershipService.membership_type_count(:Circus)
      @active_memberships = MembershipService.active_memberships_count
      @users_this_month = UserService.users_this_month

      add_breadcrumb "Liste d'adhérents", nil
    end

    # GET /admin/users/1 or /admin/users/1.json
    def show
      # Adapter pour accepter les ID de Person ET de User
      if params[:id].to_s.start_with?('person_')
        # ID de Person (format: person_123)
        person_id = params[:id].gsub('person_', '')
        @person = Person.includes(:user, :memberships => :membership_type, :book_of_entries => :subscription_plan, :payments => [:payment_lines, :recorded_by])
                        .find(person_id)
        @user = @person.user # Peut être nil
        
        # Si pas de User, créer un User temporaire pour la vue
        if @user.nil?
          @user = User.new(
            id: "temp_#{@person.id}",
            email_address: @person.email,
            system_role: nil # Pas de rôle pour une Person sans User
          )
          # Établir la relation person manuellement
          @user.association(:person).target = @person
          @user.association(:person).loaded!
          @is_person_without_user = true
        end
        
        # Données pour les formulaires
        @membership_types = MembershipType.all
        @subscription_plans = SubscriptionPlan.all
        @users = User.where(person: nil) # Users non liés
        
        add_breadcrumb "Liste d'adhérents", admin_users_path
        add_breadcrumb @person.full_name, nil
        
      else
        # ID de User (format classique)
        @user = User.unscoped.includes(
          :person,
          :memberships,
          payments: { payment_lines: :item }
        ).find_by(id: params[:id])
        
        @person = @user.person
        @array_right = available_roles_for_user(@user)
        @is_person_without_user = false
        
        add_breadcrumb "Liste d'adhérents", admin_users_path
        add_breadcrumb @user&.person&.full_name.present? ? @user.person.full_name : "Utilisateur ##{@user.id}", nil
      end

      respond_to do |format|
        format.html
        format.json { render json: @user || @person }
      end
    end

    # GET /admin/users/new
    def new
      @user = User.new
      @user.created_by_admin = true
      add_breadcrumb "Liste d'adhérents", admin_users_path
      add_breadcrumb "Nouvel adhérent", nil
    end

    # GET /admin/users/1/edit
    def edit
      # Adapter pour gérer les Person
      if params[:id].to_s.start_with?('person_')
        # Rediriger vers la fiche Person pour modification
        redirect_to admin_user_path(params[:id]), notice: "Utilisez la fiche Person pour modifier les informations"
        return
      end

      Rails.logger.debug "Edit action called for user ID: #{params[:id]}"
      Rails.logger.debug "@user: #{@user.inspect}"
      Rails.logger.debug "current_user: #{current_user.inspect}"

      if @user.nil?
        Rails.logger.debug "User is nil, redirecting to users list"
        redirect_to admin_users_path, alert: "Utilisateur non trouvé."
        return
      end

      begin
        @array_right = available_roles_for_user(@user)
        Rails.logger.debug "@array_right: #{@array_right.inspect}"
        @default_role = @user.system_role
        Rails.logger.debug "@default_role: #{@default_role.inspect}"
      rescue => e
        Rails.logger.error "Error in edit action: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        redirect_to admin_users_path, alert: "Une erreur est survenue lors de l'édition de l'utilisateur."
        return
      end

      add_breadcrumb "Liste d'adhérents", admin_users_path
      add_breadcrumb @user.person&.full_name.present? ? @user.person.full_name : "Utilisateur ##{@user.id}", admin_user_path(@user)
      add_breadcrumb "Modifier", nil
    end

    # POST /admin/users or /admin/users.json
    def create
      # Utiliser le service People::Register pour créer Person + User + Membership
      result = People::Register.new(
        first_name: user_params[:person][:first_name],
        last_name: user_params[:person][:last_name],
        email: user_params[:person][:email],
        phone: user_params[:person][:phone],
        birth_date: user_params[:person][:birth_date],
        address: user_params[:person][:address],
        zip_code: user_params[:person][:zip_code],
        town: user_params[:person][:town],
        country: user_params[:person][:country],
        emergency_contact_name: user_params[:person][:emergency_contact_name],
        emergency_contact_phone: user_params[:person][:emergency_contact_phone],
        notes: user_params[:person][:notes],
        occupation: user_params[:person][:occupation],
        specialty: user_params[:person][:specialty],
        image_rights: user_params[:person][:image_rights],
        get_involved: user_params[:person][:get_involved],
        newsletter_subscribed: user_params[:person][:newsletter_subscribed],
        dyslexic_font: user_params[:person][:dyslexic_font],
        # Adhésion obligatoire
        membership_type_id: user_params[:membership_type_id],
        payment_method: user_params[:payment_method] || "cash",
        recorded_by_id: Current.user&.id,
        # User account creation (optionnel)
        create_user_account: user_params[:email_address].present?,
        user_email: user_params[:email_address],
        user_system_role: user_params[:system_role] || "user_connected"
      ).call

      if result.success?
        redirect_to admin_users_path, notice: "Adhérent créé avec succès !"
      else
        @user = User.new
        @user.build_person
        flash.now[:alert] = "Erreur lors de la création de l'adhérent: #{result.errors.join(', ')}"
        render :new, status: :unprocessable_entity
      end
    end

    # PATCH/PUT /admin/users/1 or /admin/users/1.json
    def update
      # Adapter pour gérer les Person
      if params[:id].to_s.start_with?('person_')
        # Rediriger vers la fiche Person
        redirect_to admin_user_path(params[:id]), notice: "Utilisez la fiche Person pour modifier les informations"
        return
      end

      respond_to do |format|
        if @user.update(user_params)
          format.html { redirect_to admin_user_path(@user), notice: "Utilisateur mis à jour avec succès." }
          format.json { render json: @user }
          format.turbo_stream {
            flash.now[:notice] = "Utilisateur mis à jour avec succès."
            render turbo_stream: [
              turbo_stream.replace(@user),
              turbo_stream.replace("flash", partial: "shared/flash")
            ]
          }
        else
          format.html { render :show, status: :unprocessable_entity }
          format.json { render json: @user.errors, status: :unprocessable_entity }
          format.turbo_stream {
            render turbo_stream: turbo_stream.replace(
              "error_explanation",
              partial: "shared/error_messages",
              locals: { resource: @user }
            )
          }
        end
      end
    end

    # DELETE /admin/users/1 or /admin/users/1.json
    def destroy
      # Adapter pour gérer les Person
      if params[:id].to_s.start_with?('person_')
        # Rediriger vers la fiche Person
        redirect_to admin_user_path(params[:id]), notice: "Utilisez la fiche Person pour gérer les suppressions"
        return
      end

      @user.destroy!

      respond_to do |format|
        format.html { redirect_to admin_users_path, status: :see_other, notice: "Utilisateur supprimé avec succès." }
        format.json { head :no_content }
      end
    end

    # POST /admin/users/1/restore
    def restore
      @user = User.unscoped.find(params[:id])

      if @user.update(
        deleted: false,
        deleted_at: nil,
        email_address: params[:email_address]
      )
        redirect_to admin_users_path, notice: "Utilisateur restauré avec succès."
      else
        redirect_to admin_users_path, alert: "Impossible de restaurer cet utilisateur."
      end
    end

    private
    # Use callbacks to share common setup or constraints between actions.
    def set_user
      # Adapter pour gérer les IDs de Person (format: person_123)
      if params[:id].to_s.start_with?('person_')
        # Pour les Person, on ne fait rien ici - géré dans show
        @user = nil
      else
        # Pour les User classiques
        @user = User.unscoped.find_by(id: params[:id])

        # If user not found, redirect to index with alert
        if @user.nil?
          redirect_to admin_users_path, alert: "Utilisateur non trouvé." and return
        end
      end
    end

    def set_breadcrumbs
      add_breadcrumb "Dashboard", admin_dashboard_index_path
    end

    # Check if current user has permission to delete the target user
    def check_deletion_permissions
      return if @user.nil?

      # Prevent deleting users with equal or higher privileges
      unless current_user.has_higher_permissions?(@user)
        redirect_to admin_users_path, alert: "Impossible de supprimer un utilisateur avec des privilèges égaux ou supérieurs."
      end
    end

    # Actions pour gérer les adhésions et cotisations
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

      redirect_to admin_user_path("person_#{@person.id}"), notice: "Adhésion créée avec succès"
    rescue => e
      redirect_to admin_user_path("person_#{@person.id}"), alert: "Erreur lors de la création de l'adhésion: #{e.message}"
    end

    def create_subscription
      @person = Person.find(params[:id])
      @subscription_plan = SubscriptionPlan.find(params[:subscription_plan_id])
      
      # Vérifier que la personne peut acheter des plans d'abonnement
      unless @person.can_buy_subscription_plans?
        redirect_to admin_user_path("person_#{@person.id}"), alert: "Cette personne doit avoir une adhésion Cirque pour acheter des plans d'abonnement"
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

      redirect_to admin_user_path("person_#{@person.id}"), notice: "Plan d'abonnement acheté avec succès"
    rescue => e
      redirect_to admin_user_path("person_#{@person.id}"), alert: "Erreur lors de l'achat du plan: #{e.message}"
    end

    def create_user_for_person
      @person = Person.find(params[:id])
      
      # Vérifier qu'il n'y a pas déjà un compte User
      if @person.user.present?
        redirect_to admin_user_path("person_#{@person.id}"), alert: "Cette personne a déjà un compte utilisateur"
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

      redirect_to admin_user_path("person_#{@person.id}"), notice: "Compte utilisateur créé avec succès. Mot de passe temporaire généré."
    rescue => e
      redirect_to admin_user_path("person_#{@person.id}"), alert: "Erreur lors de la création du compte: #{e.message}"
    end

    # Only allow a list of trusted parameters through.
    def user_params
      params.require(:user).permit(
        :email_address,
        :system_role,
        :created_by_admin,
        person: [
          :id,
          :first_name,
          :last_name,
          :email,
          :phone,
          :birth_date,
          :address,
          :emergency_contact_name,
          :emergency_contact_phone,
          :notes,
          :occupation,
          :specialty,
          :image_rights,
          :get_involved,
          :newsletter_subscribed,
          :dyslexic_font
        ]
      )
    end
  end
end
