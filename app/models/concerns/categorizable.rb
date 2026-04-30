# frozen_string_literal: true

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
    when "circus" then "Cirque"
    when "event" then "Événement"
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

  def circus?
    category == "circus"
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
      when "circus" then "Cirque"
      when "event" then "Événement"
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
      when "circus" then "bg-green-100 text-green-800"
      when "event" then "bg-yellow-100 text-yellow-800"
      else "bg-gray-100 text-gray-800"
      end
    end
  end
end
