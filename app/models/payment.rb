class Payment < ApplicationRecord
  belongs_to :user
  belongs_to :product_order

  enum :status, %i[success pending cancel], default: :pending
  enum :payment_type, %i[cash credit_card check]

  after_update :update_user_membership_if_paid

  def payment_successful?
    puts "#{product_order.id}"
    puts "**********************************************************************************************"
    product_order.payments.where(status: 'success').exists?
  end

  def update_user_membership_if_paid
    return unless payment_successful?
  
    # Déterminer quel type d'abonnement l'utilisateur doit avoir
    membership_type = determine_user_membership
    return unless membership_type
  
    # Vérifier s'il y a un abonnement actif et le mettre à jour, sinon en créer un
    user_membership = user.user_memberships.active.last
    if user_membership.nil?
      # Si l'utilisateur n'a pas d'abonnement actif, on en crée un
      user_membership = UserMembership.create!(user: user, membership_id: membership_type)
      puts '**********************************************************************************************'
      puts 'Membership créé'
    else
      # Si l'utilisateur a un abonnement actif, on met à jour sa date d'expiration
      user_membership.update!(membership_id: membership_type)
      puts '**********************************************************************************************'
      puts 'Membership mis à jour'
    end
    update_user_membership_end_date(user_membership) # Mise à jour de la end_date
  end

  def determine_user_membership
    puts "**********************************************************************************************"
    puts product_order
    product_names = product_order.product.product_name

    circus_products = [
      "Adhésion Cirque - Tarif Plein",
      "Upgrade Basic to Cirque - Tarif Plein",
      "Upgrade Basic to Cirque - Tarif Réduit",
      "Cotisation annuelle",
      "Cotisation trimestrielle",
      "Cotisation 10 séances",
      "Pass journée"
    ]

    return 2 if circus_products.any? { |name| product_names.include?(name) }
    return 1 if product_names.include?("Adhésion simple")
    return nil if product_names.include?("Donation")
  end

  def determine_end_date(product_name)
    case product_name
    when "Cotisation trimestrielle"
      3.months.from_now
    when "Pass journée"
      1.day.from_now
    when "Donation"
      nil
    else
      1.year.from_now
    end
  end

  def update_user_membership_end_date(user_membership)
    puts "**********************************************************************************************"
    puts user_membership.inspect
    product_name = product_order.product.product_name
    end_date = determine_end_date(product_name)

    if end_date
      user_membership.update!(end_date: end_date)
      puts '**********************************************************************************************'
      puts 'End date mise à jour'
      puts 'Membership mise à jour'
      puts "Mise à jour de l'abonnement pour l'utilisateur #{user.id} avec le type #{product_name}"

    end
  end
end
