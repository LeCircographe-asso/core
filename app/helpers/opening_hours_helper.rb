# frozen_string_literal: true

module OpeningHoursHelper
  # Méthode d'instance pour les contrôleurs qui incluent ce module
  delegate :default_opening_hours, to: :OpeningHoursHelper

  # Méthode de module accessible directement
  def self.default_opening_hours
    OpeningHour::DEFAULT_SCHEDULE.dup
  end

  def current_opening_hours
    OpeningHour.schedule_hash
  rescue ActiveModel::MissingAttributeError, NoMethodError
    default_opening_hours
  end
end
