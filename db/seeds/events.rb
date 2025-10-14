# Seeds pour les événements
puts "📅 Creating events..."

# Récupérer un utilisateur admin
admin_user = User.first || User.create!(
  first_name: "Admin",
  last_name: "System",
  email: "admin@circographe.com",
  password: "password123",
  password_confirmation: "password123"
)

events = [
  {
    name: "Spectacle de Cirque",
    category: :show,
    date: 1.week.from_now,
    description: "Spectacle de cirque avec les élèves de l'école"
  },
  {
    name: "Atelier Jonglage",
    category: :workshop,
    date: 2.days.from_now,
    description: "Atelier d'initiation au jonglage pour tous niveaux"
  },
  {
    name: "Atelier Équilibre",
    category: :workshop,
    date: 1.week.from_now,
    description: "Atelier d'équilibre sur fil et boule"
  },
  {
    name: "Bénévolat Entretien",
    category: :volunteering,
    date: 3.days.from_now,
    description: "Séance de bénévolat pour l'entretien des locaux"
  },
  {
    name: "Réunion d'Équipe",
    category: :other,
    date: 5.days.from_now,
    description: "Réunion de l'équipe pédagogique"
  }
]

events.each do |attrs|
  event = Event.find_or_create_by(name: attrs[:name], date: attrs[:date]) do |e|
    e.category = attrs[:category]
    e.description = attrs[:description]
    e.creator = admin_user
  end
  
  puts "  ✅ #{event.name} (#{event.category}) - #{event.date.strftime('%d/%m/%Y')}"
end

puts "🎉 Created #{Event.count} events"
