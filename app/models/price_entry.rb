class PriceEntry < ApplicationRecord
  belongs_to :product
  belongs_to :price_catalog
  after_create :priceEntryValidation

  def priceEntryValidation
    if self.product_id.blank? || self.price_catalog_id.blank?
      Rails.logger.error("Price entry #{self.id}, data missing !")
    end
  end
end
