# Seeds pour les plans d'abonnement
puts "🎫 Creating subscription plans..."

# Récupérer les types d'adhésion
basic_type = MembershipType.find_by(category: :basic)
circus_full_type = MembershipType.find_by(category: :circus_full)
circus_reduced_type = MembershipType.find_by(category: :circus_reduced)

subscription_plans = [
  {
    name: "Journée",
    duration: :day,
    price_cents: 800, # 8€
    description: "Accès pour une journée",
    membership_type: basic_type,
    sessions_count: nil,
    validity_days: nil
  },
  {
    name: "Trimestre",
    duration: :trimester,
    price_cents: 6000, # 60€
    description: "Accès pour un trimestre",
    membership_type: circus_full_type,
    sessions_count: nil,
    validity_days: nil
  },
  {
    name: "Annuel",
    duration: :annual,
    price_cents: 20000, # 200€
    description: "Accès pour une année complète",
    membership_type: circus_full_type,
    sessions_count: nil,
    validity_days: nil
  },
  {
    name: "Pack 10 séances",
    duration: :pack10,
    price_cents: 7000, # 70€
    description: "Pack de 10 séances valables 1 an",
    membership_type: circus_full_type,
    sessions_count: 10,
    validity_days: 365
  }
]

subscription_plans.each do |attrs|
  subscription_plan = SubscriptionPlan.find_or_create_by(name: attrs[:name]) do |sp|
    sp.duration = attrs[:duration]
    sp.price_cents = attrs[:price_cents]
    sp.description = attrs[:description]
    sp.membership_type = attrs[:membership_type]
    sp.sessions_count = attrs[:sessions_count]
    sp.validity_days = attrs[:validity_days]
  end
  
  puts "  ✅ #{subscription_plan.name} (#{subscription_plan.price_euros}€) - #{subscription_plan.membership_type.name}"
end

puts "🎉 Created #{SubscriptionPlan.count} subscription plans"
