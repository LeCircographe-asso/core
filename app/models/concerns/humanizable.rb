module Humanizable
  extend ActiveSupport::Concern

  # Humanization des méthodes de paiement
  def payment_method_humanized
    case payment_method
    when 'cash' then 'Espèces'
    when 'card' then 'Carte bancaire'
    when 'cheque' then 'Chèque'
    when 'transfer' then 'Virement'
    when 'offered' then 'Offert'
    else payment_method.humanize
    end
  end

  # Humanization des statuts de paiement
  def payment_status_humanized
    case status
    when 'success' then 'Réussi'
    when 'pending' then 'En attente'
    when 'cancel' then 'Annulé'
    else status.humanize
    end
  end

  # Alias pour compatibilité
  def status_humanized
    payment_status_humanized
  end

  # Humanization des statuts d'adhésion
  def membership_status_humanized
    case status
    when 'active' then 'Actif'
    when 'pending' then 'En attente'
    when 'expired' then 'Expiré'
    when 'canceled' then 'Annulé'
    else status.humanize
    end
  end

  # Humanization des catégories d'adhésion
  def membership_category_humanized
    case category
    when 'basic' then 'Basique'
    when 'circus' then 'Cirque'
    when 'event' then 'Événement'
    else category.humanize
    end
  end

  def contribution_duration_humanized
    case duration
    when 'day' then 'Journée'
    when 'trimester' then 'Trimestriel'
    when 'annual' then 'Annuel'
    when 'pack10' then 'Pack 10'
    else duration.humanize
    end
  end

  def duration_humanized
    contribution_duration_humanized
  end

  # Méthodes de classe pour les humanizations
  class_methods do
    def humanize_payment_method(method)
      case method.to_s
      when 'cash' then 'Espèces'
      when 'card' then 'Carte bancaire'
      when 'cheque' then 'Chèque'
      when 'transfer' then 'Virement'
      when 'offered' then 'Offert'
      else method.to_s.humanize
      end
    end

    def humanize_payment_status(status)
      case status.to_s
      when 'success' then 'Réussi'
      when 'pending' then 'En attente'
      when 'cancel' then 'Annulé'
      else status.to_s.humanize
      end
    end

    def humanize_membership_status(status)
      case status.to_s
      when 'active' then 'Actif'
      when 'pending' then 'En attente'
      when 'expired' then 'Expiré'
      when 'canceled' then 'Annulé'
      else status.to_s.humanize
      end
    end

    def humanize_membership_category(category)
      case category.to_s
      when 'basic' then 'Basique'
      when 'circus' then 'Cirque'
      when 'event' then 'Événement'
      else category.to_s.humanize
      end
    end

    def humanize_contribution_duration(duration)
      case duration.to_s
      when 'day' then 'Journée'
      when 'trimester' then 'Trimestriel'
      when 'annual' then 'Annuel'
      when 'pack10' then 'Pack 10'
      else duration.to_s.humanize
      end
    end
  end
end
