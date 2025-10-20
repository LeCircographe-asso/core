# Seed pour le super administrateur
puts "\n👑 Creating super admin..."

admin_person = Person.create!(
  first_name: "Super",
  last_name: "Admin",
  email: "admin@rails.com",
  phone: "+33 12 34 56 789",
  address: "123 Rue du Cirque",
  zip_code: "75001",
  town: "Paris",
  country: "France",
  birth_date: Date.new(1980, 1, 1),
  newsletter_subscribed: true,
  get_involved: true,
  image_rights: true,
  is_minor: false
)

admin_user = User.create!(
  person: admin_person,
  email_address: "admin@rails.com",
  password: "123456",
  password_confirmation: "123456",
  system_role: "super_admin",
  created_by_admin: true,
  cgu: true,
  privacy_policy: true
)

puts "  ✅ Super Admin créé: #{admin_person.full_name} (#{admin_person.email})"
puts "     🔑 Connexion: #{admin_person.email} / 123456"
puts "     🎭 Rôle: Super admin"
puts "     👤 Person ID: #{admin_person.id}"
puts "🎉 Super admin created successfully!"
