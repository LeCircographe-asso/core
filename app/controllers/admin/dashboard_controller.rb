module Admin
  class DashboardController < BaseController
    def index
      @notepad = Rails.cache.fetch("notepad") || ""
      @opening_hours = Rails.cache.fetch("opening_hours") || DEFAULT_OPENING_HOURS
    end

    DEFAULT_OPENING_HOURS = {
      lundi: "Fermé",
      mardi: "14:00 - 22:00",
      mercredi: "14:00 - 22:00",
      jeudi: "14:00 - 22:00",
      vendredi: "14:00 - 22:00",
      samedi: "14:00 - 22:00",
      dimanche: "14:00 - 22:00"
    }.freeze
  end
end
