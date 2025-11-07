namespace :db do
  desc "Create subscription plans"
  task create_subscription_plans: :environment do
    puts "🎫 Creating subscription plans..."

    # Récupérer les types d'adhésion Circus (maintenant category = circus, différenciés par nom/prix)
    circus_types = MembershipType.where(category: :circus).order(price_cents: :desc)
    circus_full_type = circus_types.first  # Le plus cher (Tarif Plein)
    circus_reduced_type = circus_types.last # Le moins cher (Tarif Réduit)

    if circus_full_type.nil? || circus_reduced_type.nil?
      puts "❌ Membership types not found. Please run rails db:seed first."
      exit 1
    end

    subscription_plans = [
      {
        name: "Pack 10 séances - Cirque Complète",
        duration: :pack10,
        price_cents: 7000, # 70€
        description: "10 séances valables 1 an",
        membership_type: circus_full_type,
        sessions_count: 10,
        validity_days: 365
      },
      {
        name: "Pack 10 séances - Cirque Réduite",
        duration: :pack10,
        price_cents: 6000, # 60€
        description: "10 séances valables 1 an (tarif réduit)",
        membership_type: circus_reduced_type,
        sessions_count: 10,
        validity_days: 365
      },
      {
        name: "Pack 5 séances - Cirque Complète",
        duration: :pack10,
        price_cents: 4000, # 40€
        description: "5 séances valables 6 mois",
        membership_type: circus_full_type,
        sessions_count: 5,
        validity_days: 180
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

      puts "  ✅ #{subscription_plan.name} (#{subscription_plan.price_euros}€)"
    end

    puts "🎉 Created #{SubscriptionPlan.count} subscription plans"
  end
end
