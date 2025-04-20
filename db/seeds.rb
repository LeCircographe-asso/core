# Nettoyage des données existantes
puts "🧹 Cleaning database..."
ActiveRecord::Base.connection.disable_referential_integrity do
  # L'ordre est important pour éviter les problèmes de callbacks
  print "  - Deleting payment audit logs... "
  count = PaymentAuditLog.delete_all
  puts "#{count} deleted ✓"

  print "  - Deleting event attendees... "
  count = EventAttendee.delete_all
  puts "#{count} deleted ✓"

  print "  - Deleting attendances... "
  count = Attendance.delete_all
  puts "#{count} deleted ✓"

  print "  - Deleting books of entry... "
  count = BookOfEntry.delete_all
  puts "#{count} deleted ✓"

  print "  - Deleting payments... "
  count = Payment.delete_all
  puts "#{count} deleted ✓"

  print "  - Deleting product orders... "
  count = ProductOrder.delete_all
  puts "#{count} deleted ✓"

  print "  - Deleting orders... "
  count = Order.delete_all
  puts "#{count} deleted ✓"

  print "  - Deleting user memberships... "
  count = UserMembership.delete_all
  puts "#{count} deleted ✓"

  print "  - Deleting price entries... "
  count = PriceEntry.delete_all
  puts "#{count} deleted ✓"

  print "  - Deleting price catalogs... "
  count = PriceCatalog.delete_all
  puts "#{count} deleted ✓"

  print "  - Deleting products... "
  count = Product.delete_all
  puts "#{count} deleted ✓"

  print "  - Deleting memberships... "
  count = Membership.delete_all
  puts "#{count} deleted ✓"

  print "  - Deleting users... "
  count = User.delete_all
  puts "#{count} deleted ✓"

  print "  - Deleting tags... "
  count = Tag.delete_all
  puts "#{count} deleted ✓"

  print "  - Deleting events... "
  count = Event.delete_all
  puts "#{count} deleted ✓"
end
puts "✅ Database cleaned successfully"

# Le Circographe ASCII Art Logo
puts %(
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣤⡶⠿⠿⠷⣶⣄⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⡿⠁⠀⠀⢀⣀⡀⠙⣷⡀⠀⠀⠀
⠀⠀⠀⡀⠀⠀⠀⠀⠀⢠⣿⠁⠀⠀⠀⠘⠿⠃⠀⢸⣿⣿⣿⣿
⠀⣠⡿⠛⢷⣦⡀⠀⠀⠈⣿⡄⠀⠀⠀⠀⠀⠀⠀⣸⣿⣿⣿⠟
⢰⡿⠁⠀⠀⠙⢿⣦⣤⣤⣼⣿⣄⠀⠀⠀⠀⠀⢴⡟⠛⠋⠁⠀
⣿⠇⠀⠀⠀⠀⠀⠉⠉⠉⠉⠉⠁⠀⠀⠀⠀⠀⠈⣿⡀⠀⠀⠀
⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢹⡇⠀⠀⠀
⣿⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⡇⠀⠀⠀
⠸⣷⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⡿⠀⠀⠀⠀
⠀⠹⣷⣤⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣰⡿⠁⠀⠀⠀⠀
⠀⠀⠀⠉⠙⠛⠿⠶⣶⣶⣶⣶⣶⠶⠿⠟⠛⠉⠀⠀⠀⠀⠀⠀
)
puts "\n🎪 Bienvenue dans la seed du Circographe! 🎪\n\n"

# Création des utilisateurs avec différents rôles système
puts "👥 Creating users with different roles..."

# Administrateur
puts "  - Creating Super Admin user..."
admin_user = User.create!(
  email_address: "super_admin@rails.com",
  password: "123456",
  password_confirmation: "123456",
  first_name: "Admin",
  last_name: "User",
  system_role: 0,  # 0 = super_admin
  birthdate: Date.new(1990, 1, 1),
  address: "123 Admin Street",
  zip_code: "75000",
  town: "Paris",
  country: "France",
  phone_number: "+33123456789"
)

