class ProductOrder < ApplicationRecord
  belongs_to :product
  belongs_to :order


  after_create :productOrderValidation



  def productOrderValidation
    if self.order_id.blank? || self.product_id.blank?
      Rails.logger.error("Product Order #{self.id} empty !")
    end
  end
end
