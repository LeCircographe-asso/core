# Gestion des Entraînements - Documentation

## Fonctionnalités Implémentées

### 1. Dashboard Admin
- Vue principale des entraînements du jour
- Statistiques de fréquentation (max, min, moyenne)
- Liste des présents avec statuts de paiement
- Recherche d'adhérents en temps réel

### 2. Gestion des Présences
- Ajout d'adhérents à la session
- Vérification automatique des adhésions
- Redirection vers formulaire d'adhésion si nécessaire
- Départ des adhérents avec confirmation

### 3. Logique Métier
```ruby
# Vérification d'adhésion
user.active_circus_membership?  # Vérifie si l'adhésion est active
user.can_train_today?          # Vérifie si peut s'entraîner aujourd'hui
user.already_trained_today?    # Vérifie si déjà présent aujourd'hui

# Gestion des sessions
TrainingSession.current_or_create  # Crée ou récupère la session du jour
session.add_attendee!(user)        # Ajoute un participant
session.full?                      # Vérifie la capacité
```

## Installation et Configuration

1. Migrations nécessaires :
```bash
rails db:migrate
```

2. Configuration des tâches Rake :
```ruby
# lib/tasks/training.rake
namespace :training do
  desc "Crée une nouvelle session d'entraînement"
  task create_session: :environment do
    TrainingSession.create_for_today
  end

  desc "Ferme les sessions expirées"
  task close_expired: :environment do
    TrainingSession.close_expired
  end
end
```

3. Configuration Cron (avec whenever) :
```ruby
# config/schedule.rb
every 1.day, at: '00:00' do
  rake 'training:create_session'
  rake 'training:close_expired'
end
```

## Tests

### Tests Système
```bash
rspec spec/system/training_management_spec.rb
```

### Tests Unitaires
```bash
rspec spec/models/training_session_spec.rb
rspec spec/models/training_attendee_spec.rb
```

### Factories Disponibles
```ruby
# spec/factories/training_sessions.rb
FactoryBot.define do
  factory :training_session do
    date { Date.current }
    status { 'open' }
    max_capacity { 30 }
    association :recorded_by, factory: :user, role: 'admin'
  end
end

# spec/factories/training_attendees.rb
FactoryBot.define do
  factory :training_attendee do
    association :user
    association :training_session
    association :recorded_by, factory: :user, role: 'admin'
    association :user_membership, optional: true
  end
end
```

## Routes Disponibles
```ruby
namespace :admin do
  resources :training_dashboard, only: [:index], path: "entrainements" do
    collection do
      post :add_attendee
      post :check_in
      delete :check_out
    end
  end
end
```

## Utilisation

### Interface Admin
1. Accéder au dashboard : `/admin/entrainements`
2. Rechercher un adhérent
3. Vérifier son statut d'adhésion
4. Ajouter à la session ou rediriger vers adhésion

### Via Console
```ruby
# Créer une session
session = TrainingSession.current_or_create(recorded_by: User.admin.first)

# Ajouter un participant
user = User.find_by(email: "membre@example.com")
session.add_attendee!(user) if user.can_train_today?

# Vérifier les statistiques
stats = TrainingSessionReportService.calculate_attendance_stats(Date.current)
```

### Tâches Rake
```bash
# Créer une nouvelle session
rails training:create_session

# Fermer les sessions expirées
rails training:close_expired
```

## À Venir / TODO
- [ ] Export des données de présence
- [ ] Statistiques avancées
- [ ] Notifications automatiques
- [ ] Interface mobile 