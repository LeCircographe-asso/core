# Seeds pour le super administrateur
puts "👑 Creating super admin..."

# Créer d'abord la Person pour le super admin
admin_person = Person.create!(
  first_name: "Super",
  last_name: "Admin",
  email: "admin@rails.com",
  phone: "+33123456789",
  address: "123 Admin Street",
  zip_code: "75001",
  town: "Paris",
  country: "France",
  occupation: "System Administrator",
  image_rights: true,
  get_involved: true,
  newsletter_subscribed: true,
  dyslexic_font: false
)

# Créer le User lié à cette Person
admin_user = User.create!(
  email_address: "admin@rails.com",
  password: "123456",
  password_confirmation: "123456",
  system_role: :super_admin,
  person: admin_person,
  created_by_admin: true,
  cgu: true,
  privacy_policy: true
)

puts "  ✅ Super Admin créé: #{admin_person.full_name} (#{admin_user.email_address})"
puts "     🔑 Connexion: admin@rails.com / 123456"
puts "     🎭 Rôle: #{admin_user.system_role.humanize}"
puts "     👤 Person ID: #{admin_person.id}"

puts "🎉 Super admin created successfully!"