# admin
puts "  - Creating Admin user..."
staff_user = User.create!(
  email_address: "admin@rails.com",
  password: "123456",
  password_confirmation: "123456",
  first_name: "Staff",
  last_name: "User",
  system_role: 1,  # 1 = admin
  birthdate: Date.new(1992, 2, 2),
  address: "456 Staff Avenue",
  zip_code: "75001",
  town: "Paris",
  country: "France",
  phone_number: "+33123456790"
)

# Membre
puts "  - Creating Member user..."
member_user = User.create!(
  email_address: "member@rails.com",
  password: "123456",
  password_confirmation: "123456",
  first_name: "Member",
  last_name: "User",
  system_role: 2,  # Supposant que 2 = member
  birthdate: Date.new(1995, 5, 5),
  address: "789 Member Road",
  zip_code: "75002",
  town: "Paris",
  country: "France",
  phone_number: "+33123456791"
)

# Création du reste des utilisateurs pour avoir un total de 750
puts "👤 Creating additional users to reach 750 total..."
total = 747
progress_step = total / 10  # Show progress every 10%
progress_step = 1 if progress_step < 1

747.times do |i|
  # Show progress every 10%
  if (i % progress_step) == 0
    percent = ((i.to_f / total) * 100).round
    print "\r  Progress: #{percent}% (#{i}/#{total})"
  end

  User.create!(
    email_address: "guest#{i+1}@rails.com",
    password: "123456",
    password_confirmation: "123456",
    first_name: "Guest",
    last_name: "User#{i+1}",
    system_role: 3,  # 3 = guest (valeur par défaut)
    birthdate: Date.new(2000, 1, 1) + i.days,
    address: "#{i+1} Guest Street",
    zip_code: "7500#{i % 10}",
    town: "Paris",
    country: "France",
    phone_number: "+331234567#{i.to_s.rjust(3, '0')}",
    newsletter_subscribed: i < 100  # Les 100 premiers sont inscrits à la newsletter
  )
end
puts "\r  Progress: 100% (#{total}/#{total}) ✓"
puts "✅ Total users created: #{User.count}"

# Créer les types de membership
puts "🎭 Creating membership types..."
memberships = []
[ :No_Member, :Basic, :Circus ].each do |type|
  print "  - Creating #{type} membership type... "
  membership = Membership.create!(type_name: Membership.type_names[type])
  memberships << membership
  puts "Done ✓"
end

# Récupérer les types de membership pour référence
no_member = memberships[0]
basic = memberships[1]
circus = memberships[2]

# Création des produits et catalogues de prix selon la documentation
puts "💰 Creating price catalogs and products..."
price_catalogs = [
  { active: true, price: 1.0 },    # Basic membership - 1€/an
  { active: true, price: 10.0 },   # Cirque membership tarif plein - 10€/an
  { active: true, price: 7.0 },    # Cirque membership tarif réduit - 7€/an
  { active: true, price: 9.0 },    # Upgrade Basic to Cirque tarif plein
  { active: true, price: 6.0 },    # Upgrade Basic to Cirque tarif réduit
  { active: true, price: 4.0 },    # Pass Journée - 4€
  { active: true, price: 30.0 },   # Carnet 10 Séances - 30€
  { active: true, price: 65.0 },   # Abonnement Trimestriel - 65€
  { active: true, price: 150.0 },  # Abonnement Annuel - 150€
  { active: true, price: 0.0 }     # Gratuit (pour certains événements)
]

created_price_catalogs = []
price_catalogs.each_with_index do |price_catalog, index|
  print "  - Creating price catalog #{index+1} (#{price_catalog[:price]}€)... "
  catalog = PriceCatalog.create!(active: price_catalog[:active], price: price_catalog[:price])
  created_price_catalogs << catalog
  puts "Done ✓"
