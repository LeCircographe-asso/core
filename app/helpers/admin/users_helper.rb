module Admin::UsersHelper
  def latest_membership(user)
    user.user_memberships.order(created_at: :desc).first
  rescue
    nil
  end

  def membership_type_name(membership)
    return "Aucun" unless membership&.membership
    membership.membership.type_name.to_s.humanize
  rescue
    "Aucun"
  end

  def membership_status(membership)
    return "Inactif" unless membership
    membership.status == "active" ? "Actif" : "Inactif"
  rescue
    "Inactif"
  end

  def registration_date(user)
    first_membership = user.user_memberships.order(:created_at).first
    first_membership ? first_membership.created_at.strftime("%d/%m/%Y") : "N/A"
  rescue
    "N/A"
  end
end
