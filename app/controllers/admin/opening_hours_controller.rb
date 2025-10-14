module Admin
class OpeningHoursController < BaseController
  before_action :require_admin_or_super_admin, only: %i[ edit update ]
  before_action :set_opening_hours, only: %i[ show edit ]
  before_action :set_breadcrumbs
  include OpeningHoursHelper

  def show
    add_breadcrumb "Horaires d'ouverture", nil
  end

  def edit
    add_breadcrumb "Horaires d'ouverture", admin_opening_hours_path
    add_breadcrumb "Modifier", nil
  end

  def update
    # Reconstruire les horaires à partir des sélecteurs individuels
    updated_hours = {}
    days = %w[lundi mardi mercredi jeudi vendredi samedi dimanche]

    days.each do |day|
      # Vérifier si le jour est fermé
      closed_param = params["closed_#{day}"]
      if closed_param == "1"
        updated_hours[day] = "Fermé"
      else
        # Reconstruire les horaires à partir des sélecteurs
        open_hour = params["open_hour_#{day}"].to_i
        open_minute = params["open_minute_#{day}"].to_i
        close_hour = params["close_hour_#{day}"].to_i
        close_minute = params["close_minute_#{day}"].to_i

        updated_hours[day] = "#{open_hour.to_s.rjust(2, '0')}:#{open_minute.to_s.rjust(2, '0')} - #{close_hour.to_s.rjust(2, '0')}:#{close_minute.to_s.rjust(2, '0')}"
      end
    end

    if valid_hours?(updated_hours)
      Rails.cache.write("opening_hours", updated_hours)
      redirect_to admin_opening_hours_path, notice: "Les horaires ont été mis à jour avec succès."
    else
      @opening_hours = updated_hours
      @error_message = "Erreur : l'heure de fermeture doit être après l'heure d'ouverture pour tous les jours ouverts."
      render :edit, status: :unprocessable_entity
    end
  end


  private

  def require_admin_or_super_admin
    unless Current.user&.system_role.in?(%w[admin super_admin])
      redirect_to root_path, alert: "Vous n'avez pas accès à cette page."
    end
  end

  def set_opening_hours
    @opening_hours = Rails.cache.fetch("opening_hours") || default_opening_hours
  end

  def set_breadcrumbs
    # No need to add dashboard breadcrumb as it's already in the partial
  end

  def valid_hours?(hours)
    hours.values.all? do |time|
      if time.downcase == "fermé"
        true
      elsif time.match?(/\A(?:[0-9]|[01][0-9]|2[0-3]):[0-5][0-9] - (?:[0-9]|[01][0-9]|2[0-3]):[0-5][0-9]\z/)
        # Validation logique : fermeture > ouverture
        open_time, close_time = time.split(" - ")
        open_minutes = time_to_minutes(open_time)
        close_minutes = time_to_minutes(close_time)
        close_minutes > open_minutes
      else
        false
      end
    end
  end

  def time_to_minutes(time_str)
    hour, minute = time_str.split(":").map(&:to_i)
    hour * 60 + minute
  end
end
end
