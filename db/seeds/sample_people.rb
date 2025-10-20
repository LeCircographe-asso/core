# Seed pour des Person de test avec numéros d'adhérent et historiques
puts "\n👥 Creating sample people with member numbers and history..."

# Récupérer les types d'adhésion
basic_membership = MembershipType.find_by(category: "basic")
circus_full_membership = MembershipType.find_by(category: "circus_full")
circus_reduced_membership = MembershipType.find_by(category: "circus_reduced")

# Récupérer l'admin pour les paiements
admin_user = User.find_by(system_role: "super_admin")

# 1. Alice - Adhérente Cirque avec historique (Basique → Cirque)
puts "\n  🎭 Creating Alice (Cirque with history)..."
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
  is_minor: false
)

# Créer un compte web pour Alice
alice_user = User.create!(
  person: alice,
  email_address: alice.email,
  password: "password123",
  password_confirmation: "password123",
  system_role: "web_visitor",
  created_by_admin: true,
  cgu: true,
  privacy_policy: true
)

# Simuler l'historique : Alice a commencé en Basique puis est passée en Cirque
# 1. Adhésion Basique (il y a 6 mois)
basic_membership_alice = alice.memberships.create!(
  membership_type: basic_membership,
  started_at: 6.months.ago,
  ended_at: 6.months.ago + 1.year,
  status: :expired,
  first_joined_at: 6.months.ago
)

# Paiement pour l'adhésion Basique (cela assigne le numéro)
basic_payment = Payment.create!(
  person: alice,
  recorded_by: admin_user,
  total_cents: basic_membership.price_cents,
  payment_method: :cash,
  status: :success,
  notes: "Paiement initial adhésion Basique"
)

PaymentLine.create!(
  payment: basic_payment,
  item: basic_membership_alice,
  amount_cents: basic_membership.price_cents,
  description: "Adhésion Basique"
)

# Assigner le numéro d'adhérent pour l'adhésion Basique
MemberManagementService.assign_member_number(alice, 'BASIQUE')

# 2. Adhésion Cirque (maintenant)
circus_membership_alice = alice.memberships.create!(
  membership_type: circus_full_membership,
  started_at: Date.current,
  ended_at: 1.year.from_now,
  status: :active,
  first_joined_at: Date.current
)

# Paiement pour l'adhésion Cirque
circus_payment = Payment.create!(
  person: alice,
  recorded_by: admin_user,
  total_cents: circus_full_membership.price_cents,
  payment_method: :card,
  status: :success,
  notes: "Upgrade vers Cirque"
)

PaymentLine.create!(
  payment: circus_payment,
  item: circus_membership_alice,
  amount_cents: circus_full_membership.price_cents,
  description: "Adhésion Cirque Complète"
)

# Changer le numéro d'adhérent (Basique → Cirque)
alice.change_member_number('CIRQUE', 'Upgrade de Basique vers Cirque')

puts "    ✅ #{alice.full_name}: #{alice.member_number} (historique: #{alice.member_number_history.count} entrée(s))"

# 2. Bob - Adhérent Basique simple
puts "\n  🎪 Creating Bob (Basique simple)..."
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
  is_minor: false
)

# Créer un compte web pour Bob
bob_user = User.create!(
  person: bob,
  email_address: bob.email,
  password: "password123",
  password_confirmation: "password123",
  system_role: "web_visitor",
  created_by_admin: true,
  cgu: true,
  privacy_policy: true
)

# Adhésion Basique
bob_membership = bob.memberships.create!(
  membership_type: basic_membership,
  started_at: 3.months.ago,
  ended_at: 3.months.ago + 1.year,
  status: :active,
  first_joined_at: 3.months.ago
)

# Paiement pour l'adhésion Basique
bob_payment = Payment.create!(
  person: bob,
  recorded_by: admin_user,
  total_cents: basic_membership.price_cents,
  payment_method: :cash,
  status: :success,
  notes: "Paiement adhésion Basique"
)

PaymentLine.create!(
  payment: bob_payment,
  item: bob_membership,
  amount_cents: basic_membership.price_cents,
  description: "Adhésion Basique"
)

# Assigner le numéro d'adhérent
MemberManagementService.assign_member_number(bob, 'BASIQUE')

puts "    ✅ #{bob.full_name}: #{bob.member_number} (historique: #{bob.member_number_history.count} entrée(s))"

# 3. Charlie - Adhérent Cirque Réduit
puts "\n  🎨 Creating Charlie (Cirque Réduit)..."
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
  is_minor: false
)

# Pas de compte web pour Charlie

# Adhésion Cirque Réduite
charlie_membership = charlie.memberships.create!(
  membership_type: circus_reduced_membership,
  started_at: 1.month.ago,
  ended_at: 1.month.ago + 1.year,
  status: :active,
  first_joined_at: 1.month.ago
)

