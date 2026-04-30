module Statusable
  extend ActiveSupport::Concern

  # Humanization des statuts
  def status_humanized
    case status
    when 'pending' then 'En attente'
    when 'active' then 'Actif'
    when 'inactive' then 'Inactif'
    when 'expired' then 'Expiré'
    when 'success' then 'Réussi'
    when 'cancel' then 'Annulé'
    when 'consumed' then 'Consommé'
    else status.humanize
    end
  end

  # Vérifications de statut
  def active?
    status == 'active'
  end

  def pending?
    status == 'pending'
  end

  def expired?
    status == 'expired'
  end

  def inactive?
    status == 'inactive'
  end

  def successful?
    status == 'success'
  end

  def cancelled?
    status == 'cancel'
  end

  # Méthodes d'instance pour les badges
  def status_badge_class
    case status.to_s
    when 'active', 'success' then 'bg-green-100 text-green-800'
    when 'pending' then 'bg-yellow-100 text-yellow-800'
    when 'expired', 'cancel', 'inactive' then 'bg-red-100 text-red-800'
    else 'bg-gray-100 text-gray-800'
    end
  end

  # Méthodes de classe pour les humanizations
  class_methods do
    def humanize_status(status)
      case status.to_s
      when 'pending' then 'En attente'
      when 'active' then 'Actif'
      when 'inactive' then 'Inactif'
      when 'expired' then 'Expiré'
      when 'success' then 'Réussi'
      when 'cancel' then 'Annulé'
      when 'consumed' then 'Consommé'
      else status.to_s.humanize
      end
    end

    def status_badge_class(status)
      case status.to_s
      when 'active', 'success' then 'bg-green-100 text-green-800'
      when 'pending' then 'bg-yellow-100 text-yellow-800'
      when 'expired', 'cancel', 'inactive' then 'bg-red-100 text-red-800'
      else 'bg-gray-100 text-gray-800'
      end
    end
  end
end
