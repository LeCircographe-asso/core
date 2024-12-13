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

SubscriptionType.create(
  name: "daily",
  duration: 1,
  price: 4,
  description: "",
)

SubscriptionType.create(
  name: "trimestrial",
  duration: 90,
  price: 65,
  description: "",
)

SubscriptionType.create(
  name: "annual",
  duration: 365,
  price: 150,
  description: "",
)

SubscriptionType.create(
  name: "booklet",
  duration: -1,
  price: 30,
  description: "",
)




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
  email_address: "guest@rails.com",
  password: "123456",
  role: "guest"
)

User.create!(
  email_address: "member@rails.com",
  password: "123456",
  role: "membership"
)

User.create!(
  email_address: "circus_member@rails.com",
  password: "123456",
  role: "circus_membership"
)

User.create!(
  email_address: "volunteer@rails.com",
  password: "123456",
  role: "volunteer"
)

User.create!(
  email_address: "admin@rails.com",
  password: "123456",
  role: "admin"
)

User.create!(
  email_address: "godmode@rails.com",
  password: "123456",
  role: "godmode"
)

User.create!(
  email_address: "alixgeydet@gmail.com",
  password: "123456",
  role: "admin"
)


10.times do |i|
  Payment.create(id: i, payment_method: %w[CB check cash].sample, amount: rand(100), status: true)
end




20.times do
  User.create!(
    email_address: Faker::Internet.email,
    password: "123456",
    last_name: Faker::Name.last_name,
    first_name: Faker::Name.first_name,
    birthdate: Faker::Date.birthday(min_age: 18, max_age: 99),
    address: Faker::Address.street_address,
    zip_code: Faker::Address.zip_code,
    town: Faker::Address.city,
    country: Faker::Address.country,
    phone_number: Faker::PhoneNumber.phone_number,
    occupation: Faker::Job.title,
    specialty: Faker::Job.field,
    image_rights: [ true, false ].sample,
    newsletter: [ true, false ].sample,
    get_involved: [ true, false ].sample,
    role: Role.all.sample.name
  )
end

10.times do
  Event.create!(
    title: Faker::TvShows::BigBangTheory.character,
    upper_description: Faker::TvShows::BigBangTheory.quote,
    middle_description: "",
    bottom_description: "",
    location: Faker::Address.city,
    date: Faker::Date.forward(days: 1),
    creator: User.all.sample

  )
end


10.times do
  first_stid = SubscriptionType.first.id
  last_stid = SubscriptionType.last.id

  stid_range = last_stid - first_stid
  UserMembership.create(
    user_id: rand(20),
    subscription_type_id: (first_stid + rand(stid_range)),
    payment_id: rand(10),
    status: true
  )
end
