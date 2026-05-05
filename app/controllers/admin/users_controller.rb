# frozen_string_literal: true

module Admin
  # Admin::UsersController handles user management for administrators.
  # This controller provides full CRUD functionality and management features
  # for all users in the system, including higher-privileged operations like
  # user creation, restoration of deleted users, and role management.
  #
  # The public UsersController in contrast only handles self-service actions
  # for individual users managing their own profiles.
  class UsersController < BaseController
    include NewsletterParamParser
    include Admin::Users::ParameterHandling
    include Admin::Users::UpdateHandling
    before_action :set_user, only: %i[edit update destroy create_web_account]
    before_action :set_breadcrumbs, except: %i[index new]
    before_action :check_deletion_permissions, only: [ :destroy ]
    before_action :require_super_admin, only: [ :restore ]

    # GET /admin/users or /admin/users.json
    def index
      people_scope = Admin::Users::IndexQuery.new(params).call

      # Pagination - Réduire à 15 éléments pour une meilleure lisibilité (ou paramètre items)
      items_per_page = params[:items]&.to_i || 15
      @pagy, @people = pagy(people_scope, items: items_per_page)

      # Statistiques pour le dashboard (basées sur les Person principales)
      statistics_service = Admin::DashboardStatisticsService.new(base_people: people_scope)
      statistics = statistics_service.call
      @total_people = statistics[:total_people]
      @people_with_user = statistics[:people_with_user]
      @people_without_user = statistics[:people_without_user]
      @new_users_yesterday = statistics[:new_users_yesterday]
      @basic_memberships = statistics[:basic_memberships]
      @circus_memberships = statistics[:circus_memberships]
      @active_memberships = statistics[:active_memberships]
      @users_this_month = statistics[:users_this_month]

      add_breadcrumb I18n.t("breadcrumbs.admin.users.members_list"), nil
    end

    # GET /admin/users/1 or /admin/users/1.json
    def show
      if person_identifier?(params[:id])
        return unless load_show_context_for_person
      else
        return unless load_show_context_for_user
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
        add_breadcrumb I18n.t("breadcrumbs.admin.users.members_list"), admin_users_path
        add_breadcrumb @person.full_name, admin_user_path(person_route_key(@person))
        add_breadcrumb I18n.t("breadcrumbs.admin.users.create_web_account"), nil
      else
        add_breadcrumb I18n.t("breadcrumbs.admin.users.members_list"), admin_users_path
        add_breadcrumb I18n.t("breadcrumbs.admin.users.new_member"), nil
      end
    end

    # GET /admin/users/person_1/edit_person
    def edit_person
      person_id = extracted_person_id(params[:id])
      @person = PersonQuery.active.find(person_id)
      add_breadcrumb I18n.t("breadcrumbs.admin.users.members_list"), admin_users_path
      add_breadcrumb @person.full_name, admin_user_path(person_route_key(@person))
      add_breadcrumb I18n.t("breadcrumbs.admin.common.edit"), nil
    end

    # GET /admin/users/1/edit
    def edit
      # Adapter pour gérer les Person
      if person_identifier?(params[:id])
        # Rediriger vers l'édition Person
        redirect_to edit_person_admin_user_path(params[:id])
        return
      end

      Rails.logger.debug { "Edit action called for user ID: #{params[:id]}" }
      Rails.logger.debug { "@user: #{@user.inspect}" }
      Rails.logger.debug { "current_user: #{current_user.inspect}" }

      if @user.nil?
        Rails.logger.debug "User is nil, redirecting to users list"
        redirect_to admin_users_path, alert: t(".user_not_found")
        return
      end

      begin
        @array_right = available_roles_for_user(@user)
        Rails.logger.debug { "@array_right: #{@array_right.inspect}" }
        @default_role = @user.system_role
        Rails.logger.debug { "@default_role: #{@default_role.inspect}" }
      rescue StandardError => e
        Rails.logger.error "Error in edit action: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        redirect_to admin_users_path, alert: t(".edit_error")
        return
      end

      add_breadcrumb I18n.t("breadcrumbs.admin.users.members_list"), admin_users_path
      add_breadcrumb @user.person&.full_name.present? ? @user.person.full_name : "Utilisateur ##{@user.id}", admin_user_path(@user)
      add_breadcrumb I18n.t("breadcrumbs.admin.common.edit"), nil
    end

    # POST /admin/users or /admin/users.json
    def create
      form = Admin::UserCreationForm.new(user_creation_params)
      result = form.call

      if result.success?
        redirect_to admin_user_path(person_route_key(result.person)), notice: result.message
      else
        @user = User.new
        @user.person = result.person if result.person
        flash.now[:alert] = result.message
        render :new, status: :unprocessable_content
      end
    end

    # PATCH/PUT /admin/users/1 or /admin/users/1.json
    def update
      return handle_person_update if person_identifier?(params[:id])

      handle_user_update
    end

    # DELETE /admin/users/1 or /admin/users/1.json
    def destroy
      # Adapter pour gérer les Person
      if person_identifier?(params[:id])
        destroy_person_entity
        return
      end

      respond_to do |format|
        if @user.archive!
          format.html { redirect_to admin_users_path, status: :see_other, notice: t(".user_archived_notice") }
          format.json { head :no_content }
        else
          format.html { redirect_to admin_users_path, status: :see_other, alert: t(".archive_failed_alert") }
          format.json { head :unprocessable_content }
        end
      end
    end

    # POST /admin/users/person_1/create_web_account
    def create_web_account
      if @person.nil?
        redirect_to admin_users_path, alert: t(".person_or_user_missing_alert") and return
      end

      if @person.user.present?
        redirect_to admin_user_path(person_route_key(@person)), alert: t(".web_account_already_exists") and return
      end

      if @person.email.blank?
        redirect_to admin_user_path(person_route_key(@person)), alert: t(".email_required_for_web_account") and return
      end

      result = People::UserAccountCreator.new(
        person: @person,
        system_role: "web_visitor",
        created_by_admin: true
      ).call

      if result.success?
        redirect_to admin_user_path(person_route_key(@person)), notice: t(".web_account_created")
      else
        redirect_to admin_user_path(person_route_key(@person)), alert: result.message
      end
    end

    # POST /admin/users/1/restore
    def restore
      @user = User.unscoped.find(params[:id])

      if @user.update(deleted: false, deleted_at: nil)
        redirect_to admin_users_path, notice: t(".restored_notice")
      else
        redirect_to admin_users_path, alert: t(".restore_failed_alert")
      end
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_user
      # Adapter pour gérer les IDs de Person (format: person_123)
      if person_identifier?(params[:id])
        # Pour les Person, charger la Person
        person_id = extracted_person_id(params[:id])
        @person = Person.find_by(id: person_id)

        # If person not found, redirect to index with alert
        redirect_to admin_users_path, alert: t(".person_or_user_missing_alert") and return if @person.nil?

        @user = @person.user # Peut être nil si pas de compte utilisateur
      else
        # Pour les User classiques
        @user = User.unscoped.find_by(id: params[:id])

        # If user not found, redirect to index with alert
        redirect_to admin_users_path, alert: t(".person_or_user_missing_alert") and return if @user.nil?
      end
    end

    def set_breadcrumbs
      add_breadcrumb I18n.t("breadcrumbs.admin.common.dashboard"), admin_dashboard_index_path
    end

    # Check if current user has permission to delete the target user
    def check_deletion_permissions
      return if @user.nil?

      # Prevent deleting users with equal or higher privileges
      return if current_user.has_higher_permissions?(@user)

      redirect_to admin_users_path, alert: I18n.t("admin.users.check_deletion_permissions.higher_privileges")
    end

    def available_roles_for_user(user)
      return [] if user.nil?

      # Un super_admin peut assigner tous les rôles sauf super_admin
      if Current.user&.super_admin?
        User.system_roles.keys.reject { |role| role == "super_admin" }
      # Un admin peut assigner volunteer et web_visitor
      elsif Current.user&.admin?
        %w[volunteer web_visitor]
      else
        []
      end
    end

    def require_super_admin
      return if Current.user&.super_admin?

      redirect_to admin_users_path, alert: I18n.t("admin.users.require_super_admin.restore_denied_alert")
    end

    def person_identifier?(raw_id)
      Admin::Users::PersonRouteKey.person_identifier?(raw_id)
    end

    def extracted_person_id(raw_id)
      Admin::Users::PersonRouteKey.extract(raw_id)
    end

    def person_route_key(person_or_id)
      Admin::Users::PersonRouteKey.call(person_or_id)
    end

    def load_recent_payments(person)
      return [] unless person

      PaymentQuery.with_person_and_recorded_by
                  .where(person_id: person.id)
                  .order(created_at: :desc)
                  .limit(10)
    end

    def add_admin_user_breadcrumbs(label)
      add_breadcrumb I18n.t("breadcrumbs.admin.users.members_list"), admin_users_path
      add_breadcrumb label, nil
    end

    def user_label(user)
      user&.person&.full_name.presence || "Utilisateur ##{user.id}"
    end

    def load_show_context_for_person
      person_id = extracted_person_id(params[:id])
      @person = PersonQuery.active.includes(:user, memberships: :membership_type, contributions: :contribution_formula, payments: %i[payment_lines recorded_by])
                         .find_by(id: person_id)

      return handle_missing_person_in_show(person_id) if @person.nil?

      @user = @person.user
      @is_person_without_user = @user.nil?
      @user = Admin::Users::ViewUserAdapter.from_person(@person) if @is_person_without_user
      @membership_types = MembershipType.all
      @contribution_formulas = ContributionFormula.all
      @users = User.where(person: nil)
      @recent_payments = load_recent_payments(@person)
      add_admin_user_breadcrumbs(@person.full_name)
      true
    end

    def handle_missing_person_in_show(person_id)
      archived_person = Person.find_by(id: person_id)
      raise ActiveRecord::RecordNotFound if archived_person&.deleted_at.blank?

      redirect_to admin_users_path, notice: t(".merged_person_notice")
      false
    end

    def load_show_context_for_user
      @user = User.unscoped.includes(
        :person,
        :memberships,
        payments: { payment_lines: :item }
      ).find_by(id: params[:id])

      if @user.nil?
        respond_to do |format|
          format.html do
            redirect_to admin_users_path, alert: I18n.t("admin.users.set_user.person_or_user_missing_alert")
          end
          format.json { head :not_found }
        end
        return false
      end

      @person = @user.person
      @array_right = available_roles_for_user(@user)
      @is_person_without_user = false
      @recent_payments = load_recent_payments(@person)
      add_admin_user_breadcrumbs(user_label(@user))
      true
    end

    def destroy_person_entity
      person = @person
      if person.nil?
        redirect_to admin_users_path, alert: t(".person_not_found_alert")
        return
      end

      deleter = UserManagement::UserDeleter.new(
        person_id: person.id,
        deleted_by_id: current_user.id,
        reason: "Suppression via interface admin"
      )
      result = deleter.call
      if result.success?
        redirect_to admin_users_path, status: :see_other, notice: t(".person_deleted_notice")
      else
        redirect_to admin_users_path, alert: t(".destruction_failed_alert_html", message: result.message)
      end
    end
  end
end
