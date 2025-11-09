# Seed pour les comptes système (super-admin, admin, volunteer)
puts "\n👑 Creating system accounts..."

def seed_system_account!(label:, person_attrs:, system_role:, password: "123456")
  existing_user = User.find_by(email_address: person_attrs[:email])

  if existing_user
    puts "  ⚠️ #{label} déjà présent: #{existing_user.person.full_name} (#{existing_user.email_address})"
    return existing_user
  end

  result = People::Register.new(
    person_params: person_attrs.merge(is_minor: false),
    newsletter_subscribed: person_attrs[:newsletter_subscribed],
    newsletter_source: "seed",
    create_user_account: true,
    user_params: {
      email_address: person_attrs[:email],
      system_role: system_role,
      created_by_admin: true,
      password: password
    }
  ).call

  unless result.success?
    raise "Failed to seed #{label}: #{result.message} (#{result.errors.join(', ')})"
  end

  puts "  ✅ #{label} créé: #{result.person.full_name} (#{result.person.email})"
  puts "     🔑 Connexion: #{result.user.email_address} / #{password}"
  puts "     🎭 Rôle: #{system_role.humanize}" if result.user.respond_to?(:system_role)

  result.user
end

seed_system_account!(
  label: "Super Admin",
  system_role: "super_admin",
  person_attrs: {
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
    image_rights: true
  }
)

seed_system_account!(
  label: "Admin",
  system_role: "admin",
  person_attrs: {
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
    image_rights: true
  }
)

seed_system_account!(
  label: "Volunteer",
  system_role: "volunteer",
  person_attrs: {
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
    image_rights: true
  }
)

puts "🎉 System accounts ready!"
