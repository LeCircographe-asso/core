class Payment < ApplicationRecord
  belongs_to :user
  belongs_to :order
  has_many :product_orders, through: :order # Ajout de la relation product_order

  enum :status, %i[success pending cancel], default: :pending
  enum :payment_type, %i[cash credit_card check]

  after_update :update_user_membership_if_paid
  after_update :createBookOfEntry

  def payment_successful?
    puts "#{order.id}"
    order.payments.where(status: 'success').exists?
  end

  def createBookOfEntry
    # Vérifie si le produit acheté est un "Book of Entry"
    product_order = self.product_orders.first # Assurez-vous que product_orders est lié correctement
    if product_order.product.product_name == "Cotisation 10 séances"
      BookOfEntry.create!(user_id: self.user_id, product_id: product_order.product.id, remaining: 10, total_entry: 10)
    end
  end

  def update_user_membership_if_paid
    return unless payment_successful?

    membership_type = determine_user_membership
    return unless membership_type

    user_membership = user.user_memberships.where(status: :active).last
    if user_membership.nil?
      # Si l'utilisateur n'a pas d'abonnement actif, on en crée un
      user_membership = UserMembership.create!(user: user, membership_id: membership_type, start_date: created_at, status: :active)
      puts 'Membership créé'
    else
      # Si l'utilisateur a un abonnement actif, on met à jour sa date d'expiration
      user_membership.update!(membership_id: membership_type)
      puts 'Membership mis à jour'
    end
    update_user_membership_end_date(user_membership)
  end

  def determine_user_membership
    
    product_names = product_orders.map { |po| po.product.product_name }.join(', ')
    circus = Membership.find_by(type_name: :Circus).id
    basic = Membership.find_by(type_name: :Basic).id
    no_member = Membership.find_by(type_name: :No_Member).id

    circus_products = [
      "Adhésion Cirque - Tarif Plein",
      "Upgrade Basic to Cirque - Tarif Plein",
      "Upgrade Basic to Cirque - Tarif Réduit",
      "Cotisation annuelle",
      "Cotisation trimestrielle",
      "Cotisation 10 séances",
      "Pass journée"
    ]

    return circus if circus_products.any? { |name| product_names.include?(name) }
    return basic if product_names.include?("Adhésion simple")
    return no_member if product_names.include?("Donation")
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
    product_name = product_orders.first.product.product_name # Modifié pour prendre le premier produit
    end_date = determine_end_date(product_name)

    if end_date
      user_membership.update!(status: :active, end_date: end_date)
      puts "Mise à jour de l'abonnement pour l'utilisateur #{user.id} avec le type #{product_name}"
    end
  end
end
