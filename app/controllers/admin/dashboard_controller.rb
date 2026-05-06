# frozen_string_literal: true

module Admin
  class DashboardController < BaseController
    include OpeningHoursHelper
    include NotepadHelper

    def index
      @notepad = Rails.cache.fetch("notepad") || default_notepad
      @opening_hours = Rails.cache.fetch("opening_hours") || default_opening_hours
      @stats = build_dashboard_stats
    end

    private

    def build_dashboard_stats
      Admin::DashboardStatsBuilder.call
    end
  end
end
