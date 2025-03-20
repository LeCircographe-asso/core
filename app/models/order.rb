class Order < ApplicationRecord
  belongs_to :user
  has_many :product_orders
  validates :user_id, presence: true

  after_create :sumValidation



  def sumValidation
    if self.sum <= 0
      Rails.logger.error("Le panier #{self.id} est vide !")
    end
  end

after_update :update_user_membership_if_paid


def payment_successful?
  product_orders.any? { |po| po.payments.where(status: 'success').exists? }
end

def determine_user_membership
  product_names = product_orders.includes(:product).pluck('products.product_name')

  circus_products = [
    "Adhésion Cirque - Tarif Plein",
    "Upgrade Basic to Cirque - Tarif Plein",
    "Upgrade Basic to Cirque - Tarif Réduit",
    "Cotisation annuelle",
    "Cotisation trimestrielle",
    "Cotisation 10 séances",
    "Pass journée"
  ]

  return 2 if (product_names & circus_products).any?
  return 1 if product_names.include?("Adhésion simple")
  return nil if product_names.include?("Donation")


end

def update_user_membership_if_paid

  return unless payment_successful?

  # Déterminer quel type d'abonnement l'utilisateur doit avoir
  membership_type = determine_user_membership
  return unless membership_type

  # Si l'utilisateur n'a pas encore d'abonnement, on en crée un
  user_membership = user.user_memberships.last
  if user_membership.nil?
    user_membership = UserMembership.create!(user: user, membership_id: membership_type)
  end

  update_user_membership_end_date(user_membership) #Mise ajour de la end_date
end

def determine_end_date(product_name) #Determine la durée des adhesion
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
  product_name = product_orders.first.product.product_name
  end_date = determine_end_date(product_name)

  # Si une date est déterminée, on l'assigne à l'adhésion de l'utilisateur
  if end_date
    user_membership.end_date = end_date
    user_membership.save!
  end
end

end