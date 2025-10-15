# Seeds pour le super administrateur
puts "👑 Creating super admin..."

# Créer le super admin directement avec un User
admin_user = User.create!(
  email_address: "admin@rails.com",
  password: "123456",
  password_confirmation: "123456",
  system_role: :super_admin,
  first_name: "Super",
  last_name: "Admin",
  created_by_admin: true,
  cgu: true,
  privacy_policy: true
)

puts "  ✅ Super Admin créé: #{admin_user.full_name} (#{admin_user.email_address})"
puts "     🔑 Connexion: admin@rails.com / 123456"
puts "     🎭 Rôle: #{admin_user.system_role.humanize}"

puts "🎉 Super admin created successfully!"
