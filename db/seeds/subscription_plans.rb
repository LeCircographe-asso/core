# Seed des formules de cotisation (vocabulaire cible : ContributionFormula).
# Le code actuel utilise encore le modèle SubscriptionPlan (rename planifié — voir docs/migrations/vocabulary_migration.md).
puts "\nChargement des formules de cotisation (ContributionFormula — code actuel : SubscriptionPlan)..."

# Récupérer l'admin pour l'audit
admin_user = User.find_by(system_role: "super_admin")

subscription_plans = [
  {
    name: "Journée",
    duration: "day",
    price_cents: 400, # 4€
    description: "Accès pour une journée complète",
    membership_type: MembershipType.find_by(category: "circus"),
    sessions_count: nil,
    validity_days: 1,
    version: 1,
    effective_from: Date.current,
    effective_until: nil,
    created_by_user: admin_user,
    change_reason: "Données initiales - Version 1"
  },
  {
    name: "Trimestriel",
    duration: "trimester",
    price_cents: 6000, # 60€
    description: "Accès pour un trimestre (3 mois)",
    membership_type: MembershipType.find_by(category: "circus"),
    sessions_count: nil,
    validity_days: 90,
    version: 1,
    effective_from: Date.current,
    effective_until: nil,
    created_by_user: admin_user,
    change_reason: "Données initiales - Version 1"
  },
  {
    name: "Annuel",
    duration: "annual",
    price_cents: 12000, # 120€
    description: "Accès pour une année complète",
    membership_type: MembershipType.find_by(category: "circus"),
    sessions_count: nil,
    validity_days: 365,
    version: 1,
    effective_from: Date.current,
    effective_until: nil,
    created_by_user: admin_user,
    change_reason: "Données initiales - Version 1"
  },
  {
    name: "Carnet de 10",
    duration: "pack10",
    price_cents: 3000, # 30€
    description: "10 séances valables 1 an",
    membership_type: MembershipType.find_by(category: "circus"),
    sessions_count: 10,
    validity_days: 365,
    version: 1,
    effective_from: Date.current,
    effective_until: nil,
    created_by_user: admin_user,
    change_reason: "Données initiales - Version 1"
  }
]

subscription_plans.each do |attrs|
  formula = SubscriptionPlan.create!(attrs)
  puts "  - #{formula.name} (#{formula.price_euros}€) — #{formula.membership_type.name} — version #{formula.version}"
end

puts "  #{SubscriptionPlan.count} formules de cotisation créées."
