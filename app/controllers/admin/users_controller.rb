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
    include Admin::Users::DisplayHelper
    include Admin::Users::StatusHelper
    include Admin::Users::ActionsHelper
    include Admin::Users::Filtering
    include Admin::Users::Statistics
    before_action :set_user, only: %i[ show edit update destroy ]
    before_action :set_breadcrumbs, except: %i[ index new ]
    before_action :check_deletion_permissions, only: [ :destroy ]

    # GET /admin/users or /admin/users.json
    def index
      # Base query avec eager loading optimisé - ne montrer que les Person principales
      @people = Person.active.main_people.includes(
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
        @person = Person.active.includes(:user, memberships: :membership_type, book_of_entries: :subscription_plan, payments: [ :payment_lines, :recorded_by ])
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
        @person = Person.active.find(params[:person_id])
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
      @person = Person.active.find(person_id)
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
      # Si on a un person_id, on crée un compte pour une personne existante
      if params[:person_id].present?
        person = Person.active.find(params[:person_id])

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
            User.create!(
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
      if params[:id].to_s.start_with?("person_")
        person_id = params[:id].to_s.gsub("person_", "")
        @person = Person.active.find(person_id)

        if @person.update(person_params)
          redirect_to admin_user_path("person_#{@person.id}"), notice: "Informations mises à jour avec succès."
        else
          render :edit_person, status: :unprocessable_entity
        end
        return
      end

      respond_to do |format|
        # Séparer les paramètres User des paramètres Person
        user_only_params = user_params.slice(:email_address, :system_role, :created_by_admin, :create_web_account)
        person_params_flat = user_params.except(:email_address, :system_role, :created_by_admin, :create_web_account, :person)

        # Mettre à jour User et Person séparément
        user_updated = @user.update(user_only_params)

        # Pour les comptes avec Person, désactiver temporairement la validation d'adhésion
        person_updated = if @user.person.present?
          @user.person.skip_membership_validation = true
          @user.person.update(person_params_flat)
        else
          true # Pas de Person à mettre à jour
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
      if params[:id].to_s.start_with?("person_")
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
      @person = Person.active.find(params[:id])
      @membership_type = MembershipType.find(params[:membership_type_id])

      result = Admin::Operations::MembershipOperations.new(actor: Current.user)
        .create_membership_with_payment(
          person: @person,
          membership_type: @membership_type,
          payment_method: params[:payment_method] || :cash
        )

      handle_result(result, success_path: admin_user_path("person_#{@person.id}"))
    end



    def create_user_for_person
      @person = Person.active.find(params[:id])

      result = Admin::Operations::UserAccountOperations.new(actor: Current.user)
        .ensure_user_account_for(
          person: @person,
          email: @person.email,
          system_role: params[:system_role] || "web_visitor"
        )

      handle_result(result, success_path: admin_user_path("person_#{@person.id}"))
    end

    # Actions pour gérer les cotisations
    def create_subscription
      @person = Person.active.find(params[:id])
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

    # Action pour lier un compte User existant
    def link_user
      @person = Person.active.find(params[:id])
      @user = User.find(params[:user_id])

      # Vérifier que le User n'est pas déjà lié à une autre Person
      if @user.person.present?
        redirect_to admin_user_path("person_#{@person.id}"), alert: "Ce compte utilisateur est déjà lié à une autre personne"
        return
      end

      # Lier le User à la Person
      @user.update!(person: @person)

      redirect_to admin_user_path("person_#{@person.id}"), notice: "Compte utilisateur lié avec succès"
    rescue => e
      redirect_to admin_user_path("person_#{@person.id}"), alert: "Erreur lors de la liaison: #{e.message}"
    end

    def handle_result(result, success_path:)
      if result.success?
        redirect_to success_path, notice: result.message
      else
        redirect_back fallback_location: admin_users_path, alert: result.errors.join(", ")
      end
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

    # Actions pour la gestion des présences
    def check_attendance_eligibility
      # Gérer les IDs de User et Person
      if params[:id].start_with?("person_")
        person_id = params[:id].gsub("person_", "")
        @person = Person.active.find(person_id)
      else
        # ID numérique = User ID
        user = User.find(params[:id])
        @person = user.person
      end
      
      @date = params[:date]&.to_date || Date.current

      operations = Admin::Operations::AttendanceOperations.new(actor: Current.user)
      @result = operations.check_eligibility_for(person: @person, date: @date)

      respond_to do |format|
        format.turbo_stream
      end
    end

    def record_attendance_directly
      # Gérer les IDs de User et Person
      if params[:id].start_with?("person_")
        person_id = params[:id].gsub("person_", "")
        @person = Person.active.find(person_id)
      else
        # ID numérique = User ID
        user = User.find(params[:id])
        @person = user.person
      end
      
      @date = params[:date]&.to_date || Date.current

      operations = Admin::Operations::AttendanceOperations.new(actor: Current.user)
      @result = operations.record_directly(
        person: @person,
        date: @date
      )

      respond_to do |format|
        format.turbo_stream do
          if @result.success?
            render turbo_stream: [
              turbo_stream.update("attendance-frame-#{@person.id}", 
                partial: "admin/users/attendance_success", 
                locals: { person: @person, result: @result }),
              turbo_stream.update("flash", 
                partial: "shared/flash", 
                locals: { notice: @result.message })
            ]
          else
            render turbo_stream: turbo_stream.update("flash", 
              partial: "shared/flash", 
              locals: { alert: @result.message })
          end
        end
      end
    end

    def record_attendance_with_book
      # Gérer les IDs de User et Person
      if params[:id].start_with?("person_")
        person_id = params[:id].gsub("person_", "")
        @person = Person.active.find(person_id)
      else
        # ID numérique = User ID
        user = User.find(params[:id])
        @person = user.person
      end
      
      @book_of_entry = BookOfEntry.find(params[:book_of_entry_id])
      @date = params[:date]&.to_date || Date.current

      operations = Admin::Operations::AttendanceOperations.new(actor: Current.user)
      @result = operations.record_with_book(
        person: @person,
        book_of_entry: @book_of_entry,
        date: @date
      )

      respond_to do |format|
        format.turbo_stream do
          if @result.success?
            render turbo_stream: [
              turbo_stream.update("attendance-frame-#{@person.id}", 
                partial: "admin/users/attendance_success", 
                locals: { person: @person, result: @result }),
              turbo_stream.update("flash", 
                partial: "shared/flash", 
                locals: { notice: @result.message })
            ]
          else
            render turbo_stream: turbo_stream.update("flash", 
              partial: "shared/flash", 
              locals: { alert: @result.message })
          end
        end
      end
    end

    # Méthodes privées pour les filtres et la recherche
  end
end
