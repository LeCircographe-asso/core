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
      @person_preview = Person.new

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

      @array_right = Current.user.assignable_roles
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
        @member_creation_form = form
        @person_preview = build_person_preview(form)
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
      @person = Person.find(params[:id])
      @user = User.unscoped.find_by!(person_id: @person.id)

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


    # Reconstruit un Person non persisté à partir des valeurs soumises, pour
    # réafficher le formulaire "nouvel adhérent" sans perdre la saisie en cas d'échec.
    def build_person_preview(source)
      Person.new(
        first_name: source.first_name,
        last_name: source.last_name,
        email: source.email,
        phone: source.phone,
        address: source.address,
        birth_date: source.birth_date,
        specialty: source.specialty,
        get_involved: source.get_involved,
        image_rights: source.image_rights,
        reduced_rate_eligible: source.reduced_rate_eligible,
        reduced_rate_reason: source.reduced_rate_reason,
        reduced_rate_proof: source.reduced_rate_proof
      )
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
