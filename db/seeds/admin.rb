# Seed pour les comptes système (super-admin, admin, volunteer)
puts "\n👑 Creating system accounts..."

# 1. Super Admin
super_admin_person = Person.create!(
  first_name: "Super",
  last_name: "Admin",
  email: "super-admin@rails.com",
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

super_admin_user = User.create!(
  person: super_admin_person,
  email_address: "super-admin@rails.com",
  password: "123456",
  password_confirmation: "123456",
  system_role: "super_admin",
  created_by_admin: true,
  cgu: true,
  privacy_policy: true
)

puts "  ✅ Super Admin créé: #{super_admin_person.full_name} (#{super_admin_person.email})"
puts "     🔑 Connexion: #{super_admin_person.email} / 123456"
puts "     🎭 Rôle: Super admin"

# 2. Admin
admin_person = Person.create!(
  first_name: "Admin",
  last_name: "User",
  email: "admin@rails.com",
  phone: "+33 12 34 56 790",
  address: "124 Rue du Cirque",
  zip_code: "75001",
  town: "Paris",
  country: "France",
  birth_date: Date.new(1985, 3, 15),
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
  system_role: "admin",
  created_by_admin: true,
  cgu: true,
  privacy_policy: true
)

puts "  ✅ Admin créé: #{admin_person.full_name} (#{admin_person.email})"
puts "     🔑 Connexion: #{admin_person.email} / 123456"
puts "     🎭 Rôle: Admin"

# 3. Volunteer
volunteer_person = Person.create!(
  first_name: "Volunteer",
  last_name: "Helper",
  email: "volunteer@rails.com",
  phone: "+33 12 34 56 791",
  address: "125 Rue du Cirque",
  zip_code: "75001",
  town: "Paris",
  country: "France",
  birth_date: Date.new(1990, 6, 20),
  newsletter_subscribed: true,
  get_involved: true,
  image_rights: true,
  is_minor: false
)

volunteer_user = User.create!(
  person: volunteer_person,
  email_address: "volunteer@rails.com",
  password: "123456",
  password_confirmation: "123456",
  system_role: "volunteer",
  created_by_admin: true,
  cgu: true,
  privacy_policy: true
)

puts "  ✅ Volunteer créé: #{volunteer_person.full_name} (#{volunteer_person.email})"
puts "     🔑 Connexion: #{volunteer_person.email} / 123456"
puts "     🎭 Rôle: Volunteer"

puts "🎉 System accounts created successfully!"