end

# Création des produits selon la documentation
products = [
  { product_name: "Basic", product_type: "adhesion" },
  { product_name: "Cirque - Tarif Plein", product_type: "adhesion" },
  { product_name: "Cirque - Tarif Réduit", product_type: "adhesion" },
  { product_name: "Upgrade Basic to Cirque - Tarif Plein", product_type: "cotisation" },
  { product_name: "Upgrade Basic to Cirque - Tarif Réduit", product_type: "cotisation" },
  { product_name: "Pass journée", product_type: "cotisation" },
  { product_name: "10 séances", product_type: "cotisation" },
  { product_name: "Trimestrielle", product_type: "cotisation" },
  { product_name: "Annuelle", product_type: "cotisation" }
]

created_products = {}
products.each_with_index do |product, index|
  price_catalog = created_price_catalogs[index]
  print "  - Creating product #{product[:product_name]} (#{price_catalog.price}€)... "
  p = Product.create!(
    product_name: product[:product_name],
    product_type: product[:product_type],
    price_catalogs: [ price_catalog ]
  )
  created_products[product[:product_name]] = p
  puts "Done ✓"
end

# Distribuer les adhésions aux utilisateurs
puts "🔑 Creating user memberships..."
users = User.all.to_a
membership_statuses = UserMembership.statuses.keys

# 1. Création d'adhésions Basic pour une partie des utilisateurs (300)
puts "  - Creating 300 Basic memberships..."
basic_users = users.sample(300)
total = basic_users.size
progress_step = total / 10  # Show progress every 10%
progress_step = 1 if progress_step < 1

basic_users.each_with_index do |user, idx|
  # Show progress every 10%
  if (idx % progress_step) == 0
    percent = ((idx.to_f / total) * 100).round
    print "\r    Progress: #{percent}% (#{idx}/#{total})"
  end

  start_date = Date.today - rand(1..300).days
  end_date = start_date + 1.year

  UserMembership.create!(
    user: user,
    membership: basic,
    start_date: start_date,
    end_date: end_date,
    status: membership_statuses.sample
  )
end
puts "\r    Progress: 100% (#{total}/#{total}) ✓"

# 2. Création d'adhésions Cirque pour certains utilisateurs ayant déjà Basic (150)
# Selon la documentation: "Une adhésion Cirque nécessite une adhésion Basic valide"
puts "  - Creating 150 Cirque memberships..."
circus_users = basic_users.sample(150)
total = circus_users.size
progress_step = total / 10  # Show progress every 10%
progress_step = 1 if progress_step < 1

circus_users.each_with_index do |user, idx|
  # Show progress every 10%
  if (idx % progress_step) == 0
    percent = ((idx.to_f / total) * 100).round
    print "\r    Progress: #{percent}% (#{idx}/#{total})"
  end

  # Récupérer les dates de l'adhésion Basic pour s'assurer de la cohérence
  basic_membership = UserMembership.find_by(user: user, membership: basic)

  start_date = basic_membership.start_date + rand(5..30).days
  end_date = start_date + 1.year

  UserMembership.create!(
    user: user,
    membership: circus,
    start_date: start_date,
    end_date: end_date,
    status: membership_statuses.sample
  )
end
puts "\r    Progress: 100% (#{total}/#{total}) ✓"
puts "✅ Total memberships created: #{UserMembership.count} (#{UserMembership.where(membership: basic).count} Basic, #{UserMembership.where(membership: circus).count} Cirque)"

# Création des commandes et paiements
puts "💳 Creating orders, product orders, and payments..."

# 1. Achats d'adhésions Basic
puts "  - Creating Basic membership purchases..."
total = basic_users.size
progress_step = total / 10  # Show progress every 10%
progress_step = 1 if progress_step < 1

