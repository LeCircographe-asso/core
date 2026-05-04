# frozen_string_literal: true

module Admin
  class MembershipTypesController < BaseController
    before_action :set_membership_type, only: %i[show edit update destroy]
    before_action :set_breadcrumbs

    def index
      @membership_types = MembershipType.order(:category, :price_cents)
      add_breadcrumb I18n.t("breadcrumbs.admin.membership_types.types"), nil
    end

    def show
      @memberships = @membership_type.memberships.includes(:person).order(created_at: :desc).limit(10)
      add_breadcrumb I18n.t("breadcrumbs.admin.membership_types.type_named", name: @membership_type.name), nil
    end

    def new
      @membership_type = MembershipType.new(
        effective_from: Date.current,
        rate_kind: "standard",
        version: 1,
        created_by_user: Current.user
      )
      add_breadcrumb I18n.t("breadcrumbs.admin.membership_types.new_type"), nil
    end

    def edit
      add_breadcrumb I18n.t("breadcrumbs.admin.membership_types.edit_named", name: @membership_type.name), nil
    end

    def create
      @membership_type = MembershipType.new(membership_type_params.merge(created_by_user: Current.user))

      if @membership_type.save
        respond_to do |format|
          format.html { redirect_to admin_membership_types_path, notice: t(".html_notice") }
          format.turbo_stream { redirect_to admin_membership_types_path, notice: t(".turbo_notice") }
        end
      else
        flash.now[:alert] = @membership_type.errors.full_messages.to_sentence
        render :new, status: :unprocessable_content
      end
    end

    def update
      if @membership_type.update(membership_type_params)
        respond_to do |format|
          format.html { redirect_to admin_membership_types_path, notice: t(".html_notice") }
          format.turbo_stream { redirect_to admin_membership_types_path, notice: t(".turbo_notice") }
        end
      else
        flash.now[:alert] = @membership_type.errors.full_messages.to_sentence
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      if @membership_type.destroy
        redirect_to admin_membership_types_path, notice: t(".destroyed")
      else
        redirect_to admin_membership_types_path, alert: @membership_type.errors.full_messages.to_sentence
      end
    end

    private

    def set_membership_type
      @membership_type = MembershipType.find(params[:id])
    end

    def set_breadcrumbs
      add_breadcrumb I18n.t("breadcrumbs.admin.common.administration"), admin_dashboard_index_path
      add_breadcrumb I18n.t("breadcrumbs.admin.membership_types.types"), admin_membership_types_path
    end

    def membership_type_params
      params.expect(membership_type: %i[name category rate_kind price_cents description effective_from version created_by_user_id])
    end
  end
end
