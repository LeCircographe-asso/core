# Seeds pour le nouveau modèle Person-Based Architecture avec Articles
puts "🎪 Le Circographe - Nouveau Modèle d'Articles"
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

# Nettoyage des données existantes
puts "🧹 Cleaning existing data..."
[ Person, User, Membership, MembershipType, SubscriptionPlan,
 Payment, PaymentLine, BookOfEntry, Attendance, Event ].each do |model|
  count = model.count
  model.delete_all if count > 0
  puts "  - Deleted #{count} #{model.name.pluralize.downcase}"
end

# Charger les seeds modulaires
puts "\n📋 Loading modular seeds..."

# 0. Super administrateur
load Rails.root.join('db', 'seeds', 'admin.rb')

# 1. Types d'adhésion (Articles d'adhésion)
load Rails.root.join('db', 'seeds', 'membership_types.rb')

# 2. Plans d'abonnement (Articles de cotisation)
load Rails.root.join('db', 'seeds', 'subscription_plans.rb')

# 3. Événements
load Rails.root.join('db', 'seeds', 'events.rb')

# 4. Personnes de test avec numéros d'adhérent et historiques
load Rails.root.join('db', 'seeds', 'sample_people.rb')

puts "\n🎉 Seeds completed successfully!"
puts "=" * 60
puts "📊 Summary:"
puts "  - #{MembershipType.count} types d'adhésion (articles d'adhésion)"
puts "  - #{SubscriptionPlan.count} plans d'abonnement (articles de cotisation)"
puts "  - #{Event.count} événements"
puts "  - #{Person.count} personnes"
puts "  - #{User.count} utilisateurs"
puts "  - #{Membership.count} adhésions"
puts "  - #{BookOfEntry.count} carnets d'entrées"
puts "  - #{Payment.count} paiements"
puts "=" * 60

puts "\n🔑 Compte de test:"
puts "  👑 Super Admin: admin@rails.com / 123456"

puts "\n📈 Articles disponibles:"
puts "  📋 Adhésions:"
MembershipType.all.each do |mt|
  puts "    - #{mt.name}: #{mt.price_euros}€ (#{mt.category})"
end

puts "  🎫 Cotisations:"
SubscriptionPlan.all.each do |sp|
  puts "    - #{sp.name}: #{sp.price_euros}€ (#{sp.duration})"
end

puts "\n👥 Personnes avec numéros d'adhérent:"
Person.where.not(member_number: nil).each do |person|
  history_count = person.member_number_history.count
  web_account = person.user.present? ? "🌐" : "📱"
  puts "    #{web_account} #{person.full_name}: #{person.member_number} (#{history_count} historique(s))"
end

puts "\n📊 Statistiques des numéros d'adhérent:"
current_year = Date.current.year.to_s.last(2)
basique_count = Person.where("member_number LIKE ?", "#{current_year}U%").count
cirque_count = Person.where("member_number LIKE ?", "#{current_year}C%").count
puts "    - Basique (#{current_year}U): #{basique_count} adhérent(s)"
puts "    - Cirque (#{current_year}C): #{cirque_count} adhérent(s)"
puts "    - Total avec numéro: #{Person.where.not(member_number: nil).count}"
puts "    - Sans numéro: #{Person.where(member_number: nil).count}"

puts "\n✨ Système d'articles et numéros d'adhérent prêt à l'emploi!"