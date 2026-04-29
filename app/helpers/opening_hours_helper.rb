module OpeningHoursHelper
  # Méthode d'instance pour les contrôleurs qui incluent ce module
  delegate :default_opening_hours, to: :OpeningHoursHelper

  # Méthode de module accessible directement
  def self.default_opening_hours
    {
      lundi: 'Fermé',
      mardi: '14:00 - 22:00',
      mercredi: '14:00 - 22:00',
      jeudi: '14:00 - 22:00',
      vendredi: '14:00 - 22:00',
      samedi: '14:00 - 22:00',
      dimanche: '14:00 - 22:00'
    }.freeze
  end
end