basic_users.each_with_index do |user, idx|
  # Show progress every 10%
  if (idx % progress_step) == 0
    percent = ((idx.to_f / total) * 100).round
    print "\r    Progress: #{percent}% (#{idx}/#{total})"
  end

  basic_membership = UserMembership.find_by(user: user, membership: basic)

  # Créer une commande pour l'adhésion Basic
  order = Order.create!(
    user: user,
    date: basic_membership.start_date - rand(1..5).days,
    sum: 1.0,  # Prix fixe de l'adhésion Basic (1€)
    donation: rand < 0.3 ? rand(1..20).to_f : 0.0
  )

  # Ajouter le produit à la commande
  ProductOrder.create!(
    product: created_products["Basic"],
    order: order,
    user: user
  )

  # Créer un paiement
  payment_date = order.date + rand(0..2).days
  total_payment = order.sum + order.donation

  payment = Payment.create!(
    user: user,
    order: order,
    payment_date: payment_date,
    payment_amount: order.sum,
    donation: order.donation,
    total_payment: total_payment,
    payment_type: Payment.payment_types.keys.sample,
    status: Payment.statuses.keys.sample,
    uuid: SecureRandom.uuid
  )

  # Log d'audit pour certains paiements
  if rand < 0.2
    PaymentAuditLog.create!(
      payment: payment,
      user: [ admin_user, staff_user ].sample,
      action: [ "created", "updated", "status_changed" ].sample,
      change_data: { old_status: "pending", new_status: "completed" }.to_json
    )
  end
end
puts "\r    Progress: 100% (#{total}/#{total}) ✓"

# 2. Achats d'adhésions Cirque
puts "  - Creating Cirque membership purchases..."
total = circus_users.size
progress_step = total / 10  # Show progress every 10%
progress_step = 1 if progress_step < 1

circus_users.each_with_index do |user, idx|
  # Show progress every 10%
  if (idx % progress_step) == 0
    percent = ((idx.to_f / total) * 100).round
    print "\r    Progress: #{percent}% (#{idx}/#{total})"
  end

  circus_membership = UserMembership.find_by(user: user, membership: circus)

  # Déterminer le tarif (plein ou réduit)
  is_reduced = rand < 0.3 # 30% chance for reduced price
  product_name = is_reduced ? "Cirque - Tarif Réduit" : "Cirque - Tarif Plein"
  price = is_reduced ? 7.0 : 10.0

  # Créer une commande
  order = Order.create!(
    user: user,
    date: circus_membership.start_date - rand(1..5).days,
    sum: price,
    donation: rand < 0.3 ? rand(1..20).to_f : 0.0
  )

  # Ajouter le produit à la commande
  ProductOrder.create!(
    product: created_products[product_name],
    order: order,
    user: user
  )

  # Créer un paiement
  payment_date = order.date + rand(0..2).days
  total_payment = order.sum + order.donation

  payment = Payment.create!(
    user: user,
    order: order,
    payment_date: payment_date,
    payment_amount: order.sum,
    donation: order.donation,
    total_payment: total_payment,
    payment_type: Payment.payment_types.keys.sample,
    status: Payment.statuses.keys.sample,
    uuid: SecureRandom.uuid
  )

  # Log d'audit pour certains paiements
  if rand < 0.2
    PaymentAuditLog.create!(
      payment: payment,
      user: [ admin_user, staff_user ].sample,
      action: [ "created", "updated", "status_changed" ].sample,
      change_data: { old_status: "pending", new_status: "completed" }.to_json
    )
  end
end
puts "\r    Progress: 100% (#{total}/#{total}) ✓"

# 3. Achats de cotisations (uniquement pour les membres Cirque)
puts "  - Creating cotisations for Cirque members (120 users)..."
cotisation_users = circus_users.sample(120)
total = cotisation_users.size
progress_step = total / 10  # Show progress every 10%
progress_step = 1 if progress_step < 1

