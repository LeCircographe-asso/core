namespace :db do
  desc "Update membership and subscription prices according to current specifications"
  task update_prices: :environment do
    puts "💰 Updating prices according to current specifications..."
    
    # 1. Mettre à jour les adhésions (MembershipType)
    puts "\n📋 Updating membership types..."
    
    # Adhésion Basique : 1€
    basic_type = MembershipType.find_by(category: :basic)
    if basic_type
      basic_type.update!(price_cents: 100) # 1€
      puts "  ✅ #{basic_type.name}: #{basic_type.price_euros}€"
    else
      puts "  ❌ Basic membership type not found"
    end
    
    # Adhésion Cirque : types multiples maintenant (category = circus, différenciés par nom/prix)
    circus_types = MembershipType.where(category: :circus).order(price_cents: :desc)
    
    # Tarif Plein (le plus cher)
    circus_full_type = circus_types.first
    if circus_full_type
      circus_full_type.update!(price_cents: 1000) # 10€
      puts "  ✅ #{circus_full_type.name}: #{circus_full_type.price_euros}€"
    else
      puts "  ❌ Circus full membership type not found"
    end
    
    # Tarif Réduit (le moins cher)
    circus_reduced_type = circus_types.last
    if circus_reduced_type
      circus_reduced_type.update!(price_cents: 800) # 8€ (réduit)
      puts "  ✅ #{circus_reduced_type.name}: #{circus_reduced_type.price_euros}€"
    else
      puts "  ❌ Circus reduced membership type not found"
    end
    
    # 2. Mettre à jour les cotisations (SubscriptionPlan)
    puts "\n🎫 Updating subscription plans..."
    
    # Supprimer les anciens plans (en gérant les contraintes)
    old_count = SubscriptionPlan.count
    if old_count > 0
      # Désactiver temporairement les contraintes de clés étrangères
      ActiveRecord::Base.connection.execute("PRAGMA foreign_keys=OFF")
      SubscriptionPlan.delete_all
      ActiveRecord::Base.connection.execute("PRAGMA foreign_keys=ON")
      puts "  🗑️ Deleted #{old_count} old subscription plans"
    end
    
    # Créer les nouveaux plans selon tes spécifications
    subscription_plans = [
      {
        name: "Journée",
        duration: :day,
        price_cents: 400, # 4€
        description: "Accès pour une journée",
        membership_type: circus_full_type,
        sessions_count: nil,
        validity_days: 1
      },
      {
        name: "Trimestriel",
        duration: :trimester,
        price_cents: 6000, # 60€
        description: "Accès pour un trimestre (3 mois)",
        membership_type: circus_full_type,
        sessions_count: nil,
        validity_days: 90
      },
      {
        name: "Annuel",
        duration: :annual,
        price_cents: 12000, # 120€
        description: "Accès pour une année complète",
        membership_type: circus_full_type,
        sessions_count: nil,
        validity_days: 365
      },
      {
        name: "Carnet de 10",
        duration: :pack10,
        price_cents: 3000, # 30€
        description: "10 séances valables 1 an",
        membership_type: circus_full_type,
        sessions_count: 10,
        validity_days: 365
      }
    ]
    
    subscription_plans.each do |attrs|
      subscription_plan = SubscriptionPlan.create!(attrs)
      puts "  ✅ #{subscription_plan.name}: #{subscription_plan.price_euros}€"
    end
    
    puts "\n🎉 Price update completed!"
    puts "=" * 50
    puts "📊 Summary:"
    puts "  - #{MembershipType.count} membership types updated"
    puts "  - #{SubscriptionPlan.count} subscription plans created"
    puts "=" * 50
  end
end
