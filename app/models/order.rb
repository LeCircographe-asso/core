class Order < ApplicationRecord
  belongs_to :product_order, optional: true
  belongs_to :user
  has_many :product_orders
  validates :user_id

  after_create :sumValidation

  private

  def sumValidation
    if self.sum <= 0
      Rails.logger.error("Le panier #{self.id} est vide !")
    end
  end
end
