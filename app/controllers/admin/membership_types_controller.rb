# frozen_string_literal: true

module Admin
  class MembershipTypesController < BaseController
    before_action :set_membership_type, only: %i[show edit update destroy change_price archive unarchive]
    before_action :set_breadcrumbs
    before_action :require_admin_rights, only: %i[new create edit update destroy change_price archive unarchive]

    def index
      @membership_types = MembershipType.current_versions.order(:category, :price_cents)
      @archived_membership_types = MembershipType.where.not(effective_until: nil).order(effective_until: :desc)
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

    # Édition classique : jamais le prix, la version ou effective_from — ces
    # champs identifient la ligne pour l'historique/la compta, ils passent
    # uniquement par #change_price (create_price_change!). Voir docs/architecture/models.md §4.8.
    def update
      if @membership_type.update(membership_type_update_params)
        respond_to do |format|
          format.html { redirect_to admin_membership_types_path, notice: t(".html_notice") }
          format.turbo_stream { redirect_to admin_membership_types_path, notice: t(".turbo_notice") }
        end
      else
        flash.now[:alert] = @membership_type.errors.full_messages.to_sentence
        render :edit, status: :unprocessable_content
      end
    end

    def change_price
      new_price_cents = (params[:price].to_f * 100).round

      @membership_type.create_price_change!(new_price_cents, reason: params[:reason], user: Current.user)
      redirect_to admin_membership_types_path, notice: t(".success")
    rescue ActiveRecord::RecordInvalid => e
      redirect_to edit_admin_membership_type_path(@membership_type), alert: t(".failure", message: e.message)
    end

    def archive
      @membership_type.archive!(user: Current.user)
      redirect_to admin_membership_types_path, notice: t(".success")
    rescue ActiveRecord::RecordInvalid => e
      redirect_to admin_membership_types_path, alert: t(".failure", message: e.message)
    end

    def unarchive
      @membership_type.unarchive!(user: Current.user)
      redirect_to admin_membership_types_path, notice: t(".success")
    rescue ActiveRecord::RecordInvalid => e
      redirect_to admin_membership_types_path, alert: t(".failure", message: e.message)
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
      @membership_type = MembershipType.find(params.expect(:id))
    end

    def set_breadcrumbs
      add_breadcrumb I18n.t("breadcrumbs.admin.common.dashboard"), admin_dashboard_index_path
      add_breadcrumb I18n.t("breadcrumbs.admin.membership_types.types"), admin_membership_types_path
    end

    def membership_type_params
      params.expect(membership_type: %i[name category rate_kind price_euros description effective_from version created_by_user_id])
    end

    # Édition classique : nom/description seulement. category/rate_kind
    # définissent ce que signifie ce type pour les Membership déjà achetées —
    # les changer en place réinterpréterait silencieusement un achat passé.
    # Prix : #change_price.
    def membership_type_update_params
      params.expect(membership_type: %i[name description])
    end
  end
end
