# DEPRECATED: Ancien modèle obsolète - remplacé par Person-Based Architecture
# Ce modèle est conservé temporairement pour la migration des données
# TODO: Supprimer après migration complète
class UserMembership < ApplicationRecord
  # Désactivé - utilisez le nouveau système Person + Membership
  # enum :status, %i[active pending expired canceled], default: :pending
  # belongs_to :membership
  # belongs_to :user
  # belongs_to :produit, optional: true
  # belongs_to :order, optional: true
  # before_update :expire_previous_memberships, if: -> { status_changed?(to: "active") }
  
  # Méthodes désactivées - utilisez le nouveau système
  # def activate!; end
  # def expire!; end  
  # def cancel!; end
  # def status_display_name; end
  # def status_badge_class; end
  # def membership_type_display_name; end
  # def membership_type_badge_class; end
  # private
  # def expire_previous_memberships; end
end
