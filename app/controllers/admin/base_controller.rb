# frozen_string_literal: true

module Admin
  class BaseController < ApplicationController
    before_action :require_admin_or_super_admin

    private

    def require_admin_or_super_admin
      return if Current.user&.has_privileges?

      redirect_to root_path, alert: I18n.t("admin.base.unauthorized_alert")
    end
  end
end
