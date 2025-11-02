module Admin
  # Admin::UsersController handles user management for administrators.
  # This controller provides full CRUD functionality and management features
  # for all users in the system, including higher-privileged operations like
  # user creation, restoration of deleted users, and role management.
  #
  # The public UsersController in contrast only handles self-service actions
  # for individual users managing their own profiles.
  class UsersController < BaseController
    before_action :set_user, only: %i[ show edit update destroy ]
    before_action :set_breadcrumbs, except: %i[ index new ]
    before_action :check_deletion_permissions, only: [ :destroy ]

    # GET /admin/users or /admin/users.json
    def index
      # Base query avec eager loading optimisé - ne montrer que les Person principales
      @people = PersonQuery.active.main_people.includes(
        :user,
        memberships: :membership_type,
        book_of_entries: :subscription_plan
      )

      # Filtres
      apply_person_filters

      # Recherche
      apply_person_search

      # Tri
      @people = @people.order(:last_name, :first_name)

      # Pagination - Réduire à 15 éléments pour une meilleure lisibilité (ou paramètre items)
      items_per_page = params[:items]&.to_i || 15
      @pagy, @people = pagy(@people, items: items_per_page)

      # Statistiques pour le dashboard (basées sur les Person principales)
      load_dashboard_statistics

      add_breadcrumb "Liste d'adhérents", nil
    end

    # GET /admin/users/1 or /admin/users/1.json
    def show
      # Adapter pour accepter les ID de Person ET de User
      if params[:id].to_s.start_with?("person_")
        # ID de Person (format: person_123)
        person_id = params[:id].gsub("person_", "")

        # Chercher d'abord dans les Person actives
        @person = PersonQuery.active.includes(:user, memberships: :membership_type, book_of_entries: :subscription_plan, payments: [ :payment_lines, :recorded_by ])
                        .find_by(id: person_id)

        # Si Person archivée (fusion), rediriger vers la liste
        if @person.nil?
          archived_person = Person.find_by(id: person_id)
          if archived_person&.deleted_at.present?
            redirect_to admin_users_path, notice: "Cette fiche a été fusionnée avec une autre. Retour à la liste des utilisateurs."
            return
          else
            raise ActiveRecord::RecordNotFound
          end
        end
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
        @person = PersonQuery.active.find(params[:person_id])
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
      person_id = params[:id].to_s.gsub("person_", "")
      @person = PersonQuery.active.find(person_id)
      add_breadcrumb "Liste d'adhérents", admin_users_path
      add_breadcrumb @person.full_name, admin_user_path("person_#{@person.id}")
      add_breadcrumb "Modifier", nil
    end

    # GET /admin/users/1/edit
    def edit
      # Adapter pour gérer les Person
      if params[:id].to_s.start_with?("person_")
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
      form = Admin::UserCreationForm.new(user_creation_params)
      result = form.call

      if result.success?
        redirect_to admin_user_path("person_#{result.person.id}"), notice: result.message
      else
        @user = User.new
        @user.person = result.person if result.person
        flash.now[:alert] = result.message
        render :new, status: :unprocessable_entity
      end
    end

    # PATCH/PUT /admin/users/1 or /admin/users/1.json
    def update
      # Adapter pour gérer les Person
      if params[:id].to_s.start_with?("person_")
        person_id = params[:id].to_s.gsub("person_", "")
        @person = PersonQuery.active.find(person_id)

        if @person.update(person_params.except(:newsletter_subscribed))
          # Gérer newsletter via NewsletterSubscriber
          handle_newsletter_update(@person, person_params[:newsletter_subscribed])
          
          # Handle AJAX requests for inline editing
          if request.xhr?
            render json: {
              success: true,
              member_number: @person.member_number,
              message: "Numéro d'adhérent mis à jour avec succès."
            }
          else
            redirect_to admin_user_path("person_#{@person.id}"), notice: "Informations mises à jour avec succès."
          end
        else
          if request.xhr?
            render json: {
              success: false,
              errors: @person.errors.full_messages
            }, status: :unprocessable_entity
          else
            render :edit_person, status: :unprocessable_entity
          end
        end
        return
      end

      respond_to do |format|
        # Séparer les paramètres User des paramètres Person
        user_only_params = user_params.slice(:email_address, :system_role, :created_by_admin, :create_web_account)
        person_params_flat = user_params.except(:email_address, :system_role, :created_by_admin, :create_web_account, :person)
        newsletter_flag = person_params_flat.delete(:newsletter_subscribed)

        # Mettre à jour User et Person séparément
        user_updated = @user.update(user_only_params)

        # Pour les comptes avec Person, désactiver temporairement la validation d'adhésion
        person_updated = if @user.person.present?
          @user.person.skip_membership_validation = true
          @user.person.update(person_params_flat)
        else
          true # Pas de Person à mettre à jour
        end

        # Gérer newsletter via NewsletterSubscriber
        if person_updated && @user.person.present?
          handle_newsletter_update(@user.person, newsletter_flag)
        end

        if user_updated && person_updated
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
          # Collecter les erreurs
          errors = []
          errors.concat(@user.errors.full_messages) if @user.errors.any?
          errors.concat(@user.person.errors.full_messages) if @user.person&.errors&.any?

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
      if params[:id].to_s.start_with?("person_")
        # Supprimer la Person (déjà chargée dans set_user)
        person = @person
        
        # Debug: vérifier si @person est défini
        if person.nil?
          Rails.logger.error "DEBUG: @person is nil for params[:id] = #{params[:id]}"
          redirect_to admin_users_path, alert: "Personne non trouvée." and return
        end
        
        # Utiliser le service UserManagement::UserDeleter
        deleter = UserManagement::UserDeleter.new(
          person_id: person.id,
          deleted_by_id: current_user.id,
          reason: "Suppression via interface admin"
        )
        
        result = deleter.call
        
        if result.success?
          redirect_to admin_users_path, status: :see_other, notice: "Personne supprimée avec succès."
        else
          redirect_to admin_users_path, alert: "❌ #{result.message}"
        end
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
      if params[:id].to_s.start_with?("person_")
        # Pour les Person, charger la Person
        person_id = params[:id].gsub("person_", "")
        @person = Person.find_by(id: person_id)
        
        # If person not found, redirect to index with alert
        if @person.nil?
          redirect_to admin_users_path, alert: "Utilisateur non trouvé." and return
        end
        
        @user = @person.user # Peut être nil si pas de compte utilisateur
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

    # Méthodes privées pour les filtres et la recherche
    def apply_person_filters
      case params[:filter]
      when "with_active_membership"
        @people = @people.with_active_membership
      when "with_expiring_membership"
        @people = @people.with_expiring_membership
      when "with_expired_membership"
        @people = @people.with_expired_membership
      when "without_membership"
        @people = @people.without_membership
      when "with_user_account"
        @people = @people.with_user_account
      when "without_user_account"
        @people = @people.without_user_account
      end
    end

    def apply_person_search
      @people = @people.search_by_contact(params[:search]) if params[:search].present?
    end

    def load_dashboard_statistics
      # Utiliser les mêmes filtres que la pagination pour la cohérence
      base_people = PersonQuery.active.main_people

      @total_people = base_people.count
      @people_with_user = base_people.joins(:user).count
      @people_without_user = base_people.left_joins(:user).where(users: { id: nil }).count
      @new_users_yesterday = User.where(created_at: 1.day.ago.beginning_of_day..1.day.ago.end_of_day).count
      @basic_memberships = Membership.joins(:membership_type).where(membership_types: { name: "Basic" }).count
      @circus_memberships = Membership.joins(:membership_type).where(membership_types: { name: "Cirque" }).count
      @active_memberships = Membership.active.count
      @users_this_month = User.where(created_at: Date.current.beginning_of_month..Date.current.end_of_month).count
    end

    # Only allow a list of trusted parameters through.
    def user_params
      params.require(:user).permit(
        :email_address,
        :system_role,
        :created_by_admin,
        :create_web_account,
        # Attributs délégués à Person (paramètres plats)
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
        :dyslexic_font,
        :zip_code,
        :town,
        :country,
        # Paramètres imbriqués (pour compatibilité)
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
          :dyslexic_font,
          :zip_code,
          :town,
          :country
        ]
      )
    end

    def user_creation_params
      # Extraire les paramètres de person et les aplatir pour le formulaire
      person_params = params.dig(:user, :person) || {}

      {
        first_name: person_params[:first_name],
        last_name: person_params[:last_name],
        email: person_params[:email],
        phone: person_params[:phone],
        address: person_params[:address],
        zip_code: person_params[:zip_code],
        town: person_params[:town],
        country: person_params[:country],
        birth_date: person_params[:birth_date],
        emergency_contact_name: person_params[:emergency_contact_name],
        emergency_contact_phone: person_params[:emergency_contact_phone],
        notes: person_params[:notes],
        specialty: person_params[:specialty],
        is_minor: person_params[:is_minor],
        image_rights: person_params[:image_rights],
        get_involved: person_params[:get_involved],
        newsletter_subscribed: person_params[:newsletter_subscribed],
        dyslexic_font: person_params[:dyslexic_font],
        create_web_account: params.dig(:user, :create_web_account),
        email_address: params.dig(:user, :email_address),
        system_role: params.dig(:user, :system_role),
        create_membership: params.dig(:user, :create_membership),
        membership_type_id: params.dig(:user, :membership_type_id),
        payment_method: params.dig(:user, :payment_method),
        person_id: params.dig(:user, :person_id)
      }.compact
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
    
    def handle_newsletter_update(person, newsletter_flag)
      return unless person.email.present?
      
      subscriber = NewsletterSubscriber.find_or_initialize_by(email: person.email)
      
      if newsletter_flag == "1" || newsletter_flag == true || newsletter_flag == 1
        subscriber.update!(
          person: person,
          source: 'admin',
          subscribed: true
        )
      else
        subscriber.update!(
          subscribed: false
        )
      end
    end
  end
end
