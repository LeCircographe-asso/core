# Seed pour créer 75 utilisateurs supplémentaires pour les tests
puts "\n🎭 Creating 75 additional users for testing..."

# Récupérer les types d'adhésion
basic_membership = MembershipType.find_by(category: "basic")
circus_full_membership = MembershipType.find_by(category: "circus_full")
circus_reduced_membership = MembershipType.find_by(category: "circus_reduced")

# Récupérer les comptes système pour les créations par admin/volunteer
admin_user = User.find_by(system_role: "admin")
volunteer_user = User.find_by(system_role: "volunteer")

# Noms et prénoms variés pour créer des utilisateurs réalistes
first_names = [
  "Alexandre", "Marie", "Thomas", "Camille", "Julien", "Sophie", "Nicolas", "Julie",
  "Antoine", "Claire", "Pierre", "Émilie", "Maxime", "Léa", "Romain", "Chloé",
  "Baptiste", "Manon", "Hugo", "Emma", "Lucas", "Léa", "Gabriel", "Sarah",
  "Louis", "Océane", "Arthur", "Lola", "Ethan", "Inès", "Noah", "Zoé",
  "Liam", "Mia", "Léo", "Luna", "Raphaël", "Alice", "Paul", "Rose",
  "Gabin", "Anna", "Timéo", "Louise", "Nolan", "Jade", "Enzo", "Agathe",
  "Mael", "Léna", "Naël", "Lina", "Kylian", "Mila", "Axel", "Eva",
  "Léon", "Lya", "Eliott", "Nina", "Aaron", "Lila", "Adam", "Léonie",
  "Isaac", "Lily", "Noé", "Livia", "Malo", "Lise", "Eden", "Liv",
  "Luka", "Léane", "Milan", "Léana", "Liam", "Léa", "Gabriel", "Sarah"
]

last_names = [
  "Martin", "Bernard", "Thomas", "Petit", "Robert", "Richard", "Durand", "Dubois",
  "Moreau", "Laurent", "Simon", "Michel", "Lefebvre", "Leroy", "Roux", "David",
  "Bertrand", "Morel", "Simon", "Laurent", "Lefebvre", "Martin", "Bernard", "Thomas",
  "Petit", "Robert", "Richard", "Durand", "Dubois", "Moreau", "Laurent", "Simon",
  "Michel", "Lefebvre", "Leroy", "Roux", "David", "Bertrand", "Morel", "Simon",
  "Laurent", "Lefebvre", "Martin", "Bernard", "Thomas", "Petit", "Robert", "Richard",
  "Durand", "Dubois", "Moreau", "Laurent", "Simon", "Michel", "Lefebvre", "Leroy",
  "Roux", "David", "Bertrand", "Morel", "Simon", "Laurent", "Lefebvre", "Martin",
  "Bernard", "Thomas", "Petit", "Robert", "Richard", "Durand", "Dubois", "Moreau",
  "Laurent", "Simon", "Michel", "Lefebvre", "Leroy", "Roux", "David", "Bertrand"
]

# Villes françaises
cities = [
  "Paris", "Lyon", "Marseille", "Toulouse", "Nice", "Nantes", "Strasbourg", "Montpellier",
  "Bordeaux", "Lille", "Rennes", "Reims", "Le Havre", "Saint-Étienne", "Toulon", "Angers",
  "Grenoble", "Dijon", "Nîmes", "Aix-en-Provence", "Clermont-Ferrand", "Brest", "Limoges",
  "Tours", "Amiens", "Perpignan", "Metz", "Besançon", "Boulogne-Billancourt", "Orléans",
  "Mulhouse", "Rouen", "Caen", "Nancy", "Saint-Denis", "Argenteuil", "Montreuil", "Roubaix",
  "Tourcoing", "Nanterre", "Avignon", "Créteil", "Dunkirk", "Poitiers", "Asnières-sur-Seine",
  "Versailles", "Courbevoie", "Vitry-sur-Seine", "Colombes", "Aulnay-sous-Bois", "La Rochelle",
  "Rueil-Malmaison", "Antibes", "Saint-Maur-des-Fossés", "Champigny-sur-Marne", "Aubervilliers",
  "Cannes", "Béziers", "Bourges", "Colmar", "Drancy", "Mérignac", "Saint-Nazaire", "Issy-les-Moulineaux",
  "Noisy-le-Grand", "Évry", "Cergy", "Pessac", "Vénissieux", "Clichy", "Troyes", "Antony",
  "Montauban", "Neuilly-sur-Seine", "Levallois-Perret", "Sarcelles", "Niort", "Chambéry", "Lorient"
]

