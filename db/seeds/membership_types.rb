# Seed pour les types d'adhésion (Articles d'adhésion)
puts "\n🌱 Creating membership types (Articles d'adhésion)..."

# Récupérer l'admin pour l'audit
admin_user = User.find_by(system_role: "super_admin")

membership_types = [
  {
    name: "Adhésion Basique",
    category: "basic",
    price_cents: 100, # 1€
    description: "Accès de base à l'association - participation aux événements et activités générales",
    version: 1,
    effective_from: Date.current,
    effective_until: nil,
    created_by_user: admin_user,
    change_reason: "Données initiales - Version 1"
  },
  {
    name: "Adhésion Cirque Complète",
    category: "circus_full",
    price_cents: 1000, # 10€
    description: "Accès complet aux cours de cirque - tarif normal pour adultes",
    version: 1,
    effective_from: Date.current,
    effective_until: nil,
    created_by_user: admin_user,
    change_reason: "Données initiales - Version 1"
  },
  {
    name: "Adhésion Cirque Réduite",
    category: "circus_reduced",
    price_cents: 800, # 8€
    description: "Accès complet aux cours de cirque - tarif réduit (étudiants, chômeurs, etc.)",
    version: 1,
    effective_from: Date.current,
    effective_until: nil,
    created_by_user: admin_user,
    change_reason: "Données initiales - Version 1"
  }
]

membership_types.each do |attrs|
  membership_type = MembershipType.create!(attrs)
  puts "  ✅ #{membership_type.name} (#{membership_type.price_euros}€) - Version #{membership_type.version}"
end

puts "🎉 Created #{MembershipType.count} membership types"
