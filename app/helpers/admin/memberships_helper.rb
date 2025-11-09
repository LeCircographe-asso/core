module Admin::MembershipsHelper
  # Calculer et formater la différence de prix pour l'upgrade
  def upgrade_price_difference(new_membership_type)
    return "0€" unless @current_membership&.membership_type

    old_price = @current_membership.membership_type.price_cents
    new_price = new_membership_type.price_cents
    difference = new_price - old_price

    if difference > 0
      "+#{difference / 100.0}€"
    elsif difference < 0
      "#{difference / 100.0}€"
    else
      "0€"
    end
  end

  # Formater le nom avec la différence de prix pour l'upgrade
  def upgrade_name_with_price(membership_type)
    base_name = membership_type.name
    price_diff = upgrade_price_difference(membership_type)

    if price_diff == "0€"
      "#{base_name} - Gratuit"
    else
      "#{base_name} - #{price_diff}"
    end
  end
end
