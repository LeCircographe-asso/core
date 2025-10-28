module Categorizable
  extend ActiveSupport::Concern

  # Humanization des catégories
  def category_humanized
    case category
    when "show" then "Spectacle"
    when "workshop" then "Atelier"
    when "volunteering" then "Bénévolat"
    when "other" then "Autre"
    when "basic" then "Basique"
    when "circus_full" then "Tarif Plein"
    when "circus_reduced" then "Tarif Réduit"
    else category.humanize
    end
  end

  # Vérifications de catégorie
  def show?
    category == "show"
  end

  def workshop?
    category == "workshop"
  end

  def volunteering?
    category == "volunteering"
  end

  def other?
    category == "other"
  end

  def basic?
    category == "basic"
  end

  def circus_full?
    category == "circus_full"
  end

  def circus_reduced?
    category == "circus_reduced"
  end

  def circus?
    circus_full? || circus_reduced?
  end

  # Méthodes de classe pour les humanizations
  class_methods do
    def humanize_category(category)
      case category.to_s
      when "show" then "Spectacle"
      when "workshop" then "Atelier"
      when "volunteering" then "Bénévolat"
      when "other" then "Autre"
      when "basic" then "Basique"
      when "circus_full" then "Tarif Plein"
      when "circus_reduced" then "Tarif Réduit"
      else category.to_s.humanize
      end
    end

    def category_badge_class(category)
      case category.to_s
      when "show" then "bg-purple-100 text-purple-800"
      when "workshop" then "bg-blue-100 text-blue-800"
      when "volunteering" then "bg-green-100 text-green-800"
      when "other" then "bg-gray-100 text-gray-800"
      when "basic" then "bg-blue-100 text-blue-800"
      when "circus_full" then "bg-green-100 text-green-800"
      when "circus_reduced" then "bg-yellow-100 text-yellow-800"
      else "bg-gray-100 text-gray-800"
      end
    end
  end
end
