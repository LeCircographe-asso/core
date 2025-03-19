class PriceEntry < ApplicationRecord
  belongs_to :product
  belongs_to :price_catalog
end