# Créer 75 utilisateurs supplémentaires
75.times do |i|
  first_name = first_names[i % first_names.length]
  last_name = last_names[i % last_names.length]
  city = cities[i % cities.length]

  # Générer un email unique
  email = "#{first_name.downcase}.#{last_name.downcase}.#{i+1}@example.com"

  # Déterminer le type de création (admin, volunteer, ou utilisateur)
  creation_type = case i % 3
  when 0
    "admin"
  when 1
    "volunteer"
  else
    "user"
  end

  # Déterminer le type d'adhésion
  membership_type = case i % 4
  when 0
    basic_membership
  when 1
    circus_full_membership
  when 2
    circus_reduced_membership
  else
    nil # Pas d'adhésion pour certains utilisateurs
  end

  # Déterminer le rôle système
  system_role = case i % 5
  when 0, 1, 2, 3
    "web_visitor"
  else
    "volunteer" # Quelques volontaires supplémentaires
  end

  puts "\n  👤 Creating #{first_name} #{last_name} (#{i+1}/75) - #{creation_type} - #{membership_type&.category || 'no membership'}..."

  # Créer la Person
  person = Person.create!(
    first_name: first_name,
    last_name: last_name,
    email: email,
    phone: "+33 6 #{rand(10..99)} #{rand(10..99)} #{rand(10..99)} #{rand(10..99)}",
    address: "#{rand(1..200)} Rue de #{[ 'la Paix', 'la République', 'Victor Hugo', 'Jean Jaurès', 'Gambetta', 'Clemenceau' ][rand(6)]}",
    zip_code: "#{rand(10000..99999)}",
    town: city,
    country: "France",
    birth_date: Date.new(rand(1980..2010), rand(1..12), rand(1..28)),
    newsletter_subscribed: [ true, false ].sample,
    get_involved: [ true, false ].sample,
    image_rights: [ true, false ].sample,
    is_minor: rand(1980..2010) > 2005,
    notes: "Créée par #{creation_type}"
  )

  # Créer l'adhésion si nécessaire
  if membership_type
    person.memberships.create!(
      membership_type: membership_type,
      started_at: rand(1..12).months.ago,
      ended_at: rand(1..12).months.ago + 1.year,
      status: [ :active, :expired, :pending ].sample,
      first_joined_at: rand(1..24).months.ago
    )
  end

  # Créer le User si c'est un compte web ou volontaire
  if creation_type == "user" || system_role == "volunteer"
    user = User.create!(
      person: person,
      email_address: email,
      password: "password123",
      password_confirmation: "password123",
      system_role: system_role,
      created_by_admin: creation_type != "user",
      cgu: true,
      privacy_policy: true
    )

    puts "    ✅ #{person.full_name}: #{system_role} account created"
  else
    puts "    ✅ #{person.full_name}: Person only (no user account)"
  end
end

puts "\n🎉 75 additional users created successfully!"
puts "📊 Updated Summary:"
puts "  - #{Person.count} personnes total"
puts "  - #{User.count} utilisateurs total"
puts "  - #{Person.where("notes LIKE ?", "%admin%").count} personnes créées par admin"
puts "  - #{Person.where("notes LIKE ?", "%volunteer%").count} personnes créées par volunteer"
puts "  - #{Person.where("notes LIKE ?", "%user%").count} personnes créées par les utilisateurs eux-mêmes"
puts "  - #{User.where(created_by_admin: true).count} comptes créés par admin"
puts "  - #{User.where(created_by_admin: false).count} comptes créés par les utilisateurs"
puts "  - #{Membership.count} adhésions total"
puts "  - #{Membership.where(status: :active).count} adhésions actives"
