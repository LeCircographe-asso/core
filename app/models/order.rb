class Order < ApplicationRecord
  belongs_to :product_order, optional: true
  has_many :product_orders
end
