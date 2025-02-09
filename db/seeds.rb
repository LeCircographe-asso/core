# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Nettoyage de la base dans l'ordre inverse des dépendances
puts "Nettoyage de la base de données..."

def table_exists?(table_name)
  ActiveRecord::Base.connection.table_exists?(table_name)
end

[
  EventAttendee,
  UserRole,
  Donation,
  TrainingAttendee,
  UserMembership,
  Event,
  Payment,
  TrainingSession,
  SubscriptionType,
  Role,
  User
].each do |model|
  if table_exists?(model.table_name)
    puts "Suppression des #{model.table_name}..."
    model.destroy_all
  else
    puts "Table #{model.table_name} n'existe pas encore..."
  end
end

puts "Création des rôles..."
# Création des rôles
Role.create!(name: 'guest')      # 0
Role.create!(name: 'member')     # 1
Role.create!(name: 'volunteer')  # 2
Role.create!(name: 'admin')      # 3
Role.create!(name: 'godmode')    # 4

puts "Création des types d'abonnement..."
# Adhésion simple (1€)
SubscriptionType.create!(
  name: "Adhésion Simple",
  price: 1,
  category: :basic_membership,
  duration_type: "years",
  duration_value: 1,
  has_limited_sessions: false,
  active: true,
  valid_from: Date.current
)

# Adhésion cirque (10€)
SubscriptionType.create!(
  name: "Adhésion Cirque",
  price: 10,
  category: :circus_membership,
  duration_type: "years",
  duration_value: 1,
  has_limited_sessions: false,
  active: true,
  valid_from: Date.current
)

# Pass journée (4€)
SubscriptionType.create!(
  name: "Pass Journée",
  price: 4,
  category: :day_pass,
  duration_type: "days",
  duration_value: 1,
  has_limited_sessions: false,
  active: true,
  valid_from: Date.current
)

# Pack 10 séances (30€)
SubscriptionType.create!(
  name: "Carnet 10 séances",
  price: 30,
  category: :ten_sessions,
  duration_type: "sessions",
  duration_value: 10,
  has_limited_sessions: true,
  active: true,
  valid_from: Date.current
)

# Abonnement trimestriel (65€)
SubscriptionType.create!(
  name: "Abonnement Trimestriel",
  price: 65,
  category: :quarterly,
  duration_type: "months",
  duration_value: 3,
  has_limited_sessions: false,
  active: true,
  valid_from: Date.current
)

# Abonnement annuel (150€)
SubscriptionType.create!(
  name: "Abonnement Annuel",
  price: 150,
  category: :yearly,
  duration_type: "years",
  duration_value: 1,
  has_limited_sessions: false,
  active: true,
  valid_from: Date.current
)

puts "Création des utilisateurs..."
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
  get_involved: true,
  role: :guest
)

# Création des utilisateurs de test pour chaque rôle
[
  { role: :guest, email: "guest@rails.com" },
  { role: :member, email: "member@rails.com" },
  { role: :volunteer, email: "volunteer@rails.com" },
  { role: :admin, email: "admin@rails.com" },
  { role: :godmode, email: "godmode@rails.com" }
].each do |user_data|
  User.create!(
    email_address: user_data[:email],
    password: "123456",
    first_name: user_data[:role].to_s.capitalize,
    last_name: "User",
    role: user_data[:role],
    birthdate: "1990-01-01",
    zip_code: "75000",
    town: "Paris",
    country: "France",
    phone_number: "0123456789",
    image_rights: true,
    newsletter: false,
    get_involved: true
  )
end

User.create!(
  first_name: "Alix",
  last_name: "Geydet",
  email_address: "alixgeydet@gmail.com",
  password: "123456",
  role: :admin,
  birthdate: "1990-01-01",
  zip_code: "75000",
  town: "Paris",
  country: "France",
  phone_number: "0123456789",
  image_rights: true,
  newsletter: false,
  get_involved: true
)

puts "Création des paiements..."
10.times do |i|
  Payment.create!(
    payment_method: %w[card check cash].sample,
    amount: rand(10..100),
    status: :completed,
    user: User.all.sample
  )
end

puts "Création des utilisateurs supplémentaires..."
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
    image_rights: [true, false].sample,
    newsletter: [true, false].sample,
    get_involved: [true, false].sample,
    role: [:guest, :member, :volunteer, :admin].sample
  )
