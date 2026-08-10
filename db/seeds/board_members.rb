BoardMember.destroy_all

board_members_data = [
  {
    name: "Léa Martin",
    role: "Présidente",
    bio: "Trapéziste et coordinatrice d'événements culturels.",
    display_order: 1,
    instagram_url: "https://instagram.com/lea.circographe",
    linkedin_url: "https://linkedin.com/in/lea-martin"
  },
  {
    name: "Sofiane Dupont",
    role: "Vice-président",
    bio: "Graphiste et scénographe, passionné par la typographie.",
    display_order: 2,
    instagram_url: "https://instagram.com/sofiane.graphiste"
  },
  {
    name: "Anouk Vidal",
    role: "Trésorière",
    bio: "Responsable administratif et jongleuse multi-instrument.",
    display_order: 3,
    linkedin_url: "https://linkedin.com/in/anouk-vidal"
  },
  {
    name: "Marc Lemaire",
    role: "Secrétaire",
    bio: "Technicien plateau et photographe de la scène toulousaine.",
    display_order: 4
  },
  {
    name: "Julie Carmes",
    role: "Membre CA",
    bio: "Illustratrice et animatrice d'ateliers jeune public.",
    display_order: 5,
    behance_url: "https://behance.net/julie-carmes"
  },
  {
    name: "Marius Conti",
    role: "Membre CA",
    bio: "Voltigeur, responsable sécurité et planning.",
    display_order: 6
  }
]

board_members_data.each { |attrs| BoardMember.create!(attrs) }
puts "  #{BoardMember.count} membres du CA créés."
