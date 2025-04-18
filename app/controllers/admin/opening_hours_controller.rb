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
    updated_hours = params.require(:opening_hours).permit(:lundi, :mardi, :mercredi, :jeudi, :vendredi, :samedi, :dimanche).to_h # xss vulnerability resolved
    if valid_hours?(updated_hours)
      Rails.cache.write("opening_hours", updated_hours)
      flash[:success] = "Les horaires d'ouverture ont été mis à jour avec succès !"
      redirect_to admin_opening_hours_path, notice: "Les horaires ont été mis à jour avec succès."
    else
      flash[:error] = "Le format des horaires est invalide. Veuillez utiliser le format HH:MM - HH:MM ou 'Fermé'."
      @opening_hours = updated_hours
      render :edit, status: :unprocessable_entity
    end
  end


  private

  def require_admin_or_super_admin
    unless Current.user&.system_role.in?(%w[admin super_admin volunteer])
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
      time.match?(/\A((?:[0-9]|[01][0-9]|2[0-3]):[0-5][0-9] - (?:[0-9]|[01][0-9]|2[0-3]):[0-5][0-9]|Fermé)\z/i)
    end
  end
end
end
