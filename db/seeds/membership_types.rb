# Seeds pour les types d'adhésion
puts "🌱 Creating membership types..."

membership_types = [
  {
    name: "Adhésion Basique",
    category: :basic,
    price_cents: 1500, # 15€
    description: "Adhésion de base permettant l'accès aux activités générales"
  },
  {
    name: "Adhésion Cirque Complète",
    category: :circus_full,
    price_cents: 2500, # 25€
    description: "Adhésion complète pour toutes les activités circassiennes"
  },
  {
    name: "Adhésion Cirque Réduite",
    category: :circus_reduced,
    price_cents: 2000, # 20€
    description: "Adhésion réduite pour les activités circassiennes (étudiants, chômeurs, etc.)"
  }
]

membership_types.each do |attrs|
  membership_type = MembershipType.find_or_create_by(name: attrs[:name]) do |mt|
    mt.category = attrs[:category]
    mt.price_cents = attrs[:price_cents]
    mt.description = attrs[:description]
  end
  
  puts "  ✅ #{membership_type.name} (#{membership_type.price_euros}€)"
end

puts "🎉 Created #{MembershipType.count} membership types"
