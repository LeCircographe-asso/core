# Seed pour des Person de test avec différents types de création
puts "\n👥 Creating sample people..."

# Récupérer les types d'adhésion
basic_membership = MembershipType.find_by(category: "basic")
circus_full_membership = MembershipType.find_by(category: "circus_full")
circus_reduced_membership = MembershipType.find_by(category: "circus_reduced")

# Récupérer les comptes système pour les créations par admin/volunteer
admin_user = User.find_by(system_role: "admin")
volunteer_user = User.find_by(system_role: "volunteer")

puts "\n📋 PARTIE 1: 3 personnes créées par admin/volunteer..."

# 1. Alice - Créée par Admin
puts "\n  🎭 Creating Alice (created by admin)..."
alice = Person.create!(
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
)

# Adhésion Basique pour Alice
alice_membership = alice.memberships.create!(
  membership_type: basic_membership,
  started_at: 3.months.ago,
  ended_at: 3.months.ago + 1.year,
  status: :active,
  first_joined_at: 3.months.ago
)

puts "    ✅ #{alice.full_name}: Créée par #{admin_user.person.full_name}"

# 2. Bob - Créé par Volunteer
puts "\n  🎪 Creating Bob (created by volunteer)..."
bob = Person.create!(
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
)

# Adhésion Cirque Complète pour Bob
bob_membership = bob.memberships.create!(
  membership_type: circus_full_membership,
  started_at: 1.month.ago,
  ended_at: 1.month.ago + 1.year,
  status: :active,
  first_joined_at: 1.month.ago
)

puts "    ✅ #{bob.full_name}: Créé par #{volunteer_user.person.full_name}"

# 3. Charlie - Créé par Admin
puts "\n  🎨 Creating Charlie (created by admin)..."
charlie = Person.create!(
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
)

# Adhésion Cirque Réduite pour Charlie
charlie_membership = charlie.memberships.create!(
  membership_type: circus_reduced_membership,
  started_at: 2.weeks.ago,
  ended_at: 2.weeks.ago + 1.year,
  status: :active,
  first_joined_at: 2.weeks.ago
)

puts "    ✅ #{charlie.full_name}: Créé par #{admin_user.person.full_name}"

puts "\n🌐 PARTIE 2: 3 comptes web créés par les utilisateurs eux-mêmes..."

# 4. Diana - Compte web créé par l'utilisateur
puts "\n  👤 Creating Diana (web account created by user)..."
diana_person = Person.create!(
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
)

diana_user = User.create!(
  person: diana_person,
  email_address: diana_person.email,
  password: "password123",
  password_confirmation: "password123",
  system_role: "web_visitor",
  created_by_admin: false,  # Créé par l'utilisateur
  cgu: true,
  privacy_policy: true
)

puts "    ✅ #{diana_person.full_name}: Compte web créé par l'utilisateur"

# 5. Emma - Compte web créé par l'utilisateur
puts "\n  🎪 Creating Emma (web account created by user)..."
emma_person = Person.create!(
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
)

emma_user = User.create!(
  person: emma_person,
  email_address: emma_person.email,
  password: "password123",
  password_confirmation: "password123",
  system_role: "web_visitor",
  created_by_admin: false,  # Créé par l'utilisateur
  cgu: true,
  privacy_policy: true
)

# Adhésion Basique pour Emma
emma_membership = emma_person.memberships.create!(
  membership_type: basic_membership,
  started_at: Date.current,
  ended_at: 1.year.from_now,
  status: :active,
  first_joined_at: Date.current
)

puts "    ✅ #{emma_person.full_name}: Compte web créé par l'utilisateur"

# 6. Frank - Compte web créé par l'utilisateur
puts "\n  🎨 Creating Frank (web account created by user)..."
frank_person = Person.create!(
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
)

frank_user = User.create!(
  person: frank_person,
  email_address: frank_person.email,
  password: "password123",
  password_confirmation: "password123",
  system_role: "web_visitor",
  created_by_admin: false,  # Créé par l'utilisateur
  cgu: true,
  privacy_policy: true
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