end

puts "Création des événements..."
5.times do
  event = Event.create!(
    title: Faker::TvShows::BigBangTheory.character,
    upper_description: "",
    middle_description: Faker::TvShows::BigBangTheory.quote,
    bottom_description: "",
    location: Faker::Address.city,
    date: Faker::Date.forward(days: 1),
    creator: User.all.sample
  )

  rand(1..5).times do
    user = User.all.sample
    unless event.users.include?(user) || event.creator == user
      payment = Payment.create!(
        user: user,
        amount: rand(10..50),
        status: :completed,
        payment_method: %w[card check cash].sample
      )
      
      EventAttendee.create!(
        user: user,
        event: event,
        payment: payment
      )
    end
  end
end

puts "Création des abonnements..."
User.all.each do |user|
  next if user.guest?
  
  base_type = if user.has_privileges? # volunteer, admin, ou godmode
                SubscriptionType.find_by(category: :circus_membership)
              else
                SubscriptionType.find_by(category: :basic_membership)
              end

  base_payment = Payment.create!(
    user: user,
    amount: base_type.price,
    status: :completed,
    payment_method: %w[card check cash].sample
  )
  
  UserMembership.create!(
    user: user,
    subscription_type: base_type,
    payment: base_payment,
    status: :active,
    start_date: Date.current,
    end_date: 1.year.from_now,
    year_reference: Date.current.year
  )

  if user.has_privileges?
    training_type = SubscriptionType.where(category: [:day_pass, :ten_sessions, :quarterly, :yearly]).sample
    training_payment = Payment.create!(
      user: user,
      amount: training_type.price,
      status: :completed,
      payment_method: %w[card check cash].sample
    )

    UserMembership.create!(
      user: user,
      subscription_type: training_type,
      payment: training_payment,
      status: :active,
      start_date: Date.current,
      end_date: training_type.duration_type == "sessions" ? 1.year.from_now : eval("#{training_type.duration_value}.#{training_type.duration_type}.from_now"),
      remaining_sessions: training_type.has_limited_sessions ? training_type.duration_value : nil,
      year_reference: Date.current.year
    )
  end
end

puts "Création des sessions d'entraînement..."
# Session du jour
TrainingSession.create!(
  date: Date.current,
  status: :open,
  recorded_by: User.find_by(role: :admin),
  year_reference: Date.current.year,
  week_number: Date.current.strftime("%U").to_i,
  month_number: Date.current.month
)

# Sessions passées (pour les statistiques)
7.times do |i|
  TrainingSession.create!(
    date: (i+1).days.ago.to_date,
    status: :closed,
    recorded_by: User.find_by(role: :admin),
    year_reference: (i+1).days.ago.year,
    week_number: (i+1).days.ago.strftime("%U").to_i,
    month_number: (i+1).days.ago.month
  )
end

# Sessions futures
7.times do |i|
  TrainingSession.create!(
    date: (i+1).days.from_now.to_date,
    status: :open,
    recorded_by: User.find_by(role: :admin),
    year_reference: (i+1).days.from_now.year,
    week_number: (i+1).days.from_now.strftime("%U").to_i,
    month_number: (i+1).days.from_now.month
  )
end

puts "Création des présences..."
# Création de quelques présences
TrainingSession.all.each do |session|
  next if session.date > Date.current # Pas de présences pour les sessions futures
  
  # Sélectionner des membres cirque aléatoires
  circus_members = User.where(role: [:volunteer, :admin, :godmode]).sample(rand(3..8))
  
  circus_members.each do |member|
    # Trouver une adhésion active
    membership = member.user_memberships.active.joins(:subscription_type)
                      .where(subscription_types: { category: [:ten_sessions, :quarterly, :yearly] })
                      .first
    
    next unless membership # Skip si pas d'adhésion active
    
    TrainingAttendee.create!(
      user: member,
      user_membership: membership,
      training_session: session,
      checked_by: User.find_by(role: :admin),
      check_in_time: session.date.to_time + rand(10..19).hours,
      is_visitor: false,
      year_reference: session.year_reference,
      week_number: session.week_number,
      month_number: session.month_number
    )
  end
end
