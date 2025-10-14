# Seeds pour le nouveau modèle Person-Based Architecture
puts "🎪 Le Circographe - Person-Based Architecture Seeds"
puts "=" * 60
# Le Circographe ASCII Art Logo
puts %(
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣤⡶⠿⠿⠷⣶⣄⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⡿⠁⠀⠀⢀⣀⡀⠙⣷⡀⠀⠀⠀
⠀⠀⠀⡀⠀⠀⠀⠀⠀⢠⣿⠁⠀⠀⠀⠘⠿⠃⠀⢸⣿⣿⣿⣿
⠀⣠⡿⠛⢷⣦⡀⠀⠀⠈⣿⡄⠀⠀⠀⠀⠀⠀⠀⣸⣿⣿⣿⠟
⢰⡿⠁⠀⠀⠙⢿⣦⣤⣤⣼⣿⣄⠀⠀⠀⠀⠀⢴⡟⠛⠋⠁⠀
⣿⠇⠀⠀⠀⠀⠀⠉⠉⠉⠉⠉⠁⠀⠀⠀⠀⠀⠈⣿⡀⠀⠀⠀
⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢹⡇⠀⠀⠀
⣿⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⡇⠀⠀⠀
⠸⣷⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⡿⠀⠀⠀⠀
⠀⠹⣷⣤⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣰⡿⠁⠀⠀⠀⠀
⠀⠀⠀⠉⠙⠛⠿⠶⣶⣶⣶⣶⣶⠶⠿⠟⠛⠉⠀⠀⠀⠀⠀⠀
)
puts "\n🎪 Bienvenue dans la seed du Circographe! 🎪\n\n"
# Nettoyage des données existantes (optionnel)
if ENV['CLEAN'] == 'true'
  puts "\n🧹 Cleaning existing data..."
  [ Person, User, Membership, MembershipType, SubscriptionPlan,
   Payment, PaymentLine, BookOfEntry, Attendance, Event ].each do |model|
    count = model.count
    model.delete_all if count > 0
    puts "  - Deleted #{count} #{model.name.pluralize.downcase}"
  end
end

# Charger les seeds modulaires
puts "\n📋 Loading modular seeds..."

# 1. Types d'adhésion
load Rails.root.join('db', 'seeds', 'membership_types.rb')

# 2. Plans d'abonnement
load Rails.root.join('db', 'seeds', 'subscription_plans.rb')

# 3. Événements
load Rails.root.join('db', 'seeds', 'events.rb')

# 4. Personnes de test
load Rails.root.join('db', 'seeds', 'people.rb')

puts "\n🎉 Seeds completed successfully!"
puts "=" * 60
puts "📊 Summary:"
puts "  - #{MembershipType.count} membership types"
puts "  - #{SubscriptionPlan.count} subscription plans"
puts "  - #{Event.count} events"
puts "  - #{Person.count} people"
puts "  - #{User.count} users (with person accounts)"
puts "  - #{Membership.count} memberships"
puts "  - #{BookOfEntry.count} book of entries"
puts "  - #{Attendance.count} attendances"
puts "=" * 60

puts "\n🔑 Test accounts created:"
Person.joins(:user).each do |person|
  puts "  - #{person.full_name}: #{person.email} / password123"
end

puts "\n✨ Ready to test the Person-Based Architecture!"
