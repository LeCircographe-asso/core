module Admin
  class DashboardController < BaseController
    include OpeningHoursHelper
    include NotepadHelper
    def index
      @notepad = Rails.cache.fetch("notepad") || default_notepad
      @opening_hours = Rails.cache.fetch("opening_hours") || default_opening_hours
    end
  end
end
