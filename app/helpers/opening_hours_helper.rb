module OpeningHoursHelper
  def default_opening_hours
  {
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
