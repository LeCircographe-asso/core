# Seeds pour les personnes de test - Version améliorée avec 25 personnes
puts "👥 Creating test people (25 persons with varied profiles)..."

# Types d'adhésion et plans
basic_type = MembershipType.find_by(category: :basic)
circus_full_type = MembershipType.find_by(category: :circus_full)
circus_reduced_type = MembershipType.find_by(category: :circus_reduced)
pack10_plan = SubscriptionPlan.find_by(duration: :pack10)
trimestre_plan = SubscriptionPlan.find_by(duration: :quarterly)
annuel_plan = SubscriptionPlan.find_by(duration: :annual)

# Données de test variées et réalistes
test_people = [
  # Artistes professionnels avec comptes utilisateur
  {
    first_name: "Marie",
    last_name: "Dubois",
    email: "marie.dubois@circographe.fr",
    phone: "+33123456789",
    address: "123 Rue de la Paix, 75001 Paris",
    birth_date: 25.years.ago.to_date,
    occupation: "Artiste de cirque",
    specialty: "Jonglage",
    image_rights: true,
    get_involved: true,
    newsletter_subscribed: true,
    create_user_account: true,
    user_password: "password123",
    membership_type: circus_full_type,
    subscription_plan: annuel_plan
  },
  {
    first_name: "Lucas",
    last_name: "Moreau",
    email: "lucas.moreau@circographe.fr",
    phone: "+33987654321",
    address: "456 Avenue des Champs, 75008 Paris",
    birth_date: 28.years.ago.to_date,
    occupation: "Artiste aérien",
    specialty: "Trapèze",
    image_rights: true,
    get_involved: true,
    newsletter_subscribed: true,
    create_user_account: true,
    user_password: "password123",
    membership_type: circus_full_type,
    subscription_plan: trimestre_plan
  },
  {
    first_name: "Emma",
    last_name: "Petit",
    email: "emma.petit@circographe.fr",
    phone: "+33555666777",
    address: "789 Boulevard Saint-Germain, 75006 Paris",
    birth_date: 22.years.ago.to_date,
    occupation: "Équilibriste",
    specialty: "Fil de fer",
    image_rights: true,
    get_involved: true,
    newsletter_subscribed: true,
    create_user_account: true,
    user_password: "password123",
    membership_type: circus_full_type,
    subscription_plan: pack10_plan
  },
  
  # Étudiants avec comptes utilisateur
  {
    first_name: "Thomas",
    last_name: "Martin",
    email: "thomas.martin@student.fr",
    phone: "+33666777888",
    address: "12 Rue de Rivoli, 75004 Paris",
    birth_date: 19.years.ago.to_date,
    occupation: "Étudiant en arts du cirque",
    specialty: "Acrobatie",
    image_rights: false,
    get_involved: true,
    newsletter_subscribed: true,
    create_user_account: true,
    user_password: "password123",
    membership_type: circus_reduced_type,
    subscription_plan: pack10_plan
  },
  {
    first_name: "Chloé",
    last_name: "Bernard",
    email: "chloe.bernard@student.fr",
    phone: "+33777888999",
    address: "34 Avenue de la République, 75011 Paris",
    birth_date: 20.years.ago.to_date,
    occupation: "Étudiante",
    specialty: "Danse",
    image_rights: false,
    get_involved: false,
    newsletter_subscribed: true,
    create_user_account: true,
    user_password: "password123",
    membership_type: basic_type
  },
  {
    first_name: "Alexandre",
    last_name: "Durand",
    email: "alexandre.durand@student.fr",
    phone: "+33888999000",
    address: "56 Rue de Belleville, 75019 Paris",
    birth_date: 21.years.ago.to_date,
    occupation: "Étudiant",
    specialty: "Magie",
    image_rights: true,
    get_involved: true,
    newsletter_subscribed: false,
    create_user_account: true,
    user_password: "password123",
    membership_type: circus_reduced_type
  },
  
  # Parents avec comptes utilisateur
  {
    first_name: "Isabelle",
    last_name: "Roux",
    email: "isabelle.roux@parent.fr",
    phone: "+33999000111",
    address: "78 Rue de la Paix, 75002 Paris",
    birth_date: 35.years.ago.to_date,
    occupation: "Professeure",
    specialty: nil,
    image_rights: false,
    get_involved: true,
    newsletter_subscribed: true,
    create_user_account: true,
    user_password: "password123",
    membership_type: basic_type
  },
  {
    first_name: "Marc",
    last_name: "Simon",
    email: "marc.simon@parent.fr",
    phone: "+33111222333",
    address: "90 Avenue des Ternes, 75017 Paris",
    birth_date: 38.years.ago.to_date,
    occupation: "Ingénieur",
    specialty: nil,
    image_rights: false,
    get_involved: false,
    newsletter_subscribed: true,
    create_user_account: true,
    user_password: "password123",
    membership_type: basic_type
  },
  
  # Personnes sans compte utilisateur (adhésions simples)
  {
    first_name: "Sophie",
    last_name: "Leroy",
    email: "sophie.leroy@example.com",
    phone: "+33222333444",
    address: "12 Rue de la Paix, 75001 Paris",
    birth_date: 26.years.ago.to_date,
    occupation: "Comédienne",
    specialty: "Clown",
    image_rights: false,
    get_involved: true,
    newsletter_subscribed: false,
    create_user_account: false,
    membership_type: circus_full_type
  },
  {
    first_name: "Pierre",
    last_name: "Moreau",
    email: "pierre.moreau@example.com",
    phone: "+33333444555",
    address: "34 Rue de Rivoli, 75004 Paris",
    birth_date: 32.years.ago.to_date,
    occupation: "Musiciens",
    specialty: "Percussion",
    image_rights: true,
    get_involved: true,
    newsletter_subscribed: true,
    create_user_account: false,
    membership_type: basic_type
  },
  
  # Bénévoles avec comptes utilisateur
  {
    first_name: "Catherine",
    last_name: "Lefebvre",
    email: "catherine.lefebvre@benevole.fr",
    phone: "+33444555666",
    address: "56 Boulevard Haussmann, 75009 Paris",
    birth_date: 45.years.ago.to_date,
    occupation: "Retraitée",
    specialty: nil,
    image_rights: false,
    get_involved: true,
    newsletter_subscribed: true,
    create_user_account: true,
    user_password: "password123",
    membership_type: basic_type
  },
  {
    first_name: "Philippe",
    last_name: "Garcia",
    email: "philippe.garcia@benevole.fr",
    phone: "+33555666777",
    address: "78 Rue de la Paix, 75002 Paris",
    birth_date: 42.years.ago.to_date,
    occupation: "Fonctionnaire",
    specialty: nil,
    image_rights: false,
    get_involved: true,
    newsletter_subscribed: false,
    create_user_account: true,
    user_password: "password123",
    membership_type: basic_type
  },
  
  # Artistes débutants
  {
    first_name: "Amélie",
    last_name: "Thomas",
    email: "amelie.thomas@artiste.fr",
    phone: "+33666777888",
    address: "90 Rue de Belleville, 75019 Paris",
    birth_date: 24.years.ago.to_date,
    occupation: "Artiste débutante",
    specialty: "Contorsion",
    image_rights: true,
    get_involved: true,
    newsletter_subscribed: true,
    create_user_account: true,
    user_password: "password123",
    membership_type: circus_reduced_type,
    subscription_plan: pack10_plan
  },
  {
    first_name: "Julien",
    last_name: "Robert",
    email: "julien.robert@artiste.fr",
    phone: "+33777888999",
    address: "12 Avenue des Champs, 75008 Paris",
    birth_date: 27.years.ago.to_date,
    occupation: "Artiste",
    specialty: "Main à main",
    image_rights: true,
    get_involved: false,
    newsletter_subscribed: true,
    create_user_account: true,
    user_password: "password123",
    membership_type: circus_full_type,
    subscription_plan: trimestre_plan
  },
  
  # Familles avec enfants
  {
    first_name: "Nathalie",
    last_name: "Petit",
    email: "nathalie.petit@famille.fr",
    phone: "+33888999000",
    address: "34 Rue de la République, 75011 Paris",
    birth_date: 33.years.ago.to_date,
    occupation: "Mère au foyer",
    specialty: nil,
    image_rights: false,
    get_involved: true,
    newsletter_subscribed: true,
    create_user_account: true,
    user_password: "password123",
    membership_type: basic_type
  },
  {
    first_name: "David",
    last_name: "Moreau",
    email: "david.moreau@famille.fr",
    phone: "+33999000111",
    address: "56 Boulevard Saint-Germain, 75006 Paris",
    birth_date: 36.years.ago.to_date,
    occupation: "Père au foyer",
    specialty: nil,
    image_rights: false,
    get_involved: false,
    newsletter_subscribed: true,
    create_user_account: true,
    user_password: "password123",
    membership_type: basic_type
  },
  
  # Artistes confirmés sans compte
  {
    first_name: "Claire",
    last_name: "Martin",
    email: "claire.martin@artiste.com",
    phone: "+33111222333",
    address: "78 Rue de Rivoli, 75004 Paris",
    birth_date: 29.years.ago.to_date,
    occupation: "Artiste confirmée",
    specialty: "Corde lisse",
    image_rights: true,
    get_involved: true,
    newsletter_subscribed: true,
    create_user_account: false,
    membership_type: circus_full_type,
    subscription_plan: annuel_plan
  },
  {
    first_name: "Antoine",
    last_name: "Bernard",
    email: "antoine.bernard@artiste.com",
    phone: "+33222333444",
    address: "90 Avenue des Ternes, 75017 Paris",
    birth_date: 31.years.ago.to_date,
    occupation: "Artiste",
    specialty: "Portés acrobatiques",
    image_rights: true,
    get_involved: true,
    newsletter_subscribed: false,
    create_user_account: false,
    membership_type: circus_full_type,
    subscription_plan: trimestre_plan
  },
  
  # Étudiants en formation
  {
    first_name: "Sarah",
    last_name: "Dubois",
    email: "sarah.dubois@formation.fr",
    phone: "+33333444555",
    address: "12 Rue de Belleville, 75019 Paris",
    birth_date: 18.years.ago.to_date,
    occupation: "Étudiante en formation",
    specialty: "Aérien",
    image_rights: false,
    get_involved: true,
    newsletter_subscribed: true,
    create_user_account: true,
    user_password: "password123",
    membership_type: circus_reduced_type
  },
  {
    first_name: "Maxime",
    last_name: "Leroy",
    email: "maxime.leroy@formation.fr",
    phone: "+33444555666",
    address: "34 Rue de la Paix, 75002 Paris",
    birth_date: 19.years.ago.to_date,
    occupation: "Étudiant",
    specialty: "Jonglage",
    image_rights: false,
    get_involved: false,
    newsletter_subscribed: true,
    create_user_account: true,
    user_password: "password123",
    membership_type: circus_reduced_type,
    subscription_plan: pack10_plan
  },
  
  # Artistes occasionnels
  {
    first_name: "Camille",
    last_name: "Roux",
    email: "camille.roux@occasional.fr",
    phone: "+33555666777",
    address: "56 Boulevard Haussmann, 75009 Paris",
    birth_date: 26.years.ago.to_date,
    occupation: "Artiste occasionnelle",
    specialty: "Danse",
    image_rights: true,
    get_involved: true,
    newsletter_subscribed: true,
    create_user_account: true,
    user_password: "password123",
    membership_type: basic_type
  },
  {
    first_name: "Romain",
    last_name: "Simon",
    email: "romain.simon@occasional.fr",
    phone: "+33666777888",
    address: "78 Avenue des Champs, 75008 Paris",
    birth_date: 28.years.ago.to_date,
    occupation: "Artiste",
    specialty: "Théâtre",
    image_rights: false,
    get_involved: false,
    newsletter_subscribed: false,
    create_user_account: true,
    user_password: "password123",
    membership_type: basic_type
  },
  
  # Personnes âgées
  {
    first_name: "Monique",
    last_name: "Garcia",
    email: "monique.garcia@senior.fr",
    phone: "+33777888999",
    address: "90 Rue de Rivoli, 75004 Paris",
    birth_date: 62.years.ago.to_date,
    occupation: "Retraitée",
    specialty: nil,
    image_rights: false,
    get_involved: true,
    newsletter_subscribed: true,
    create_user_account: true,
    user_password: "password123",
    membership_type: basic_type
  },
  {
    first_name: "Jean",
    last_name: "Martin",
    email: "jean.martin@senior.fr",
    phone: "+33888999000",
    address: "12 Boulevard Saint-Germain, 75006 Paris",
    birth_date: 58.years.ago.to_date,
    occupation: "Retraité",
    specialty: nil,
    image_rights: false,
    get_involved: false,
    newsletter_subscribed: true,
    create_user_account: true,
    user_password: "password123",
    membership_type: basic_type
  },
  
  # Artistes internationaux
  {
    first_name: "Maria",
    last_name: "Rodriguez",
    email: "maria.rodriguez@international.fr",
    phone: "+33999000111",
    address: "34 Rue de Belleville, 75019 Paris",
    birth_date: 30.years.ago.to_date,
    occupation: "Artiste internationale",
    specialty: "Flamenco",
    image_rights: true,
    get_involved: true,
    newsletter_subscribed: true,
    create_user_account: true,
    user_password: "password123",
    membership_type: circus_full_type,
    subscription_plan: annuel_plan
  },
  {
    first_name: "Giuseppe",
    last_name: "Rossi",
    email: "giuseppe.rossi@international.fr",
    phone: "+33111222333",
    address: "56 Avenue des Ternes, 75017 Paris",
    birth_date: 34.years.ago.to_date,
    occupation: "Artiste italien",
    specialty: "Mime",
    image_rights: true,
    get_involved: true,
    newsletter_subscribed: false,
    create_user_account: true,
    user_password: "password123",
    membership_type: circus_full_type,
    subscription_plan: trimestre_plan
  }
]

