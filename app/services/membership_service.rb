# DEPRECATED: Ancien service obsolète - remplacé par Person-Based Architecture
# Utilisez maintenant les services:
# - People::Register (création Person + User + Membership)
# - Memberships::Create (création d'adhésions)
# - Memberships::Upgrade (mise à niveau d'adhésions)
class MembershipService
  # Méthodes désactivées - utilisez le nouveau système Person-Based
  # def self.assign_basic_membership(user); end
  # def self.activate_membership(user_membership); end
  # def self.expire_membership(user_membership); end
  # def self.cancel_membership(user_membership); end

  def self.active_memberships_count
    # Adapté au nouveau modèle Person-Based
    Membership.where(status: 'active').count
  end

  def self.membership_type_count(type_name)
    # Adapté au nouveau modèle Person-Based
    case type_name.to_s.downcase
    when 'basic'
      Membership.joins(:membership_type)
                .where(membership_types: { category: 'basic' }, status: 'active')
                .count
    when 'circus'
      Membership.joins(:membership_type)
                .where(membership_types: { category: ['circus_full', 'circus_reduced'] }, status: 'active')
                .count
    else
      0
    end
  end
end