cotisation_count = { pass: 0, carnet: 0, trimestre: 0, annuel: 0 }

cotisation_users.each_with_index do |user, idx|
  # Show progress every 10%
  if (idx % progress_step) == 0
    percent = ((idx.to_f / total) * 100).round
    print "\r    Progress: #{percent}% (#{idx}/#{total})"
  end

  # Choisir un type de cotisation
  cotisation_type = rand(4)
  product_name = ""
  price = 0.0

  case cotisation_type
  when 0 # Pass journée
    product_name = "Pass journée"
    price = 4.0
    cotisation_count[:pass] += 1
  when 1 # 10 séances
    product_name = "10 séances"
    price = 30.0
    cotisation_count[:carnet] += 1
  when 2 # Trimestrielle
    product_name = "Trimestrielle"
    price = 65.0
    cotisation_count[:trimestre] += 1
  when 3 # Annuelle
    product_name = "Annuelle"
    price = 150.0
    cotisation_count[:annuel] += 1
  end

  # Créer une commande
  order_date = Date.today - rand(1..180).days
  order = Order.create!(
    user: user,
    date: order_date,
    sum: price,
    donation: rand < 0.3 ? rand(1..20).to_f : 0.0
  )

  # Ajouter le produit à la commande
  ProductOrder.create!(
    product: created_products[product_name],
    order: order,
    user: user
  )

  # Créer un paiement
  payment_date = order.date + rand(0..3).days
  total_payment = order.sum + order.donation

  payment = Payment.create!(
    user: user,
    order: order,
    payment_date: payment_date,
    payment_amount: order.sum,
    donation: order.donation,
    total_payment: total_payment,
    payment_type: Payment.payment_types.keys.sample,
    status: Payment.statuses.keys.sample,
    uuid: SecureRandom.uuid
  )

  # Certains paiements ont des échéances pour les abonnements trimestriels/annuels
  if (cotisation_type == 2 || cotisation_type == 3) && rand < 0.4
    # Log d'audit pour les paiements échelonnés
    PaymentAuditLog.create!(
      payment: payment,
      user: [ admin_user, staff_user ].sample,
      action: "installment_created",
      change_data: { installments: "3", schedule: "monthly" }.to_json
    )
  end

  # Créer un carnet d'entrées pour les cotisations de type carnet ou pass
  if cotisation_type <= 1
    remaining = cotisation_type == 0 ? 1 : 10 # Pass journée = 1 entrée, Carnet = 10 entrées

    BookOfEntry.create!(
      product: created_products[product_name],
      user: user,
      remaining: remaining,
      total_entry: remaining,
      status: BookOfEntry.statuses.keys.sample
    )
  end
end
puts "\r    Progress: 100% (#{total}/#{total}) ✓"
puts "    Distribution: #{cotisation_count[:pass]} Pass journée, #{cotisation_count[:carnet]} Carnets 10 séances, #{cotisation_count[:trimestre]} Abonnements trimestriels, #{cotisation_count[:annuel]} Abonnements annuels"
puts "✅ Created: #{Order.count} orders, #{Payment.count} payments, #{ProductOrder.count} product orders, #{BookOfEntry.count} books of entry"

