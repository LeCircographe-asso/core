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
      # Base query avec eager loading optimisé - ne montrer que les Person principales
      @people = Person.main_people.includes(
        :user, 
        :memberships => :membership_type, 
        :book_of_entries => :subscription_plan
      )

      # Filtres
      apply_filters
      
      # Recherche
      apply_search if params[:search].present?
      
      # Tri
      @people = @people.order(:last_name, :first_name)
      
      # Pagination
      @pagy, @people = pagy(@people, items: 25)

      # Statistiques pour le dashboard (basées sur les Person principales)
      @total_people = Person.main_people.count
      @people_with_user = Person.main_people.joins(:user).count
      @people_without_user = Person.main_people.left_joins(:user).where(users: { id: nil }).count
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
        else
          @is_person_without_user = false
        end
        
        # Données pour les formulaires
        @membership_types = MembershipType.all
        @subscription_plans = SubscriptionPlan.all
        @users = User.where(person: nil) # Users non liés
        @recent_payments = @person.payments.includes(:payment_lines, :recorded_by).order(created_at: :desc).limit(10)
        
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
        @recent_payments = @person&.payments&.includes(:payment_lines, :recorded_by)&.order(created_at: :desc)&.limit(10) || []
        
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
      
      # Si on a un person_id, pré-remplir avec les données de la personne
      if params[:person_id].present?
        @person = Person.find(params[:person_id])
        @user.person = @person
        @user.email_address = @person.email
        @user.system_role = "web_visitor" # Rôle par défaut
        add_breadcrumb "Liste d'adhérents", admin_users_path
        add_breadcrumb @person.full_name, admin_user_path("person_#{@person.id}")
        add_breadcrumb "Créer un compte web", nil
      else
        add_breadcrumb "Liste d'adhérents", admin_users_path
        add_breadcrumb "Nouvel adhérent", nil
      end
    end

    # GET /admin/users/person_1/edit_person
    def edit_person
      person_id = params[:id].to_s.gsub('person_', '')
      @person = Person.find(person_id)
      add_breadcrumb "Liste d'adhérents", admin_users_path
      add_breadcrumb @person.full_name, admin_user_path("person_#{@person.id}")
      add_breadcrumb "Modifier", nil
    end

    # GET /admin/users/1/edit
    def edit
      # Adapter pour gérer les Person
      if params[:id].to_s.start_with?('person_')
        # Rediriger vers l'édition Person
        redirect_to edit_person_admin_user_path(params[:id])
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
      # Si on a un person_id, on crée un compte pour une personne existante
      if params[:person_id].present?
        person = Person.find(params[:person_id])
        
        # Vérifier si cette personne a déjà un compte User
        if person.user.present?
          redirect_to admin_user_path("person_#{person.id}"), 
                      alert: "Cette personne a déjà un compte web. ID User: #{person.user.id}"
          return
        end
        
        # Créer le User si compte web demandé
        if user_params[:create_web_account] == "true"
          # Un compte web nécessite un email
          if person.email.blank?
            flash.now[:alert] = "Un email est obligatoire pour créer un compte web."
            @user = User.new
            @user.person = person
            render :new, status: :unprocessable_entity
            return
          end
          
          # LOGIQUE SIMPLE : Chercher un User existant avec cet email
          existing_user = User.find_by(email_address: person.email)
          
          if existing_user.present?
            # CAS 1: User existe déjà → Le lier à cette Person
            if existing_user.person.present?
              redirect_to admin_user_path("person_#{person.id}"), 
                          alert: "Ce compte web (#{existing_user.email_address}) est déjà lié à #{existing_user.person.full_name}. Impossible de le lier à #{person.full_name}."
              return
            else
              # User existe mais pas lié → Le lier
              existing_user.update!(person: person)
              redirect_to admin_user_path("person_#{person.id}"), 
                          notice: "✅ Compte web lié ! #{existing_user.email_address} est maintenant associé à #{person.full_name}."
              return
            end
          else
            # CAS 2: Pas de User existant → Créer un nouveau User
            password = SecureRandom.hex(8)
            user = User.create!(
              person: person,
              email_address: person.email,
              password: password,
              password_confirmation: password,
              system_role: user_params[:system_role] || "web_visitor",
              created_by_admin: true,
              cgu: true,
              privacy_policy: true
            )
            redirect_to admin_user_path("person_#{person.id}"), 
                        notice: "✅ Nouveau compte web créé ! Email: #{person.email}, Mot de passe temporaire généré."
            return
          end
        end

        redirect_to admin_user_path("person_#{person.id}"), notice: "Compte web créé avec succès !"
        return
      end

      # Sinon, créer une nouvelle Person (sans adhésion obligatoire)
      person = Person.new(
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
        specialty: user_params[:person][:specialty],
        is_minor: user_params[:person][:is_minor] || false,
        image_rights: user_params[:person][:image_rights] || false,
        get_involved: user_params[:person][:get_involved] || false,
        newsletter_subscribed: user_params[:person][:newsletter_subscribed] || false,
      )

        if person.save
          # PAS d'assignation automatique du numéro d'adhérent
          # Le numéro sera assigné lors du premier paiement d'adhésion
        
        # Créer le User si compte web demandé
        if user_params[:create_web_account] == "true"
          # Un compte web nécessite un email
          if person.email.blank?
            flash.now[:alert] = "Un email est obligatoire pour créer un compte web."
            @user = User.new
            @user.person = person
            render :new, status: :unprocessable_entity
            return
          end
          
          password = SecureRandom.hex(8)
          user = User.create!(
            person: person,
            email_address: person.email,
            password: password,
            password_confirmation: password,
            system_role: user_params[:system_role] || "web_visitor",
            created_by_admin: true,
            cgu: true,
            privacy_policy: true
          )
        end

        # Rediriger vers la page de création d'adhésion
        redirect_to new_admin_membership_path(person_id: person.id), notice: "Personne créée avec succès ! Veuillez maintenant créer son adhésion."
      else
        @user = User.new
        @user.person = person
        flash.now[:alert] = "Erreur lors de la création : #{person.errors.full_messages.join(', ')}"
        render :new, status: :unprocessable_entity
      end
    end

    # PATCH/PUT /admin/users/1 or /admin/users/1.json
    def update
      # Adapter pour gérer les Person
      if params[:id].to_s.start_with?('person_')
        person_id = params[:id].to_s.gsub('person_', '')
        @person = Person.find(person_id)
        
        if @person.update(person_params)
          redirect_to admin_user_path("person_#{@person.id}"), notice: "Informations mises à jour avec succès."
        else
          render :edit_person, status: :unprocessable_entity
        end
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


    # GET /admin/users/duplicates
    def duplicates
      @duplicate_report = DuplicateDetectionService.generate_report
      add_breadcrumb "Liste d'adhérents", admin_users_path
      add_breadcrumb "Détection des doublons", nil
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
      
      # Créer l'adhésion en statut pending pour le traiter
      membership = @person.memberships.create!(
        membership_type: @membership_type,
        started_at: Date.current,
        ended_at: 1.year.from_now,
        status: :pending,
        first_joined_at: Date.current
      )

      # Créer le paiement en statut pending pour le traiter
      payment = Payment.create!(
        person: @person,
        recorded_by: Current.user,
        total_cents: @membership_type.price_cents,
        payment_method: params[:payment_method] || :cash,
        status: :pending,
        notes: "Adhésion #{@membership_type.name}"
      )

      # Créer la ligne de paiement
      PaymentLine.create!(
        payment: payment,
        item: membership,
        amount_cents: @membership_type.price_cents,
        description: "Adhésion #{@membership_type.name}"
      )

      # Traiter le paiement (cela assignera automatiquement le numéro d'adhérent)
      result = Payments::Process.new(payment).call
      
      unless result.success?
        raise "Erreur lors du traitement du paiement: #{result.message}"
      end

      redirect_to admin_user_path("person_#{@person.id}"), notice: "Adhésion créée avec succès"
    rescue => e
      redirect_to admin_user_path("person_#{@person.id}"), alert: "Erreur lors de la création de l'adhésion: #{e.message}"
    end



    def create_user_for_person
      @person = Person.find(params[:id])
      
      # Vérifier qu'il n'y a pas déjà un compte User
      if @person.user.present?
        redirect_to admin_user_path("person_#{@person.id}"), alert: "Cette personne a déjà un compte utilisateur"
        return
      end

      # LOGIQUE SIMPLE : Chercher un User existant avec cet email
      if @person.email.present?
        existing_user = User.find_by(email_address: @person.email)
        
        if existing_user.present?
          # User existe déjà → Le lier à cette Person
          if existing_user.person.present?
            redirect_to admin_user_path("person_#{@person.id}"), 
                        alert: "Ce compte web (#{existing_user.email_address}) est déjà lié à #{existing_user.person.full_name}. Impossible de le lier à #{@person.full_name}."
            return
          else
            # User existe mais pas lié → Le lier
            existing_user.update!(person: @person)
            redirect_to admin_user_path("person_#{@person.id}"), 
                        notice: "✅ Compte web lié ! #{existing_user.email_address} est maintenant associé à #{@person.full_name}."
            return
          end
        end
      end

      # Pas de User existant → Créer un nouveau User
      user = User.create!(
        person: @person,
        email_address: @person.email,
        password: SecureRandom.hex(8), # Mot de passe temporaire
        password_confirmation: SecureRandom.hex(8),
        system_role: params[:system_role] || "web_visitor",
        created_by_admin: true,
        cgu: true,
        privacy_policy: true
      )

      redirect_to admin_user_path("person_#{@person.id}"), notice: "✅ Nouveau compte web créé ! Email: #{@person.email}, Mot de passe temporaire généré."
    rescue => e
      redirect_to admin_user_path("person_#{@person.id}"), alert: "Erreur lors de la création du compte: #{e.message}"
    end

    # Only allow a list of trusted parameters through.
    def user_params
      params.require(:user).permit(
        :email_address,
        :system_role,
        :created_by_admin,
        :create_web_account,
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
          :specialty,
          :is_minor,
          :image_rights,
          :get_involved,
          :newsletter_subscribed,
        ]
      )
    end

    def person_params
      params.require(:person).permit(
        :first_name,
        :last_name,
        :email,
        :phone,
        :address,
        :zip_code,
        :town,
        :country,
        :birth_date,
        :emergency_contact_name,
        :emergency_contact_phone,
        :notes,
        :newsletter_subscribed,
        :get_involved,
        :image_rights,
        :is_minor
      )
    end

    # Méthodes privées pour les filtres et la recherche
    def apply_filters
      case params[:filter]
      when 'with_active_membership'
        @people = @people.with_active_membership
      when 'with_expiring_membership'
        @people = @people.with_expiring_membership
      when 'with_expired_membership'
        @people = @people.with_expired_membership
      when 'without_membership'
        @people = @people.without_membership
      when 'with_user_account'
        @people = @people.with_user_account
      when 'without_user_account'
        @people = @people.without_user_account
      end
    end

    def apply_search
      @people = @people.search_by_contact(params[:search])
    end


  end
end
