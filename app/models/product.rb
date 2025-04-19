class Product < ApplicationRecord
  has_many :book_of_entries
  has_many :price_entries
  has_many :price_catalogs, through: :price_entries
  has_many :product_orders
  has_many :orders, through: :product_orders

  after_create :productValidation

  def current_price
    prices.order("price_entries.created_at DESC").first
  end

  def display_name
    case product_type
    when "adhesion"
      product_name.gsub(/^Adhésion\s+/, "")
    when "cotisation"
      product_name.gsub(/^Cotisation\s+/, "")
    else
      product_name
    end
  end

  def category_name
    case product_type
    when "adhesion"
      "Adhésion"
    when "cotisation"
      "Cotisation"
    else
      product_type.to_s.capitalize
    end
  end

  def productValidation
    if self.product_name.blank?
      Rails.logger.error("Le produit #{self.id} n'a pas de nom.")
    end
  end
end
