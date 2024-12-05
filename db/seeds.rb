# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# En suivant l'ordre des dépendances

EventAttendee.destroy_all
UserRole.destroy_all
Donation.destroy_all
Session.destroy_all
UserMembership.destroy_all
Event.destroy_all
Payment.destroy_all
SubscriptionType.destroy_all
Role.destroy_all
User.destroy_all




Role.create(name: 'guest')
Role.create(name: 'membership')
Role.create(name: 'circus_membership')
Role.create(name: 'volunteer')
Role.create(name: 'admin')
Role.create(name: 'godmode')

UserMembership.create()

User.create!(
  email_address: "test@example.com",
  password: "123456",
  last_name: "Dupont",
  first_name: "Jean",
  birthdate: "1970-01-01",
  zip_code: "75000",
  town: "Paris",
  country: "France",
  phone_number: "0123456789",
  occupation: "Developer",
  specialty: "Backend",
  image_rights: true,
  newsletter: false,
  get_involved: true
)


User.create!(
  email_address: "admin@rails.com",
  password: "123456",
  role: "admin"
)

20.times do
  User.create!(
    email_address: Faker::Internet.email,
    password: "password123",
    last_name: Faker::Name.last_name,
    first_name: Faker::Name.first_name,
    birthdate: Faker::Date.birthday(min_age: 18, max_age: 99),
    zip_code: Faker::Address.zip_code,
    town: Faker::Address.city,
    country: Faker::Address.country,
    phone_number: Faker::PhoneNumber.phone_number,
    occupation: Faker::Job.title,
    specialty: Faker::Job.field,
    image_rights: [true, false].sample,
    newsletter: [true, false].sample,
    get_involved: [true, false].sample,
    role: %w[guest membership circus_membership volunteer].sample
  )
end