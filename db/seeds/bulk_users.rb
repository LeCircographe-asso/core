# Seed volume opt-in — non inclus dans le run par défaut (SEED_STEPS).
# Utilisation : SEED_BULK_USERS_COUNT=N rails db:seed  ou  load Rails.root.join("db/seeds/bulk_users.rb")
BULK_USERS_COUNT = ENV.fetch("SEED_BULK_USERS_COUNT", "0").to_i.clamp(0, 10_000)

if BULK_USERS_COUNT.positive?
  puts "\n🎭 Creating #{BULK_USERS_COUNT} additional users for testing..."
else
  puts "\n  [bulk] Aucun utilisateur volumique (#{fast_seed ? 'SEED_FAST_TEST' : 'SEED_BULK_USERS_COUNT=0'})."
end

# S'assurer que les helpers sont disponibles (si ce fichier est exécuté isolément)
SEED_DEFAULT_PASSWORD ||= "password123"

unless defined?(seed_register_person)
  def seed_register_person(person_attributes, create_user: false, user_role: "web_visitor", created_by_admin: true)
    attrs = person_attributes.dup
    newsletter_flag = attrs.delete(:newsletter_subscribed)

    result = People::Register.new(
      person_params: attrs,
      newsletter_subscribed: newsletter_flag,
      newsletter_source: created_by_admin ? "admin" : "web",
      create_user_account: create_user,
      user_params: create_user ? {
        email_address: attrs[:email],
        password: SEED_DEFAULT_PASSWORD,
        system_role: user_role,
        created_by_admin: created_by_admin,
        cgu: true,
        privacy_policy: true
      } : {},
      create_membership: false
    ).call

    raise "Seed error: #{result.message}" unless result.success?

    result.person
  end
end

unless defined?(seed_assign_membership)
  def seed_assign_membership(person, membership_type, recorded_by_id:, started_at:, ended_at:, first_joined_at:, status: :active)
    return unless membership_type

    result = People::MembershipCreator.new(
      person: person,
      membership_type_id: membership_type.id,
      payment_method: "cash",
      recorded_by_id: recorded_by_id
    ).call

    raise "Seed error: #{result.message}" unless result.success?

    membership = result.membership
    membership.update!(
      started_at: started_at,
      ended_at: ended_at,
      first_joined_at: first_joined_at,
      status: status
    )
  end
end

# Récupérer les types d'adhésion
basic_membership = MembershipType.find_by(category: "basic")
# Récupérer tous les types Circus (maintenant category = "circus", différenciés par nom/prix)
circus_types = MembershipType.where(category: "circus").order(price_cents: :desc)
circus_full_membership = circus_types.first  # Le plus cher (Tarif Plein)
circus_reduced_membership = circus_types.last # Le moins cher (Tarif Réduit)

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

# Helper pour normaliser les identifiants (supprime accents/espaces)
def normalize_token(value)
  ActiveSupport::Inflector.transliterate(value.to_s).downcase.gsub(/[^a-z0-9]+/, '-')
end

def build_email(first_name, last_name, index)
  base_first = normalize_token(first_name)
  base_last = normalize_token(last_name)
  "#{base_first}.#{base_last}.#{index}@example.com"
end

# Créer les utilisateurs supplémentaires
BULK_USERS_COUNT.times do |i|
  first_name = first_names[i % first_names.length]
  last_name = last_names[i % last_names.length]
  city = cities[i % cities.length]

  # Générer un email unique
  email = build_email(first_name, last_name, i + 1)

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

  puts "\n  👤 Creating #{first_name} #{last_name} (#{i + 1}/#{BULK_USERS_COUNT}) - #{creation_type} - #{membership_type&.category || 'no membership'}..."

  person = seed_register_person(
    {
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
    },
    create_user: (creation_type == "user") || system_role == "volunteer",
    user_role: system_role,
    created_by_admin: creation_type != "user"
  )

  if membership_type
    started_at = rand(1..12).months.ago
    seed_assign_membership(
      person,
      membership_type,
      recorded_by_id: case creation_type
                      when "admin" then admin_user&.id
                      when "volunteer" then volunteer_user&.id
                      else admin_user&.id
                      end,
      started_at: started_at,
      ended_at: started_at + 1.year,
      first_joined_at: rand(1..24).months.ago,
      status: [ :active, :expired, :pending ].sample
    )
  end

  if person.user.present?
    puts "    ✅ #{person.full_name}: #{person.user.system_role} account created"
  else
    puts "    ✅ #{person.full_name}: Person only (no user account)"
  end
end

if BULK_USERS_COUNT.positive?
  puts "\n🎉 #{BULK_USERS_COUNT} additional users created successfully!"
else
  puts "\n  Bulk : rien à créer (0)."
end
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
