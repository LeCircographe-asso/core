# Guide TDD - Le Circographe

**Date:** 2025-11-09  
**Status:** ✅ STABLE - Guide complet pour TDD

---

## 📚 Table des Matières

1. [Philosophie TDD](#philosophie-tdd)
2. [Configuration et Setup](#configuration-et-setup)
3. [Stratégie de Tests](#stratégie-de-tests)
4. [Workflow TDD](#workflow-tdd)
5. [Structure des Tests](#structure-des-tests)
6. [Outils et Commandes](#outils-et-commandes)
7. [Couverture de Tests](#couverture-de-tests)
8. [CI/CD](#cicd)

---

## Philosophie TDD

### Cycle Red-Green-Refactor

1. **Red:** Écrire un test qui échoue
2. **Green:** Écrire le minimum de code pour le faire passer
3. **Refactor:** Améliorer le code tout en gardant les tests verts

### Principe Fondamental

**Tester le comportement métier, PAS l'implémentation.**

#### ❌ Ne PAS tester l'implémentation
```ruby
# Mauvais: Teste l'implémentation interne
it "updates status to active using update!" do
  membership.update!(status: :active)
  expect(membership.status).to eq("active")
end
```

#### ✅ Tester le comportement métier
```ruby
# Bon: Teste le comportement attendu
it "activates a pending membership when payment succeeds" do
  membership = create(:membership, status: :pending)
  payment = create(:payment, membership: membership, status: :success)
  
  People::PaymentCreator.new(
    person: payment.person,
    amount_cents: payment.total_cents,
    payment_method: payment.payment_method,
    recorded_by_id: payment.recorded_by_id,
    item_type: "Donation",
    item_id: payment.person_id
  ).call
  
  expect(membership.reload.status).to eq("active")
end
```

---

## Configuration et Setup

### SimpleCov Activé (mis à jour)

**Fichier:** `spec/spec_helper.rb`

**Configuration:** Groupes par type (Models, Controllers, Services, Helpers, Jobs, Mailers)

**Seuil:** 12% minimum (progressif vers 60%)  
Objectif: +5% par itération majeure jusqu'à atteindre ≥60% sur le cœur métier.

**Badge:** Ajouté dans README

### Shoulda Matchers Configuré

**Fichier:** `spec/rails_helper.rb`

**Gem:** Ajoutée au Gemfile

**Utilité:** Tests de validations et associations plus concis

### Workflow CI/CD

```
dev → CI Tests ✅ → Auto-merge staging → Deploy staging (si tests passent)
```

**Workflows:**
- `.github/workflows/01-ci.yml` - CI Strict avec coverage
- `.github/workflows/02-auto-merge-to-staging.yml` - Auto-Merge
- `.github/workflows/03-staging-deploy.yml` - Deploy Sécurisé

---

## Stratégie de Tests

### Les 3 Types de Tests à Écrire

#### 1. Tests d'Invariants Métier (IMMUABLES)

**Ce sont les règles métier CORE qui ne changeront JAMAIS.**

```ruby
# Règle: Un membre ne peut pas avoir 2 adhésions actives en même temps
it "prevents overlapping active memberships" do
  person = create(:person)
  create(:membership, person: person, status: :active, 
         started_at: Date.current, ended_at: 1.year.from_now)
  
  overlapping = build(:membership, person: person, status: :active,
                      started_at: 6.months.from_now, ended_at: 18.months.from_now)
  
  expect(overlapping).not_to be_valid
end

# Règle: Prix NE PEUT PAS être négatif ou zéro
it "requires price_cents to be greater than 0" do
  plan = build(:subscription_plan, price_cents: 0)
  expect(plan).not_to be_valid
end
```

**Ces tests sont SACRÉS** - Si tu changes la logique métier ET que ces tests échouent, STOP! Tu as cassé une règle immuable.

### Patterns spécifiques (People::* & Instrumentation)

#### Contrat Result (services People)
Tous les services `People::*` retournent un objet avec une interface minimale (ex: `success?`, `errors`, `message`, payload).
```ruby
result = People::MembershipCreator.new(...).call
expect(result).to respond_to(:success?)
expect(result).to respond_to(:errors)
expect(result).to respond_to(:message)
expect(result).to respond_to(:membership) # payload spécifique
```

#### Instrumentation (ActiveSupport::Notifications)
Les services émettent des événements (`payment.created`, `membership.created`, `membership.upgraded`, `subscription.created`, etc.)
```ruby
captured = []
subscriber = ActiveSupport::Notifications.subscribe("membership.created") do |_name, _start, _finish, _id, payload|
  captured << payload
end

People::MembershipCreator.new(person: person, membership_type_id: type.id, recorded_by_id: admin.id).call
ActiveSupport::Notifications.unsubscribe(subscriber)

expect(captured).not_to be_empty
expect(captured.first[:person_id]).to eq(person.id)
```

#### Turbo/Hotwire (request specs)
Vérifier redirections/statuts et, lorsque pertinent, le contenu Turbo Stream:
```ruby
post path, params: params, headers: { "Accept" => "text/vnd.turbo-stream.html" }
expect(response.media_type).to eq("text/vnd.turbo-stream.html")
expect(response.body).to include("turbo-stream")
```

### Request specs CRUD inline (Admin)
Les contrôleurs admin simplifiés (CRUD inline) se testent comme des flows intégrés:
- `Admin::EventsController`: création avec `title`, mise à jour partielle (via `compact_blank`), redirections et notices.
- `Admin::MembershipTypesController`: create/update/destroy et validations (niveau modèle).
- `Admin::SubscriptionPlansController`: update/destroy inline; `create` délègue à `People::SubscriptionCreator`.

#### 2. Tests de Contrat (Stable Interface)

**Ce sont les APIs exposées qui doivent rester stables.**

```ruby
# Contrat: Service doit TOUJOURS retourner un résultat avec success?/failure?
describe "Contract: Response format" do
  it "always returns a result object" do
    payment = create(:payment)
    result = People::PaymentCreator.new(
      person: payment.person,
      amount_cents: payment.total_cents,
      payment_method: payment.payment_method,
      recorded_by_id: payment.recorded_by_id,
      item_type: "Donation",
      item_id: payment.person_id
    ).call
    
    expect(result).to respond_to(:success?)
    expect(result).to respond_to(:failure?)
    expect(result).to respond_to(:errors)
  end
end
```

#### 3. Tests de Caractérisation (Documentation du Comportement Actuel)

**Documentent le comportement ACTUEL, pas le comportement idéal.**

```ruby
# Comportement ACTUEL: Pack10 n'expire jamais
it "never expires for pack10 subscriptions" do
  book = create(:book_of_entry, :pack10, expires_at: 1.year.ago)
  expect(book.expired?).to be false
end
```

**Si dans 6 mois tu changes cette règle métier:**
1. Le test va échouer
2. Tu DECIDES: Est-ce une régression ou une nouvelle feature?
3. Si nouvelle feature → Mettre à jour BUSINESS_LOGIC.md + Test
4. Si régression → Rejeter le changement

### Classification par Zones

**Zone 1 (Stable):** Tests immédiats requis
**Zone 2 (En cours):** Tests après stabilisation
**Zone 3 (Future):** Pas de tests ou tests triviaux

Voir `docs/ZONES_CLASSIFICATION.md` pour détails.

---

## Workflow TDD

### Scénario 1: Bug ou Edge Case Trouvé

```
1. Reproduire le bug dans un test (RED)
2. Fixer le bug (GREEN)
3. Refactor si nécessaire
4. Commit
```

### Scénario 2: Nouvelle Règle Métier Ajoutée

```
1. Documenter la règle dans BUSINESS_LOGIC.md
2. Écrire test pour la règle (RED)
3. Implémenter la logique (GREEN)
4. Refactor
5. Commit
```

### Scénario 3: Logique Existant Change

```
1. Tests existants échouent (RED)
2. Décider: Bug ou nouvelle feature?
3. Si bug → Fixer (GREEN)
4. Si feature → Mettre à jour tests + doc (GREEN)
5. Refactor
6. Commit
```

---

## Structure des Tests

### Directory Layout

```
spec/
├── models/               # Model specs (validations, associations, scopes)
├── controllers/          # Controller specs (DEPRECATED - use requests)
├── requests/             # Request specs (integration tests for controllers)
│   ├── admin/
│   └── public/
├── services/             # Service object specs
├── helpers/              # Helper specs
├── factories/            # Factory definitions
├── support/              # Shared helpers and configuration
├── rails_helper.rb       # Rails-specific RSpec configuration
└── spec_helper.rb        # Core RSpec configuration
```

### Test Naming Conventions

```ruby
# Model: spec/models/user_spec.rb
RSpec.describe User, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:email) }
  end
  
  describe 'associations' do
    it { should have_many(:memberships) }
  end
  
  describe '#some_method' do
    context 'when condition' do
      it 'returns expected result' do
        # test implementation
      end
    end
  end
end

# Service: spec/services/user_management/user_creator_spec.rb
RSpec.describe UserManagement::UserCreator do
  describe '#call' do
    context 'with valid params' do
      it 'returns success result' do
        # test implementation
      end
    end
    
    context 'with invalid params' do
      it 'returns failure result' do
        # test implementation
      end
    end
  end
end

# Request: spec/requests/admin/users_spec.rb
RSpec.describe 'Admin::Users', type: :request do
  describe 'GET /admin/users' do
    context 'when authenticated' do
      it 'returns list of users' do
        # test implementation
      end
    end
  end
end
```

---

## Outils et Commandes

### Scripts TDD Locaux

#### `bin/test`
Lance tous les tests avec couverture
- Format documentation
- Support `--no-coverage` pour dev rapide

#### `bin/test_fast`
Tests rapides uniquement (models + services)
- Pas d'intégration/controller specs
- Idéal pendant développement

#### `bin/test_watch`
Watch mode pour TDD
- Requiert Guard (gem optionnelle)
- Auto-run tests sur changement de fichier

### Commandes RSpec

```bash
# Run all tests
bundle exec rspec

# Run with documentation format
bundle exec rspec --format documentation

# Run specific file
bundle exec rspec spec/models/user_spec.rb

# Run with focus
bundle exec rspec --tag focus

# Run only failures
bundle exec rspec --only-failures

# Run with seed (to reproduce failures)
bundle exec rspec --seed 12345
```

### FactoryBot

**Définition:**
```ruby
# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    email { "user@example.com" }
    password { "password123" }
    system_role { :member }
  end
end
```

**Utilisation:**
```ruby
# Dans les specs
user = create(:user)
user = create(:user, email: "custom@example.com")
user = build(:user)  # Pas sauvegardé
```

### Shoulda Matchers

```ruby
# Validations
it { should validate_presence_of(:email) }
it { should validate_uniqueness_of(:email) }
it { should validate_length_of(:password).is_at_least(8) }

# Associations
it { should have_many(:memberships) }
it { should belong_to(:person) }
```

---

## Couverture de Tests

### Coverage Actuel (mis à jour)

- **~52.8%** de couverture globale
- SimpleCov activé et configuré
- Seuil minimum: 12% (augmentation progressive prévue)

### Générer le Rapport

```bash
# Tous les tests
bin/test

# OU spécifique
bundle exec rspec spec/models/subscription_plan_spec.rb
```

Le rapport est généré dans: `coverage/index.html`

### Lire le Rapport

1. **Ouvre** `coverage/index.html` dans ton navigateur
2. **Clique** sur un fichier (ex: `app/models/subscription_plan.rb`)
3. **Lis** les couleurs:
   - 🟢 **Vert** = Ligne couverte (exécutée dans les tests)
   - 🔴 **Rouge** = Ligne non couverte (jamais exécutée)
   - ⚪ **Gris** = Code mort / non-exécutable

### Gaps Identifiés

**Models (24 total):**
- ✅ 12 testés (50%)
- ❌ 12 non testés (50%)

**Controllers (34 total):**
- ✅ 8 testés (Zone 1 - critiques)
- ⚠️ 10 en cours (Zone 2)
- ❌ 16 non prioritaires (Zone 3)

**Services (21 total):**
- ✅ 21 testés (100% - tous les services utilisés)

### Priorités (à jour)

**Phase 1: Critiques (Semaine 1)**
- OpeningHoursController (mise à jour via cache)
- Newsletter (flow authentifié) via `NewsletterManagement::NewsletterUpdater`
- UserDeleter (suppression/archivage sécurisé)
- Observabilité: tests d’événements (notifications) sur People::* (membership/payment/subscription/newsletter)

**Phase 2: Admin Complet (Semaine 2)**
- Request specs CRUD inline: Events, MembershipTypes, SubscriptionPlans
- Edge cases modèles (dates, enums, scopes)

**Phase 3: Public & Integration (Semaine 3)**
- Controllers public
- Tests d'intégration end-to-end

---

## CI/CD

### Workflow CI Strict

**`.github/workflows/01-ci.yml`**
- ✅ Rapport de couverture SimpleCov
- ✅ Blocage si coverage < 10%
- ✅ Génération rapport JSON
- ✅ Tests, Linting, Security audit

### Deploy Sécurisé

**`.github/workflows/03-staging-deploy.yml`**
- ✅ Run suite complète AVANT deploy
- ✅ Vérification coverage seuil minimum
- ✅ Blocage si tests échouent ou coverage trop bas
- ✅ Smoke tests améliorés

### Auto-Merge

**`.github/workflows/02-auto-merge-to-staging.yml`**
- ✅ Trigger automatique après CI réussi sur `dev`
- ✅ Merge `dev` → `staging` uniquement si CI passe
- ✅ Force deploy automatique vers staging

---

## 📚 Documentation liée

- **Architecture Services:** `docs/ARCHITECTURE_SERVICES.md` - Pattern Controller → Service → Model
- **Logique Métier:** `docs/BUSINESS_LOGIC.md` - Règles business complètes
- **Audit Controllers:** `docs/CONTROLLERS_AUDIT.md` - État des tests et stratégie
- **Zones Classification:** `docs/ZONES_CLASSIFICATION.md` - Classification Zone 1/2/3


