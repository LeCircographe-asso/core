# Seeds — architecture Person-Based.
# Vocabulaire canonique : Person / User / Membership / MembershipType /
# Contribution / ContributionFormula
# Voir docs/glossary.md pour le lexique complet.
puts "Le Circographe — chargement des seeds"
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
puts "\nLe Circographe — initialisation des données de référence\n\n"

# Nettoyage des données existantes (dans l'ordre des dépendances)
puts "Nettoyage des données existantes..."
[ PaymentLine, Payment, Attendance, Contribution, Membership,
  Event, ContributionFormula, MembershipType, User, Person ].each do |model|
  count = model.count
  model.delete_all if count > 0
  puts "  - #{count} #{model.name.pluralize.downcase} supprimé(s)"
end

# Chargement des seeds modulaires
puts "\nChargement des seeds modulaires..."

# 0. Super administrateur
load Rails.root.join('db', 'seeds', 'admin.rb')

# 1. Types d'adhésion (catalogue MembershipType)
load Rails.root.join('db', 'seeds', 'membership_types.rb')

# 2. Formules de cotisation (catalogue ContributionFormula)
load Rails.root.join('db', 'seeds', 'contribution_formulas.rb')

# 3. Événements
load Rails.root.join('db', 'seeds', 'events.rb')

# 4. Personnes de test avec numéros d'adhérent et historiques
load Rails.root.join('db', 'seeds', 'sample_people.rb')

# 5. Création de 75 utilisateurs supplémentaires pour les tests
load Rails.root.join('db', 'seeds', 'bulk_users.rb')

# 6. Ajouter des adhésions et paiements avec la nouvelle logique
load Rails.root.join('db', 'seeds', 'add_memberships_and_payments.rb')

puts "\nSeeds terminés."
puts "=" * 60
puts "Récapitulatif :"
puts "  - #{MembershipType.count} types d'adhésion"
puts "  - #{ContributionFormula.count} formules de cotisation"
puts "  - #{Event.count} événements"
puts "  - #{Person.count} personnes"
puts "  - #{User.count} comptes web"
puts "  - #{Membership.count} adhésions"
puts "  - #{Contribution.count} cotisations"
puts "  - #{Payment.count} paiements"
puts "=" * 60

puts "\nComptes de test :"
puts "  - Super Admin : super-admin@rails.com / 123456"
puts "  - Admin       : admin@rails.com / 123456"
puts "  - Volunteer   : volunteer@rails.com / 123456"

puts "\nCatalogue disponible :"
puts "  Types d'adhésion :"
MembershipType.all.each do |mt|
  puts "    - #{mt.name} : #{mt.price_euros}€ (#{mt.category})"
end

puts "  Formules de cotisation :"
ContributionFormula.all.each do |sp|
  puts "    - #{sp.name} : #{sp.price_euros}€ (#{sp.duration})"
end

puts "\nPersonnes avec numéro d'adhérent :"
Person.where.not(member_number: nil).each do |person|
  history_count = person.member_number_history.count
  web_account = person.user.present? ? "[web]" : "[no-web]"
  puts "    #{web_account} #{person.full_name} : #{person.member_number} (#{history_count} historique(s))"
end

puts "\nStatistiques des numéros d'adhérent :"
current_year = Date.current.year.to_s.last(2)
basique_count = Person.where("member_number LIKE ?", "#{current_year}U%").count
cirque_count = Person.where("member_number LIKE ?", "#{current_year}C%").count
puts "    - Basic  (#{current_year}U) : #{basique_count} adhérent(s)"
puts "    - Cirque (#{current_year}C) : #{cirque_count} adhérent(s)"
puts "    - Total avec numéro : #{Person.where.not(member_number: nil).count}"
puts "    - Sans numéro       : #{Person.where(member_number: nil).count}"

puts "\nCatalogue d'adhésions et de cotisations prêt à l'emploi."
