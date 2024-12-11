class OpeningHoursController < ApplicationController
  before_action :require_admin_or_godmode, only: [:edit, :update]

  DEFAULT_OPENING_HOURS = {
    lundi: 'Fermé',
    mardi: '14:00 - 22:00',
    mercredi: '14:00 - 22:00',
    jeudi: '14:00 - 22:00',
    vendredi: '14:00 - 22:00',
    samedi: '14:00 - 22:00',
    dimanche: '14:00 - 22:00'
  }.freeze

  def show
    @opening_hours = Rails.cache.fetch('opening_hours') || DEFAULT_OPENING_HOURS
  end

  def edit
    @opening_hours = Rails.cache.fetch('opening_hours') || DEFAULT_OPENING_HOURS
  end

  def update
    updated_hours = params[:opening_hours].to_unsafe_h
    if valid_hours?(updated_hours)
      Rails.cache.write('opening_hours', updated_hours)
      flash[:notice] = "Les horaires d'ouverture ont été mis à jour !"
      redirect_to opening_hours_path
    else
      flash[:alert] = "Le format des horaires est invalide."
      render :edit
    end
  end


  private

  def require_admin_or_godmode
    unless Current.user&.role.in?(%w[admin godmode volunteer])
      redirect_to root_path, alert: "Vous n'avez pas accès à cette page."
    end
  end

  def valid_hours?(hours)
    hours.values.all? { |time| time.match?(/\A(\d{2}:\d{2} - \d{2}:\d{2}|Fermé)\z/) }
  end

end