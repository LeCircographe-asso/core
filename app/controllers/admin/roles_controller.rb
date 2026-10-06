# frozen_string_literal: true

module Admin
  # Vue d'ensemble des comptes ayant un rôle (super_admin/admin/volunteer) et
  # recherche d'un compte web_visitor à qui attribuer un rôle. Le changement
  # lui-même passe par Admin::Members::RolesController#update.
  class RolesController < BaseController
    before_action :require_admin_rights

    def index
      query = Admin::Roles::IndexQuery.new
      @users_with_role = query.users_with_role
      @search = params[:search].to_s.strip
      @search_results = query.search_web_visitors(@search)

      add_breadcrumb I18n.t("breadcrumbs.admin.common.dashboard"), admin_dashboard_index_path
      add_breadcrumb I18n.t("breadcrumbs.admin.roles.index"), nil
    end
  end
end
