# Nettoyage des données existantes
ActiveRecord::Base.connection.disable_referential_integrity do
  PriceEntry.destroy_all
  PriceCatalog.destroy_all
  Product.destroy_all
  Membership.destroy_all
  User.destroy_all
  Tag.destroy_all
  Tag.destroy_all
end

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
puts "\nBienvenue dans la seed du Circographe!\n\n"

# Création des utilisateurs avec différents rôles système
puts "Creating users with different roles..."

# Administrateur
User.create!(
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
User.create!(
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
User.create!(
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

# Création de plusieurs guests
650.times do |i|
  User.create!(
    email_address: "guest#{i+1}@rails.com",
    password: "123456",
    password_confirmation: "123456",
    first_name: "Guest",
    last_name: "User#{i+1}",
    system_role: 3,  # Supposant que 3 = guest (valeur par défaut)
    birthdate: Date.new(2000, 1, 1) + i.years,
    address: "#{i+1} Guest Street",
    zip_code: "7500#{i}",
    town: "Paris",
    country: "France",
    phone_number: "+3312345679#{i}",
    newsletter_subscribed: i < 70  # Les 7 premiers guests sont inscrits à la newsletter
  )
end

# Créer les types de membership par défaut s'ils n'existent pas
[ :No_Member, :Basic, :Circus ].each do |type|
  Membership.find_or_create_by!(type_name: type)
end

puts "Seed completed! Created:"
puts "- 1 Admin (admin@rails.com)"
puts "- 1 Staff (staff@rails.com)"
puts "- 1 Member (member@rails.com)"
puts "- 10 Guests (guest1@rails.com through guest10@rails.com)"
puts "All passwords are set to: 123456"



puts "Suppression des données existantes... OK"

price_catalogs = [
  { active: true, price: 1.0 },
  { active: true, price: 10.0 },
  { active: true, price: 7.0 },
  { active: true, price: 9.0 },
  { active: true, price: 6.0 },
  { active: true, price: 4.0 },
  { active: true, price: 30.0 },
  { active: true, price: 65.0 },
  { active: true, price: 150.0 },
  { active: true, price: 0.0 }
]

puts "Création des tarifs..."
price_catalogs.each do |price_catalog|
  PriceCatalog.create!(active: price_catalog[:active], price: price_catalog[:price])
end
puts PriceCatalog.first.inspect

products = [
  { product_name: "Adhésion simple", product_type: "adhesion" },
  { product_name: "Adhésion Cirque - Tarif Plein", product_type: "adhesion" },
  { product_name: "Adhésion Cirque - Tarif Réduit", product_type: "adhesion" },
  { product_name: "Upgrade Basic to Cirque - Tarif Plein", product_type: "cotisation" },
  { product_name: "Upgrade Basic to Cirque - Tarif Réduit", product_type: "cotisation" },
  { product_name: "Pass journée", product_type: "cotisation" },
  { product_name: "Cotisation 10 séances", product_type: "cotisation" },
  { product_name: "Cotisation trimestrielle", product_type: "cotisation" },
  { product_name: "Cotisation annuelle", product_type: "cotisation" }
]
puts "Création des produits..."

created_price_catalogs = PriceCatalog.all

products.each_with_index do |product, index|
  price_catalog = created_price_catalogs[index]

  p = Product.create!(
    product_name: product[:product_name],
    product_type: product[:product_type],
    price_catalogs: [ price_catalog ]
  )
  puts "Produit créé : #{p.product_name} (#{p.product_type}) au prix de #{price_catalog.price}"
end

puts "\nTous les objets ont été créés avec succès !"

# Création des événements
puts "\nCreating events..."

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

# Récupération d'un utilisateur admin pour creator_id
admin_user = User.find_by(system_role: 0)

events.each do |event_data|
  event = Event.find_or_create_by!(title: event_data[:title]) do |e|
    e.upper_description = event_data[:upper_description]
    e.middle_description = event_data[:middle_description]
    e.bottom_description = event_data[:bottom_description]
    e.location = event_data[:location]
    e.date = event_data[:date]
    e.picture_url = event_data[:picture_url]
    e.creator_id = admin_user.id
  end
end

puts "Seeds completed! Created:"
puts "- #{Product.count} products"
puts "- #{PriceEntry.count} price entries"
puts "- #{Event.count} events"

tags = %i[ evenement article newslister]
tags.each do |tag|
  Tag.create(name: tag.to_s)
end

# pour pouvoir afficher les images executer en consol :
# sudo apt install libvips
# pour modifier comment l'image qui s affiche pour les fronteux, c'est dans app/views/active_storage/blobs/_blob.html.erb