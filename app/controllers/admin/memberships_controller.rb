# frozen_string_literal: true

module Admin
  class MembershipsController < BaseController
    before_action :set_person, only: %i[show edit update destroy]
    before_action :set_person_for_create, only: [ :create ]
    before_action :set_breadcrumbs

    def index
      @people = Person.includes(:memberships, :user).all
      add_breadcrumb I18n.t("breadcrumbs.admin.memberships.management"), nil
    end

    def show
      @membership = @person.current_membership
      @membership_types = MembershipType.all
      @contribution_formulas = ContributionFormula.all

      add_person_context_breadcrumbs(@person, I18n.t("breadcrumbs.admin.memberships.membership"))
    end

    def new
      @person = Person.find(params[:person_id]) if params[:person_id]

      if params[:upgrade] == "true" && @person&.current_membership&.basic?
        @membership_types = MembershipType.circus_types.available_for(@person).order(:price_cents)
        @is_upgrade = true
        @current_membership = @person.current_membership
        add_person_context_breadcrumbs(@person, I18n.t("breadcrumbs.admin.memberships.upgrade_to_circus"))
      else
        @membership_types = @person.present? \
          ? MembershipType.available_for(@person).order(:price_cents) \
          : MembershipType.current_versions.order(:price_cents)
        @is_upgrade = false
        add_person_context_breadcrumbs(@person, I18n.t("breadcrumbs.admin.memberships.new_membership")) if @person.present?
        add_breadcrumb I18n.t("breadcrumbs.admin.memberships.new_membership"), nil unless @person.present?
      end
    end

    def edit
      @membership = @person.current_membership
      @membership_types = MembershipType.all
      add_person_context_breadcrumbs(@person, I18n.t("breadcrumbs.admin.memberships.edit_membership"))
    end

    def create
      params_hash = membership_purchase_params
      membership_type = MembershipType.find(params_hash[:membership_type_id])

      if upgrade_request_for?(@person, params_hash)
        handle_upgrade_flow(@person, membership_type, params_hash)
      else
        handle_creation_flow(@person, membership_type, params_hash)
      end
    end

    def update
      @membership = @person.current_membership

      result = People::MembershipUpdater.new(
        membership_id: @membership.id,
        membership_type_id: membership_params[:membership_type_id],
        started_at: membership_params[:started_at],
        ended_at: membership_params[:ended_at],
        updated_by_id: Current.user.id
      ).call

      if result.success?
        redirect_to admin_person_path(@person), notice: t(".success")
      else
        flash[:alert] = result.message
        redirect_to edit_admin_membership_path(@membership)
      end
    end

    def destroy
      @membership = @person.current_membership

      result = People::MembershipDeactivator.new(
        membership_id: @membership.id,
        deactivated_by_id: Current.user.id,
        reason: "Désactivation via interface admin"
      ).call

      if result.success?
        redirect_to admin_memberships_path, notice: t(".deactivated")
      else
        redirect_to admin_memberships_path, alert: result.message
      end
    end

    private

    def set_person
      @person = Person.find(params[:id])
    end

    def set_person_for_create
      @person = Person.find(membership_purchase_params[:person_id])
    end

    def set_breadcrumbs
      add_breadcrumb I18n.t("breadcrumbs.admin.common.administration"), admin_dashboard_index_path
    end

    def membership_params
      params.expect(membership: %i[person_id membership_type_id payment_method started_at ended_at])
    end

    def membership_purchase_params
      params.expect(membership: %i[person_id membership_type_id payment_method custom_amount_cents offer_reason upgrade donation_amount])
    end

    def payment_method_from(params_hash)
      params_hash[:payment_method].presence || "cash"
    end

    def custom_amount_from(params_hash)
      return nil unless params_hash[:payment_method] == "offered"

      params_hash[:custom_amount_cents].to_i
    end

    def donation_cents_from(params_hash)
      return nil if params_hash[:donation_amount].blank?

      cents = (params_hash[:donation_amount].to_f * 100).to_i
      cents.positive? ? cents : nil
    end

    def handle_upgrade_flow(person, membership_type, params_hash)
      result = People::MembershipUpgrader.new(
        person: person,
        new_membership_type_id: membership_type.id,
        payment_method: payment_method_from(params_hash),
        recorded_by_id: Current.user.id,
        custom_amount_cents: custom_amount_from(params_hash),
        offer_reason: params_hash[:offer_reason],
        donation_cents: donation_cents_from(params_hash)
      ).call

      if result.success?
        redirect_to admin_person_path(person), notice: build_upgrade_notice(membership_type, result, payment_method_from(params_hash))
      else
        redirect_to new_admin_membership_path(person_id: person.id, upgrade: params_hash[:upgrade]),
                    alert: t("admin.memberships.create.upgrade_failed_alert", message: result.message)
      end
    end

    def handle_creation_flow(person, membership_type, params_hash)
      result = People::MembershipCreator.new(
        person: person,
        membership_type_id: membership_type.id,
        payment_method: payment_method_from(params_hash),
        recorded_by_id: Current.user.id,
        custom_amount_cents: custom_amount_from(params_hash),
        offer_reason: params_hash[:offer_reason],
        donation_cents: donation_cents_from(params_hash)
      ).call

      if result.success?
        if result.already_existed
          redirect_to new_admin_membership_path(person_id: person.id),
                      alert: t(".duplicate_active")
        else
          redirect_to admin_person_path(person),
                      notice: t(".success_with_contribution_hint")
        end
      else
        redirect_to new_admin_membership_path(person_id: person.id),
                    alert: t("admin.memberships.create.membership_creation_failed_alert", message: result.message)
      end
    end

    def upgrade_request_for?(person, params_hash)
      params_hash[:upgrade] == "true" && person.current_membership&.basic?
    end

    def build_upgrade_notice(membership_type, result, payment_method)
      message =
        if payment_method == "offered"
          I18n.t("admin.memberships.create.upgrade_notice_offered", name: membership_type.name)
        else
          amount = result.payment&.total_cents || membership_type.price_cents
          I18n.t(
            "admin.memberships.create.upgrade_notice_paid",
            name: membership_type.name,
            amount: (amount / 100.0).round(2)
          )
        end

      if result.member_number_changed
        message += I18n.t(
          "admin.memberships.create.upgrade_notice_member_number_suffix",
          old_number: result.old_member_number,
          new_number: result.new_member_number
        )
      end

      message
    end
  end
end