success_count = 0
error_count = 0

test_people.each do |person_attrs|
  begin
    # Extraire les attributs pour le service et les données supplémentaires
    membership_type = person_attrs.delete(:membership_type)
    subscription_plan = person_attrs.delete(:subscription_plan)
    
    # Ajouter user_email si create_user_account est true
    if person_attrs[:create_user_account] && person_attrs[:email]
      person_attrs[:user_email] = person_attrs[:email]
    end

    # Créer la personne avec le service
    register_service = People::Register.new(person_attrs)
    result = register_service.call

    if result.success?
      person = result.person
      puts "  ✅ #{person.full_name} (#{person.email})"

      # Créer une adhésion selon les attributs
      if membership_type
        membership = Membership.create!(
          person: person,
          membership_type: membership_type,
          started_at: rand(1..6).months.ago,
          ended_at: rand(6..12).months.from_now,
          status: :active,
          first_joined_at: rand(1..6).months.ago
        )
        puts "    📋 Adhésion: #{membership.membership_type.name}"

        # Créer le paiement correspondant à l'adhésion
        admin_user = User.find_by(system_role: :super_admin)
        payment = Payment.create!(
          person: person,
          recorded_by: admin_user,
          total_cents: membership_type.price_cents,
          payment_method: "cash",
          status: "success",
          notes: "Paiement pour adhésion #{membership_type.name} (seed data)"
        )

        # Créer la ligne de paiement
        PaymentLine.create!(
          payment: payment,
          item: membership,
          amount_cents: membership_type.price_cents,
          description: "Adhésion #{membership_type.name}"
        )

        # Traiter le paiement
        Payments::Process.new(payment).call if defined?(Payments::Process)
        puts "    💰 Paiement: #{payment.total_cents / 100.0}€ (#{payment.payment_method})"
      end

      # Créer un carnet d'entrées si spécifié
      if subscription_plan
        sessions_remaining = case subscription_plan.duration.to_s
                           when 'pack10'
                             rand(1..10)
                           when 'quarterly'
                             rand(10..20)
                           when 'annual'
                             rand(20..50)
                           else
                             5
                           end

        book_of_entry = BookOfEntry.create!(
          person: person,
          subscription_plan: subscription_plan,
          sessions_remaining: sessions_remaining,
          status: :active,
          purchased_at: rand(1..3).months.ago,
          expires_at: rand(6..12).months.from_now
        )
        puts "    📚 Carnet: #{book_of_entry.subscription_plan.name} (#{book_of_entry.sessions_remaining} séances restantes)"

        # Créer le paiement correspondant au carnet
        admin_user = User.find_by(system_role: :super_admin)
        payment = Payment.create!(
          person: person,
          recorded_by: admin_user,
          total_cents: subscription_plan.price_cents,
          payment_method: "cash",
          status: "success",
          notes: "Paiement pour #{subscription_plan.name} (seed data)"
        )

        # Créer la ligne de paiement
        PaymentLine.create!(
          payment: payment,
          item: book_of_entry,
          amount_cents: subscription_plan.price_cents,
          description: subscription_plan.name
        )

        # Traiter le paiement
        Payments::Process.new(payment).call if defined?(Payments::Process)
        puts "    💰 Paiement carnet: #{payment.total_cents / 100.0}€ (#{payment.payment_method})"
      end

      # Créer quelques présences de test (entre 0 et 5)
      num_attendances = rand(0..5)
      events = Event.all.sample(num_attendances)
      events.each_with_index do |event, index|
        attendance = Attendance.create!(
          person: person,
          event: event,
          date: event.date - rand(0..30).days
        )
      end
      puts "    📅 Présences: #{person.attendances.count}"

      success_count += 1
    else
      puts "  ❌ Erreur pour #{person_attrs[:first_name]} #{person_attrs[:last_name]}: #{result.message}"
      error_count += 1
    end
  rescue => e
    puts "  ❌ Exception pour #{person_attrs[:first_name]} #{person_attrs[:last_name]}: #{e.message}"
    error_count += 1
  end
end

puts "🎉 Created #{success_count} test people with memberships and attendances"
puts "⚠️  #{error_count} errors encountered" if error_count > 0
