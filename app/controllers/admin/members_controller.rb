# frozen_string_literal: true

module Admin
  class MembersController < BaseController
    include NewsletterParamParser
    include Admin::Members::ParameterHandling
    include Admin::Members::UpdateHandling
    before_action :set_person, only: %i[show edit update destroy create_web_account edit_person]
    before_action :set_breadcrumbs, except: %i[index new]
    before_action :check_deletion_permissions, only: [ :destroy ]
    before_action :require_super_admin, only: [ :restore ]

    def index
      people_scope = Admin::Members::IndexQuery.new(params).call

      items_per_page = params[:items]&.to_i || 15
      @pagy, @people = pagy(people_scope, items: items_per_page)

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

      add_breadcrumb I18n.t("breadcrumbs.admin.members.members_list"), nil
    end

    def show
      @user = @person.user
      @is_person_without_user = @user.nil?
      @membership_types = MembershipType.all
      @contribution_formulas = ContributionFormula.all
      @users = User.where(person: nil)
      @recent_payments = load_recent_payments(@person)
      add_breadcrumb I18n.t("breadcrumbs.admin.members.members_list"), admin_members_path
      add_breadcrumb @person.full_name, nil

      respond_to do |format|
        format.html
        format.json { render json: @person }
      end
    end

    def new
      @member_creation_form = Admin::MemberCreationForm.new

      if params[:person_id].present?
        @person = PersonQuery.active.find(params[:person_id])
        @member_creation_form.person_id = @person.id
        @member_creation_form.email_address = @person.email
        add_breadcrumb I18n.t("breadcrumbs.admin.members.members_list"), admin_members_path
        add_breadcrumb @person.full_name, admin_member_path(@person)
        add_breadcrumb I18n.t("breadcrumbs.admin.members.create_web_account"), nil
      else
        add_breadcrumb I18n.t("breadcrumbs.admin.members.members_list"), admin_members_path
        add_breadcrumb I18n.t("breadcrumbs.admin.members.new_member"), nil
      end
    end

    def edit_person
      add_breadcrumb I18n.t("breadcrumbs.admin.members.members_list"), admin_members_path
      add_breadcrumb @person.full_name, admin_member_path(@person)
      add_breadcrumb I18n.t("breadcrumbs.admin.common.edit"), nil
    end

    def edit
      @user = @person.user

      if @user.nil?
        redirect_to edit_person_admin_member_path(@person)
        return
      end

      @array_right = available_roles_for_user(@user)
      @default_role = @user.system_role

      add_breadcrumb I18n.t("breadcrumbs.admin.members.members_list"), admin_members_path
      add_breadcrumb @person.full_name, admin_member_path(@person)
      add_breadcrumb I18n.t("breadcrumbs.admin.common.edit"), nil
    end

    def create
      form = Admin::MemberCreationForm.new(member_creation_params)
      result = form.call

      if result.success?
        redirect_to admin_member_path(result.person), notice: result.message
      else
        @member_creation_form = Admin::MemberCreationForm.new
        flash.now[:alert] = result.message
        render :new, status: :unprocessable_content
      end
    end

    def update
      handle_member_update
    end

    def destroy
      deleter = UserManagement::UserDeleter.new(
        person_id: @person.id,
        deleted_by_id: current_user.id,
        reason: "Suppression via interface admin"
      )
      result = deleter.call

      respond_to do |format|
        if result.success?
          format.html { redirect_to admin_members_path, status: :see_other, notice: t(".person_deleted_notice") }
          format.json { head :no_content }
        else
          format.html { redirect_to admin_members_path, status: :see_other, alert: t(".destruction_failed_alert_html", message: result.message) }
          format.json { head :unprocessable_content }
        end
      end
    end

    def create_web_account
      if @person.user.present?
        redirect_to admin_member_path(@person), alert: t(".web_account_already_exists") and return
      end

      if @person.email.blank?
        redirect_to admin_member_path(@person), alert: t(".email_required_for_web_account") and return
      end

      result = People::UserAccountCreator.new(
        person: @person,
        system_role: "web_visitor",
        created_by_admin: true
      ).call

      if result.success?
        redirect_to admin_member_path(@person), notice: t(".web_account_created")
      else
        redirect_to admin_member_path(@person), alert: result.message
      end
    end

    def restore
      @user = User.unscoped.find(params[:id])

      if @user.update(deleted: false, deleted_at: nil)
        redirect_to admin_members_path, notice: t(".restored_notice")
      else
        redirect_to admin_members_path, alert: t(".restore_failed_alert")
      end
    end

    private

    def set_person
      @person = Person.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to admin_members_path, alert: t(".person_not_found_alert")
    end

    def set_breadcrumbs
      add_breadcrumb I18n.t("breadcrumbs.admin.common.dashboard"), admin_dashboard_index_path
    end

    def check_deletion_permissions
      user = @person&.user
      return if user.nil?
      return if current_user.has_higher_permissions?(user)

      redirect_to admin_members_path, alert: I18n.t("admin.members.check_deletion_permissions.higher_privileges")
    end

    def available_roles_for_user(user)
      return [] if user.nil?

      if Current.user&.super_admin?
        User.system_roles.keys.reject { |role| role == "super_admin" }
      elsif Current.user&.admin?
        %w[volunteer web_visitor]
      else
        []
      end
    end

    def require_super_admin
      return if Current.user&.super_admin?

      redirect_to admin_members_path, alert: I18n.t("admin.members.require_super_admin.restore_denied_alert")
    end

    def load_recent_payments(person)
      return [] unless person

      PaymentQuery.with_person_and_recorded_by
                  .where(person_id: person.id)
                  .order(created_at: :desc)
                  .limit(10)
    end
  end
end
