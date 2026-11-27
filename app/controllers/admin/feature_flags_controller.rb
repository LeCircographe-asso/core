# frozen_string_literal: true

module Admin
  class FeatureFlagsController < BaseController
    before_action :require_super_admin

    def index
      @flags = FeatureFlag.all
      add_breadcrumb I18n.t("breadcrumbs.admin.common.dashboard"), admin_dashboard_index_path
      add_breadcrumb t(".title"), nil
    end
  end
end
