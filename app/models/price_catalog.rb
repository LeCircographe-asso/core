class PriceCatalog < ApplicationRecord
  has_many :price_entries

  after_create :priceValidation

  def priceValidation
    if self.price <= 0
      Rails.logger.error("Vous devez ajouter un prix.")
    end
  end
end
