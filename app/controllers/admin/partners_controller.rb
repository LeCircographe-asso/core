# frozen_string_literal: true

module Admin
  class PartnersController < BaseController
    before_action :set_breadcrumbs
    before_action :require_admin_rights, only: %i[create update destroy reorder]
    before_action :set_partner, only: %i[edit update destroy]

    def index
      @partners = Partner.ordered
      add_breadcrumb I18n.t("breadcrumbs.admin.partners.index"), nil
    end

    def new
      @partner = Partner.new
    end

    def create
      @partner = Partner.new(partner_params)
      if @partner.save
        redirect_to admin_partners_path, notice: t(".created")
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @partner.update(partner_params)
        redirect_to admin_partners_path, notice: t(".updated")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def reorder
      Array(params[:ids]).each_with_index do |id, index|
        Partner.find_by(id: id.to_i)&.update(display_order: index + 1)
      end
      head :ok
    end

    def destroy
      @partner.destroy!
      redirect_to admin_partners_path, notice: t(".destroyed"), status: :see_other
    end

    private

    def set_breadcrumbs
      add_breadcrumb I18n.t("breadcrumbs.admin.common.administration"), admin_dashboard_index_path
    end

    def set_partner
      @partner = Partner.find(params[:id])
    end

    def partner_params
      params.expect(partner: [ :name, :category, :bio, :url, :initials, :logo ])
    end
  end
end
