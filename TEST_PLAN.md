# Plan de Tests du Circographe

## 1. Tests Unitaires

### 1.1 Modèles
```ruby
# spec/models/membership_type_spec.rb
RSpec.describe MembershipType do
  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:price) }
    it { should validate_numericality_of(:price).is_greater_than(0) }
    
    it "valide les catégories autorisées" do
      expect(build(:membership_type, category: 'membership')).to be_valid
      expect(build(:membership_type, category: 'circus_membership')).to be_valid
      expect(build(:membership_type, category: 'invalid')).not_to be_valid
    end
  end
end

# spec/models/training_attendee_spec.rb
RSpec.describe TrainingAttendee do
  describe "validations" do
    it { should belong_to(:user) }
    it { should belong_to(:training_session) }
    
    it "empêche les doublons pour un même jour" do
      user = create(:user)
      session = create(:training_session)
      create(:training_attendee, user: user, training_session: session)
      
      duplicate = build(:training_attendee, user: user, training_session: session)
      expect(duplicate).not_to be_valid
    end
  end
end
```

### 1.2 Services
```ruby
# spec/services/membership_service_spec.rb
RSpec.describe MembershipService do
  describe "#register_with_payment" do
    it "crée une adhésion basique à 1€" do
      service = MembershipService.new(user: create(:user))
      membership = service.register_with_payment(
        type: 'basic',
        payment_method: 'cash'
      )
      
      expect(membership).to be_valid
      expect(membership.price).to eq(1)
    end
    
    it "gère le bypass événement" do
      service = MembershipService.new(user: create(:user))
      membership = service.register_with_payment(
        type: 'basic',
        payment_method: 'event_bypass',
        event_name: 'Portes Ouvertes'
      )
      
      expect(membership.payment.notes).to include('Portes Ouvertes')
    end
  end
end
```

## 2. Tests d'Intégration

### 2.1 Workflow Bénévole
```ruby
# spec/system/volunteer_workflow_spec.rb
RSpec.describe "Workflow Bénévole", type: :system do
  it "permet d'ajouter un passage" do
    user = create(:user, :with_valid_membership)
    sign_in create(:user, :volunteer)
    
    visit admin_training_sessions_path
    fill_in "Recherche", with: user.name
    click_on "Ajouter"
    
    expect(page).to have_content("Passage enregistré")
    expect(TrainingAttendee.count).to eq(1)
  end
  
  it "empêche les passages sans adhésion valide" do
    user = create(:user, :without_membership)
    sign_in create(:user, :volunteer)
    
    visit admin_training_sessions_path
    fill_in "Recherche", with: user.name
    click_on "Ajouter"
    
    expect(page).to have_content("Adhésion invalide")
    expect(TrainingAttendee.count).to eq(0)
  end
end
```

### 2.2 Workflow Adhésion
```ruby
# spec/system/membership_workflow_spec.rb
RSpec.describe "Workflow Adhésion", type: :system do
  it "permet une inscription complète" do
    sign_in create(:user, :admin)
    visit new_admin_member_path
    
    fill_in "Nom", with: "John Doe"
    fill_in "Email", with: "john@example.com"
    select "Adhésion Circus", from: "Type"
    select "Espèces", from: "Paiement"
    click_on "Enregistrer"
    
    expect(page).to have_content("Membre créé")
    expect(User.last.circus_membership?).to be true
  end
end
```

## 3. Tests de Performance

### 3.1 Recherche Membres
```ruby
# spec/performance/search_spec.rb
RSpec.describe "Performance Recherche", type: :performance do
  it "recherche rapide avec 1000 membres" do
    create_list(:user, 1000)
    
    measure do
      User.search("doe").limit(10)
    end.to perform_under(100).ms
  end
end
```

### 3.2 Session Quotidienne
```ruby
# spec/performance/daily_session_spec.rb
RSpec.describe "Performance Session", type: :performance do
  it "gère 100 passages simultanés" do
    session = create(:training_session)
    users = create_list(:user, 100, :with_valid_membership)
    
    measure do
      users.each do |user|
        session.add_attendee!(user)
      end
    end.to perform_under(1).seconds
  end
end
```

## 4. Commandes de Test

### Lancer les Tests
```bash
# Tests unitaires
rspec spec/models

# Tests d'intégration
rspec spec/system

# Tests de performance
rspec spec/performance

# Tous les tests avec couverture
COVERAGE=true bundle exec rspec
```

### Vérifier la Couverture
```bash
open coverage/index.html
```

## 5. Points de Contrôle

### Avant Déploiement
- [ ] Couverture > 90%
- [ ] Tous les tests passent
- [ ] Performance acceptable
- [ ] Pas de fuite mémoire

### Après Déploiement
- [ ] Monitoring des erreurs
- [ ] Temps de réponse < 200ms
- [ ] Pas de N+1 queries 