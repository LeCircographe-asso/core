# Seeds pour les personnes de test
puts "👥 Creating test people..."

# Types d'adhésion et plans
basic_type = MembershipType.find_by(category: :basic)
circus_full_type = MembershipType.find_by(category: :circus_full)
circus_reduced_type = MembershipType.find_by(category: :circus_reduced)
pack10_plan = SubscriptionPlan.find_by(duration: :pack10)

test_people = [
  {
    first_name: "Marie",
    last_name: "Dubois",
    email: "marie.dubois.#{Time.current.to_i}@example.com",
    phone: "+33123456789",
    address: "123 Rue de la Paix, 75001 Paris",
    birth_date: 25.years.ago.to_date,
    occupation: "Étudiante",
    specialty: "Jonglage",
    image_rights: true,
    get_involved: true,
    newsletter_subscribed: true,
    create_user_account: true,
    user_password: "password123"
  },
  {
    first_name: "Jean",
    last_name: "Martin",
    email: "jean.martin.#{Time.current.to_i}@example.com",
    phone: "+33987654321",
    address: "456 Avenue des Champs, 75008 Paris",
    birth_date: 30.years.ago.to_date,
    occupation: "Artiste",
    specialty: "Équilibre",
    image_rights: false,
    get_involved: true,
    newsletter_subscribed: false,
    create_user_account: false
  },
  {
    first_name: "Sophie",
    last_name: "Leroy",
    email: "sophie.leroy.#{Time.current.to_i}@example.com",
    phone: "+33555666777",
    address: "789 Boulevard Saint-Germain, 75006 Paris",
    birth_date: 22.years.ago.to_date,
    occupation: "Étudiante",
    specialty: "Aérien",
    image_rights: true,
    get_involved: false,
    newsletter_subscribed: true,
    create_user_account: true,
    user_password: "password123"
  }
]

test_people.each do |person_attrs|
  # Créer la personne avec le service
  register_service = People::Register.new(person_attrs)
  result = register_service.call

  if result.success?
    person = result.person
    puts "  ✅ #{person.full_name} (#{person.email})"

    # Créer une adhésion de test
    if person_attrs[:first_name] == "Marie"
      # Marie a une adhésion circus complète
      membership = Membership.create!(
        person: person,
        membership_type: circus_full_type,
        started_at: 2.months.ago,
        ended_at: 10.months.from_now,
        status: :active,
        first_joined_at: 2.months.ago
      )
      puts "    📋 Adhésion: #{membership.membership_type.name}"

    elsif person_attrs[:first_name] == "Jean"
      # Jean a une adhésion basique
      membership = Membership.create!(
        person: person,
        membership_type: basic_type,
        started_at: 1.month.ago,
        ended_at: 11.months.from_now,
        status: :active,
        first_joined_at: 1.month.ago
      )
      puts "    📋 Adhésion: #{membership.membership_type.name}"

    elsif person_attrs[:first_name] == "Sophie"
      # Sophie a une adhésion réduite et un carnet
      membership = Membership.create!(
        person: person,
        membership_type: circus_reduced_type,
        started_at: 3.months.ago,
        ended_at: 9.months.from_now,
        status: :active,
        first_joined_at: 3.months.ago
      )
      puts "    📋 Adhésion: #{membership.membership_type.name}"

      # Créer un carnet Pack 10
      book_of_entry = BookOfEntry.create!(
        person: person,
        subscription_plan: pack10_plan,
        sessions_remaining: 7,
        status: :active,
        purchased_at: 1.month.ago,
        expires_at: 11.months.from_now
      )
      puts "    📚 Carnet: #{book_of_entry.subscription_plan.name} (#{book_of_entry.sessions_remaining} séances restantes)"
    end

    # Créer quelques présences de test
    events = Event.limit(3)
    events.each_with_index do |event, index|
      attendance = Attendance.create!(
        person: person,
        event: event,
        date: event.date - index.days
      )
    end
    puts "    📅 Présences: #{person.attendances.count}"

  else
    puts "  ❌ Erreur pour #{person_attrs[:first_name]} #{person_attrs[:last_name]}: #{result.message}"
  end
end

puts "🎉 Created #{Person.count} test people with memberships and attendances"
