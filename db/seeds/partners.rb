Partner.destroy_all

partners_data = [
  {
    name: "La Grainerie",
    display_order: 1,
    category: "Lieu associé",
    url: "https://www.la-grainerie.net",
    bio: "Fabrique partagée pour les arts du cirque et les projets hybrides en région toulousaine."
  },
  {
    name: "Le Cirque Pep's",
    display_order: 2,
    category: "Compagnie",
    initials: "CP",
    bio: "Rencontres, ateliers et énergie circassienne au service du lieu et du public."
  },
  {
    name: "Le Zmam",
    display_order: 3,
    category: "Projet & lieu",
    initials: "LZ",
    bio: "Échanges et collaborations qui nourrissent la vie collective du Circographe."
  },
  {
    name: "Notre crêpier·e partenaire",
    display_order: 4,
    category: "Convivialité",
    initials: "Cr",
    bio: "Présent·e sur nos temps forts pour partager un goûter entre deux créneaux et animer la buvette."
  }
]

partners_data.each { |attrs| Partner.create!(attrs) }
puts "  #{Partner.count} partenaires créés."