# Paiement pour l'adhésion Cirque Réduite
charlie_payment = Payment.create!(
  person: charlie,
  recorded_by: admin_user,
  total_cents: circus_reduced_membership.price_cents,
  payment_method: :transfer,
  status: :success,
  notes: "Paiement étudiant Cirque Réduit"
)

PaymentLine.create!(
  payment: charlie_payment,
  item: charlie_membership,
  amount_cents: circus_reduced_membership.price_cents,
  description: "Adhésion Cirque Réduite"
)

# Assigner le numéro d'adhérent
MemberManagementService.assign_member_number(charlie, 'CIRQUE')

puts "    ✅ #{charlie.full_name}: #{charlie.member_number} (historique: #{charlie.member_number_history.count} entrée(s))"

# 4. Diana - Person sans adhésion (pas de numéro d'adhérent)
puts "\n  👤 Creating Diana (no membership yet)..."
diana = Person.create!(
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
  is_minor: false
)

# Pas de compte web, pas d'adhésion, pas de numéro d'adhérent
puts "    ✅ #{diana.full_name}: Pas de numéro d'adhérent (pas encore d'adhésion)"

# 5. Emma - Adhérente avec historique complexe (Basique → Cirque → Basique)
puts "\n  🎪 Creating Emma (complex history)..."
emma = Person.create!(
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
  is_minor: false
)

# Créer un compte web pour Emma
emma_user = User.create!(
  person: emma,
  email_address: emma.email,
  password: "password123",
  password_confirmation: "password123",
  system_role: "web_visitor",
  created_by_admin: true,
  cgu: true,
  privacy_policy: true
)

# 1. Adhésion Basique (il y a 1 an)
emma_basic_1 = emma.memberships.create!(
  membership_type: basic_membership,
  started_at: 1.year.ago,
  ended_at: 1.year.ago + 1.year,
  status: :expired,
  first_joined_at: 1.year.ago
)

# Paiement pour la première adhésion Basique
emma_payment_1 = Payment.create!(
  person: emma,
  recorded_by: admin_user,
  total_cents: basic_membership.price_cents,
  payment_method: :cash,
  status: :success,
  notes: "Première adhésion Basique"
)

PaymentLine.create!(
  payment: emma_payment_1,
  item: emma_basic_1,
  amount_cents: basic_membership.price_cents,
  description: "Adhésion Basique"
)

# Assigner le premier numéro d'adhérent
MemberManagementService.assign_member_number(emma, 'BASIQUE')

# 2. Adhésion Cirque (il y a 6 mois)
emma_cirque = emma.memberships.create!(
  membership_type: circus_full_membership,
  started_at: 6.months.ago,
  ended_at: 6.months.ago + 1.year,
  status: :expired,
  first_joined_at: 6.months.ago
)

# Paiement pour l'adhésion Cirque
emma_payment_2 = Payment.create!(
  person: emma,
  recorded_by: admin_user,
  total_cents: circus_full_membership.price_cents,
  payment_method: :card,
  status: :success,
  notes: "Upgrade vers Cirque"
)

PaymentLine.create!(
  payment: emma_payment_2,
  item: emma_cirque,
  amount_cents: circus_full_membership.price_cents,
  description: "Adhésion Cirque Complète"
)

# Changer le numéro d'adhérent (Basique → Cirque)
emma.change_member_number('CIRQUE', 'Upgrade de Basique vers Cirque')

# 3. Retour en Basique (maintenant)
emma_basic_2 = emma.memberships.create!(
  membership_type: basic_membership,
  started_at: Date.current,
  ended_at: 1.year.from_now,
  status: :active,
  first_joined_at: Date.current
)

# Paiement pour le retour en Basique
emma_payment_3 = Payment.create!(
  person: emma,
  recorded_by: admin_user,
  total_cents: basic_membership.price_cents,
  payment_method: :cash,
  status: :success,
  notes: "Retour en Basique"
)

PaymentLine.create!(
  payment: emma_payment_3,
  item: emma_basic_2,
  amount_cents: basic_membership.price_cents,
  description: "Adhésion Basique"
)

# Changer le numéro d'adhérent (Cirque → Basique)
emma.change_member_number('BASIQUE', 'Retour de Cirque vers Basique')

puts "    ✅ #{emma.full_name}: #{emma.member_number} (historique: #{emma.member_number_history.count} entrée(s))"

puts "\n🎉 Created #{Person.count - 1} sample people (excluding admin)"
puts "📊 Member number statistics:"
Person.where.not(member_number: nil).each do |person|
  history_count = person.member_number_history.count
  puts "  - #{person.full_name}: #{person.member_number} (#{history_count} historique(s))"
end
