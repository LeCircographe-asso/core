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
end
