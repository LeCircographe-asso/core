# Seed des types d'adhésion (catalogue MembershipType).
# Voir docs/glossary.md pour le vocabulaire canonique.
puts "\nChargement des types d'adhésion (MembershipType)..."

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
    name: "Adhésion Cirque Tarif Plein",
    category: "circus",
    price_cents: 1000, # 10€
    description: "Accès complet aux cours de cirque - tarif normal pour adultes",
    version: 1,
    effective_from: Date.current,
    effective_until: nil,
    created_by_user: admin_user,
    change_reason: "Données initiales - Version 1"
  },
  {
    name: "Adhésion Cirque Tarif Réduit",
    category: "circus",
    price_cents: 700, # 7€
    description: "Accès complet aux cours de cirque - tarif réduit (Porteur de Handicap, RSA, Mineur, Etudiant)",
    version: 1,
    effective_from: Date.current,
    effective_until: nil,
    created_by_user: admin_user,
    change_reason: "Données initiales - Version 1"
  }
]

membership_types.each do |attrs|
  membership_type = MembershipType.create!(attrs)
  puts "  - #{membership_type.name} (#{membership_type.price_euros}€) — version #{membership_type.version}"
end

puts "  #{MembershipType.count} types d'adhésion créés."