# Création des événements
puts "🎪 Creating events..."
events = [
  {
    title: "Festival de Cirque d'Été",
    upper_description: "Grand festival annuel avec spectacles de cirque en plein air",
    middle_description: "Trois jours de festivités avec des artistes internationaux",
    bottom_description: "Spectacles, ateliers et animations pour toute la famille",
    location: "Parc des Expositions",
    date: Date.today + 2.months,
    picture_url: nil
  },
  {
    title: "Atelier Jonglage Débutant",
    upper_description: "Initiation aux techniques de base du jonglage",
    middle_description: "Apprenez les bases de la jonglerie avec des professionnels",
    bottom_description: "Matériel fourni - Tous niveaux bienvenus",
    location: "Salle d'entraînement principale",
    date: Date.today + 2.weeks,
    picture_url: nil
  },
  {
    title: "Stage Acrobatie Aérienne",
    upper_description: "Stage intensif de tissus aériens et trapèze",
    middle_description: "Formation complète sur les techniques aériennes",
    bottom_description: "Prérequis : niveau intermédiaire en acrobatie",
    location: "Chapiteau Central",
    date: Date.today + 1.month,
    picture_url: nil
  },
  {
    title: "Spectacle 'Rêves en Piste'",
    upper_description: "Nouveau spectacle mêlant cirque contemporain et arts numériques",
    middle_description: "Une expérience immersive unique",
    bottom_description: "Durée : 2h avec entracte",
    location: "Théâtre Municipal",
    date: Date.today + 3.weeks,
    picture_url: nil
  },
  {
    title: "Master Class Clown",
    upper_description: "Master class exceptionnelle avec un artiste de renommée internationale",
    middle_description: "Découvrez l'art du clown contemporain",
    bottom_description: "Places limitées - Sur inscription uniquement",
    location: "Studio de création",
    date: Date.today + 45.days,
    picture_url: nil
  }
]

created_events = []
events.each do |event_data|
  print "  - Creating event '#{event_data[:title]}'... "
  event = Event.create!(
    title: event_data[:title],
    upper_description: event_data[:upper_description],
    middle_description: event_data[:middle_description],
    bottom_description: event_data[:bottom_description],
    location: event_data[:location],
    date: event_data[:date],
    picture_url: event_data[:picture_url],
    creator_id: admin_user.id
  )
  created_events << event
  puts "Done ✓"
end

# Participants aux événements (ouverts à tous, membres ou non)
puts "🎟️ Creating event attendees (200 participants)..."
# Mélanger tous les utilisateurs pour les inscriptions aux événements
all_attendees = users.sample(200)
total = all_attendees.size
progress_step = total / 10  # Show progress every 10%
progress_step = 1 if progress_step < 1

paid_count = 0
free_count = 0

all_attendees.each_with_index do |user, idx|
  # Show progress every 10%
  if (idx % progress_step) == 0
    percent = ((idx.to_f / total) * 100).round
    print "\r  Progress: #{percent}% (#{idx}/#{total})"
  end

  event = created_events.sample

  # Certains événements sont payants
  payment = nil
  if rand < 0.4  # 40% des inscriptions sont payantes
    paid_count += 1
    # Créer une commande pour l'événement
    order = Order.create!(
      user: user,
      date: Date.today - rand(1..30).days,
      sum: rand(5..20).to_f,
      donation: rand < 0.3 ? rand(1..10).to_f : 0.0
    )

    payment_date = order.date + rand(0..2).days
    total_payment = order.sum + order.donation

    payment = Payment.create!(
      user: user,
      order: order,
      payment_date: payment_date,
      payment_amount: order.sum,
      donation: order.donation,
      total_payment: total_payment,
      payment_type: Payment.payment_types.keys.sample,
      status: Payment.statuses.keys.sample,
      uuid: SecureRandom.uuid
    )
  else
    free_count += 1
  end

  EventAttendee.create!(
    user: user,
    event: event,
    payment: payment,
    interested: payment.nil? ? [ true, false ].sample : true
  )
end
puts "\r  Progress: 100% (#{total}/#{total}) ✓"
puts "  Distribution: #{paid_count} paid registrations, #{free_count} free registrations"

# Création des listes de présence et des présences
puts "📋 Creating attendance lists and attendances..."
list_types = AttendanceList.list_types.keys
list_statuses = AttendanceList.statuses.keys

