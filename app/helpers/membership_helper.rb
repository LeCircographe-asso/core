module MembershipHelper
  def membership_status_badge_class(status)
    case status.to_sym
    when :active
      "bg-green-100 text-green-800"
    when :pending
      "bg-yellow-100 text-yellow-800"
    when :expired
      "bg-red-100 text-red-800"
    when :canceled
      "bg-gray-100 text-gray-800"
    else
      "bg-gray-100 text-gray-800"
    end
  end

  def membership_status_display_name(status)
    case status.to_sym
    when :active
      "Actif"
    when :pending
      "En attente"
    when :expired
      "Expiré"
    when :canceled
      "Annulé"
    else
      status.to_s.humanize
    end
  end

  def membership_type_badge_class(type_name)
    case type_name.to_sym
    when :Basic
      "bg-blue-100 text-blue-800"
    when :Circus
      "bg-purple-100 text-purple-800"
    when :No_Member
      "bg-gray-100 text-gray-800"
    else
      "bg-gray-100 text-gray-800"
    end
  end

  def membership_type_display_name(type_name)
    case type_name.to_sym
    when :Basic
      "Basic"
    when :Circus
      "Circus"
    when :No_Member
      "Non membre"
    else
      type_name.to_s.humanize
    end
  end

  # Nouvelles méthodes Person-Based
  def person_membership_status(person)
    return "Non membre" unless person&.has_active_membership?

    membership = person.current_membership
    membership_status_display_name(membership.status)
  end

  def person_membership_type(person)
    return "Non membre" unless person&.has_active_membership?

    membership = person.current_membership
    membership.membership_type.name
  end

  def person_membership_badge_class(person)
    return "bg-gray-100 text-gray-800" unless person&.has_active_membership?

    membership = person.current_membership
    membership_type_badge_class(membership.membership_type.name)
  end

  def format_date(date)
    date&.strftime("%d/%m/%Y") || "Non renseigné"
  end

  # Méthodes obsolètes désactivées - utilisez l'architecture Person-Based
  # def user_membership_status(user)
  #   # Utilisez user.person.current_membership à la place
  # end

  # def user_membership_type(user)
  #   # Utilisez user.person.current_membership.membership_type à la place
  # end
end
