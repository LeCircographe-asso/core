# Seeds pour les produits (compatibilité avec l'ancien système)
puts "🛍️ Creating products for compatibility..."

# Créer les produits d'adhésion
membership_products = [
  {
    product_name: "Adhésion Basique",
    product_type: "adhesion",
    price: 15.0
  },
  {
    product_name: "Adhésion Cirque Complète",
    product_type: "adhesion", 
    price: 25.0
  },
  {
    product_name: "Adhésion Cirque Réduite",
    product_type: "adhesion",
    price: 20.0
  }
]

# Créer les produits de cotisation
subscription_products = [
  {
    product_name: "Cotisation Journée",
    product_type: "cotisation",
    price: 8.0
  },
  {
    product_name: "Cotisation Trimestre",
    product_type: "cotisation",
    price: 60.0
  },
  {
    product_name: "Cotisation Annuelle",
    product_type: "cotisation",
    price: 200.0
  },
  {
    product_name: "Cotisation Pack 10 séances",
    product_type: "cotisation",
    price: 70.0
  }
]

# Créer les produits d'adhésion
membership_products.each do |product_attrs|
  product = Product.find_or_create_by(product_name: product_attrs[:product_name]) do |p|
    p.product_type = product_attrs[:product_type]
  end
  
  # Créer une entrée de prix si elle n'existe pas
  unless product.price_entries.any?
    price_catalog = PriceCatalog.create!(price: product_attrs[:price])
    PriceEntry.create!(product: product, price_catalog: price_catalog)
  end
  
  puts "  ✅ #{product.product_name} (#{product_attrs[:price]}€)"
end

# Créer les produits de cotisation
subscription_products.each do |product_attrs|
  product = Product.find_or_create_by(product_name: product_attrs[:product_name]) do |p|
    p.product_type = product_attrs[:product_type]
  end
  
  # Créer une entrée de prix si elle n'existe pas
  unless product.price_entries.any?
    price_catalog = PriceCatalog.create!(price: product_attrs[:price])
    PriceEntry.create!(product: product, price_catalog: price_catalog)
  end
  
  puts "  ✅ #{product.product_name} (#{product_attrs[:price]}€)"
end

puts "🎉 Created #{Product.count} products for compatibility"
