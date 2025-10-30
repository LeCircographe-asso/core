module PersonQuery
  def self.with_active_membership
    Person.joins(:memberships)
          .where(memberships: { status: "active" })
          .where("memberships.ended_at > ?", Time.current)
  end

  def self.with_expiring_membership(days = 30)
    Person.joins(:memberships)
          .where(memberships: { status: "active" })
          .where("memberships.ended_at BETWEEN ? AND ?", Time.current, days.days.from_now)
  end

  def self.with_expired_membership
    Person.joins(:memberships)
          .where(memberships: { status: "active" })
          .where("memberships.ended_at < ?", Time.current)
  end

  def self.without_membership
    Person.left_joins(:memberships)
          .where(memberships: { id: nil })
  end

  def self.with_user_account
    Person.joins(:user)
  end

  def self.without_user_account
    Person.left_joins(:user).where(users: { id: nil })
  end

  def self.search_by_contact(search_term)
    return Person.none if search_term.blank?

    Person.where(
      "first_name ILIKE ? OR last_name ILIKE ? OR email ILIKE ? OR phone ILIKE ?",
      "%#{search_term}%", "%#{search_term}%", "%#{search_term}%", "%#{search_term}%"
    )
  end

  def self.main_people
    Person.where(deleted_at: nil)
  end

  def self.active
    Person.where(deleted_at: nil)
  end
end
