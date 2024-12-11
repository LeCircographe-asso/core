module Admin
  class DashboardController < BaseController
    before_action :require_admin_or_godmode

    def index
    end
  end
end