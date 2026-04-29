module Admin
  class OpeningHoursController < BaseController
    before_action :set_opening_hours, only: %i[show edit]
    before_action :set_breadcrumbs
    include OpeningHoursHelper

    def show
      add_breadcrumb "Horaires d'ouverture", nil
    end

    def edit
      add_breadcrumb "Horaires d'ouverture", admin_opening_hours_path
      add_breadcrumb 'Modifier', nil
    end

    def update
      # Reconstruire les horaires à partir des sélecteurs individuels
      updated_hours = {}
      days = %w[lundi mardi mercredi jeudi vendredi samedi dimanche]

      days.each do |day|
        # Vérifier si le jour est fermé
        closed_param = params["closed_#{day}"]
        if closed_param == '1'
          updated_hours[day] = 'Fermé'
        else
          # Reconstruire les horaires à partir des sélecteurs
          open_hour = params["open_hour_#{day}"].to_i
          open_minute = params["open_minute_#{day}"].to_i
          close_hour = params["close_hour_#{day}"].to_i
          close_minute = params["close_minute_#{day}"].to_i

          updated_hours[day] = "#{open_hour.to_s.rjust(2, '0')}:#{open_minute.to_s.rjust(2, '0')} - #{close_hour.to_s.rjust(2, '0')}:#{close_minute.to_s.rjust(2, '0')}"
        end
      end

      # Persist via cache for now (can be moved to a Setting model later)
      Rails.cache.write('opening_hours', updated_hours)
      redirect_to admin_opening_hours_path, notice: 'Horaires mis à jour avec succès'
    end

    private

    def set_opening_hours
      @opening_hours = Rails.cache.fetch('opening_hours') || default_opening_hours
    end

    def set_breadcrumbs
      # No need to add dashboard breadcrumb as it's already in the partial
    end
  end
end
