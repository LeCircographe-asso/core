# Seed pour les événements
puts "\n📅 Creating sample events..."

# Récupérer l'admin comme créateur
admin_user = User.find_by(system_role: "super_admin")

events = [
  {
    name: "Spectacle de Cirque",
    category: "show",
    date: 1.week.from_now,
    location: "Salle de spectacle",
    description: "Spectacle de fin d'année avec tous les élèves",
    creator: admin_user
  },
  {
    name: "Atelier Jonglage",
    category: "workshop",
    date: 3.days.from_now,
    location: "Salle de jonglage",
    description: "Atelier découverte du jonglage pour débutants",
    creator: admin_user
  },
  {
    name: "Atelier Équilibre",
    category: "workshop",
    date: 1.week.from_now + 1.day,
    location: "Salle d'équilibre",
    description: "Atelier équilibre sur boule et fil",
    creator: admin_user
  }
]

events.each do |attrs|
  event = Event.create!(attrs)
  puts "  ✅ #{event.name} (#{event.category}) - #{event.date.strftime('%d/%m/%Y')}"
end

puts "🎉 Created #{Event.count} events"
