# Seed pour des Person de test avec différents types de création
puts "\n👥 Creating sample people..."

# Helpers
SEED_DEFAULT_PASSWORD = "password123".freeze

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

# Récupérer les types d'adhésion
basic_membership = MembershipType.find_by(category: "basic")
circus_types = MembershipType.where(category: "circus").order(price_cents: :desc)
circus_full_membership = circus_types.first
circus_reduced_membership = circus_types.last

# Récupérer les comptes système
admin_user = User.find_by(system_role: "admin")
volunteer_user = User.find_by(system_role: "volunteer")

puts "\n📋 PARTIE 1: 3 personnes créées par admin/volunteer..."

puts "\n  🎭 Creating Alice (created by admin)..."
alice = seed_register_person(
  {
    first_name: "Alice",
    last_name: "Cirque",
    email: "alice.cirque@example.com",
    phone: "+33 6 12 34 56 78",
    address: "15 Rue de la Jongle",
    zip_code: "75012",
    town: "Paris",
    country: "France",
    birth_date: Date.new(1995, 3, 15),
    newsletter_subscribed: true,
    get_involved: true,
    image_rights: true,
    is_minor: false,
    notes: "Créée par admin"
  }
)

seed_assign_membership(
  alice,
  basic_membership,
  recorded_by_id: admin_user&.id,
  started_at: 3.months.ago,
  ended_at: 3.months.ago + 1.year,
  first_joined_at: 3.months.ago
)
puts "    ✅ #{alice.full_name}: Créée par #{admin_user&.person&.full_name || 'admin seed'}"

puts "\n  🎪 Creating Bob (created by volunteer)..."
bob = seed_register_person(
  {
    first_name: "Bob",
    last_name: "Basique",
    email: "bob.basique@example.com",
    phone: "+33 6 23 45 67 89",
    address: "42 Avenue du Spectacle",
    zip_code: "75013",
    town: "Paris",
    country: "France",
    birth_date: Date.new(1988, 7, 22),
    newsletter_subscribed: false,
    get_involved: false,
    image_rights: true,
    is_minor: false,
    notes: "Créée par volunteer"
  }
)

seed_assign_membership(
  bob,
  circus_full_membership,
  recorded_by_id: volunteer_user&.id,
  started_at: 1.month.ago,
  ended_at: 1.month.ago + 1.year,
  first_joined_at: 1.month.ago
)
puts "    ✅ #{bob.full_name}: Créé par #{volunteer_user&.person&.full_name || 'volunteer seed'}"

puts "\n  🎨 Creating Charlie (created by admin)..."
charlie = seed_register_person(
  {
    first_name: "Charlie",
    last_name: "Étudiant",
    email: "charlie.etudiant@example.com",
    phone: "+33 6 34 56 78 90",
    address: "8 Rue de l'Équilibre",
    zip_code: "75014",
    town: "Paris",
    country: "France",
    birth_date: Date.new(2000, 11, 8),
    newsletter_subscribed: true,
    get_involved: true,
    image_rights: false,
    is_minor: false,
    notes: "Créée par admin"
  }
)

seed_assign_membership(
  charlie,
  circus_reduced_membership,
  recorded_by_id: admin_user&.id,
  started_at: 2.weeks.ago,
  ended_at: 2.weeks.ago + 1.year,
  first_joined_at: 2.weeks.ago
)
puts "    ✅ #{charlie.full_name}: Créé par #{admin_user&.person&.full_name || 'admin seed'}"

puts "\n🌐 PARTIE 2: 3 comptes web créés par les utilisateurs eux-mêmes..."

puts "\n  👤 Creating Diana (web account created by user)..."
diana_person = seed_register_person(
  {
    first_name: "Diana",
    last_name: "Prospect",
    email: "diana.prospect@example.com",
    phone: "+33 6 45 67 89 01",
    address: "25 Boulevard du Trapèze",
    zip_code: "75015",
    town: "Paris",
    country: "France",
    birth_date: Date.new(1992, 5, 30),
    newsletter_subscribed: true,
    get_involved: false,
    image_rights: true,
    is_minor: false,
    notes: "Créée par l'utilisateur lui-même"
  },
  create_user: true,
  created_by_admin: false
)
puts "    ✅ #{diana_person.full_name}: Compte web créé par l'utilisateur"

puts "\n  🎪 Creating Emma (web account created by user)..."
emma_person = seed_register_person(
  {
    first_name: "Emma",
    last_name: "Complexe",
    email: "emma.complexe@example.com",
    phone: "+33 6 56 78 90 12",
    address: "33 Rue de l'Acrobatie",
    zip_code: "75016",
    town: "Paris",
    country: "France",
    birth_date: Date.new(1985, 9, 12),
    newsletter_subscribed: true,
    get_involved: true,
    image_rights: true,
    is_minor: false,
    notes: "Créée par l'utilisateur lui-même"
  },
  create_user: true,
  created_by_admin: false
)

seed_assign_membership(
  emma_person,
  basic_membership,
  recorded_by_id: admin_user&.id,
  started_at: Date.current,
  ended_at: 1.year.from_now,
  first_joined_at: Date.current
)
puts "    ✅ #{emma_person.full_name}: Compte web créé par l'utilisateur"

puts "\n  🎨 Creating Frank (web account created by user)..."
frank_person = seed_register_person(
  {
    first_name: "Frank",
    last_name: "Newcomer",
    email: "frank.newcomer@example.com",
    phone: "+33 6 67 89 01 23",
    address: "17 Rue de la Clown",
    zip_code: "75017",
    town: "Paris",
    country: "France",
    birth_date: Date.new(1998, 12, 3),
    newsletter_subscribed: false,
    get_involved: true,
    image_rights: true,
    is_minor: false,
    notes: "Créée par l'utilisateur lui-même"
  },
  create_user: true,
  created_by_admin: false
)
puts "    ✅ #{frank_person.full_name}: Compte web créé par l'utilisateur"

puts "\n🎉 Sample people created successfully!"
puts "📊 Summary:"
puts "  - #{Person.count} personnes total"
puts "  - #{User.count} utilisateurs total"
puts "  - #{Person.where("notes LIKE ?", "%admin%").count} personnes créées par admin"
puts "  - #{Person.where("notes LIKE ?", "%volunteer%").count} personnes créées par volunteer"
puts "  - #{Person.where("notes LIKE ?", "%utilisateur%").count} personnes créées par les utilisateurs eux-mêmes"
puts "  - #{User.where(created_by_admin: true).count} comptes créés par admin"
puts "  - #{User.where(created_by_admin: false).count} comptes créés par les utilisateurs"