# Créer 10 listes de présence
puts "  - Creating 10 attendance lists..."
attendance_lists = []
10.times do |i|
  print "    - Creating list #{i+1}... "
  start_date = Date.today - rand(1..90).days
  end_date = start_date + rand(1..7).days

  attendance_list = AttendanceList.create!(
    name: "Liste #{i+1} - #{start_date.strftime('%d/%m/%Y')}",
    start_date: start_date,
    end_date: end_date,
    list_type: list_types.sample,
    status: list_statuses.sample
  )
  attendance_lists << attendance_list
  puts "Done ✓"
end

puts "  - Creating attendances for each list..."
total_attendances = 0

attendance_lists.each_with_index do |attendance_list, list_idx|
  # Ajouter des présences - principalement pour les membres Cirque
  # qui ont des carnets ou des abonnements
  attendees_count = rand(10..40)
  total_attendances += attendees_count

  print "    - List #{list_idx+1}: Adding #{attendees_count} attendances... "

  # Priorité aux membres Cirque avec cotisations
  potential_attendees = circus_users.shuffle

  attendees_count.times do |j|
    user = j < circus_users.length ? potential_attendees[j] : users.sample

    # Vérifier si l'utilisateur a un carnet d'entrées
    book_of_entry = BookOfEntry.where(user: user).where("remaining > 0").sample

    Attendance.create!(
      user: user,
      attendance_list: attendance_list,
      book_of_entry: book_of_entry,
      arrival_time: attendance_list.start_date + rand(9..21).hours + rand(0..59).minutes
    )

    # Décrémenter les entrées restantes si c'est un carnet
    if book_of_entry && book_of_entry.product.product_name == "10 séances"
      book_of_entry.update(remaining: book_of_entry.remaining - 1)
    end
  end
  puts "Done ✓"
end
puts "  Total attendances created: #{total_attendances}"

# Création des tags
puts "🏷️ Creating tags..."
tags = %i[evenement article newsletter atelier spectacle festival formation]
created_tags = []
tags.each do |tag|
  print "  - Creating tag '#{tag}'... "
  created_tags << Tag.create!(name: tag.to_s)
  puts "Done ✓"
end

puts "\n✅ Seed completed! Here's what was created:"
puts "--------------------------------------------"
puts "👥 USERS:"
puts "  - #{User.count} total users"
puts "    - 1 Super Admin: super_admin@rails.com / 123456"
puts "    - 1 Admin: admin@rails.com / 123456"
puts "    - 1 Member: member@rails.com / 123456"
puts "    - #{User.count - 3} Guests: guest1@rails.com through guest#{User.count - 3}@rails.com / 123456"
puts "    - #{User.where(newsletter_subscribed: true).count} users subscribed to newsletter"

puts "🎭 MEMBERSHIPS:"
puts "  - #{Membership.count} membership types"
puts "  - #{UserMembership.count} user memberships"
puts "    - #{UserMembership.where(membership: basic).count} Basic memberships"
puts "    - #{UserMembership.where(membership: circus).count} Cirque memberships"

puts "💰 PRODUCTS AND PAYMENTS:"
puts "  - #{Product.count} products"
puts "  - #{PriceCatalog.count} price catalogs"
puts "  - #{Order.count} orders"
puts "  - #{Payment.count} payments"
puts "  - #{PaymentAuditLog.count} payment audit logs"
puts "  - #{BookOfEntry.count} books of entry"

puts "🎪 EVENTS:"
puts "  - #{Event.count} events"
puts "  - #{EventAttendee.count} event attendees"
puts "    - #{EventAttendee.joins(:payment).count} paid registrations"
puts "    - #{EventAttendee.where(payment_id: nil).count} free registrations"

puts "📋 ATTENDANCE:"
puts "  - #{AttendanceList.count} attendance lists"
puts "  - #{Attendance.count} attendances"

puts "🏷️ OTHER:"
puts "  - #{Tag.count} tags"

# pour pouvoir afficher les images executer en consol :
# sudo apt install libvips
# pour modifier comment l'image qui s affiche pour les fronteux, c'est dans app/views/active_storage/blobs/_blob.html.erb
