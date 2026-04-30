# Guide de tests — Le Circographe

> **Statut** : stable
> **Public cible** : contributeur
> **Dernière vérification** : 2026-04-27
> **Sources de vérité** : `spec/`, `bin/test`, `bin/test_fast`, `spec/rails_helper.rb`, `.rspec`.

> Vocabulaire : voir [`../glossary.md`](../glossary.md). Les exemples de code peuvent encore utiliser des noms legacy (`SubscriptionPlan`, `BookOfEntry`) pendant la migration progressive vers `ContributionFormula` / `Contribution` (cf. [`../migrations/vocabulary_migration.md`](../migrations/vocabulary_migration.md)).

Ce document remplace l'ancien trio `docs/TDD_GUIDE.md` + `docs/TESTING_GUIDE.md` + `docs/CHANGELOG_TDD_SETUP.md` qui s'étaient mis à diverger. Pour la priorisation par zones (Zone 1 / 2 / 3), se référer à [`../architecture/models.md`](../architecture/models.md#3-classification-par-zones).

## Sommaire

1. Philosophie TDD
2. Setup et outillage
3. Stratégie de tests (3 types)
4. Workflow TDD au quotidien
5. Structure et conventions des tests
6. Outils et commandes
7. Couverture (SimpleCov)
8. Gaps connus (snapshot)
9. CI/CD
10. Troubleshooting

## 1. Philosophie TDD

### Cycle Red-Green-Refactor

1. **Red** : écrire un test qui échoue.
2. **Green** : écrire le minimum de code pour le faire passer.
3. **Refactor** : améliorer le code en gardant les tests verts.

### Principe fondamental

**Tester le comportement métier, PAS l'implémentation.**

Mauvais (teste l'implémentation interne) :

```ruby
it "updates status to active using update!" do
  membership.update!(status: :active)
  expect(membership.status).to eq("active")
end
```

Bon (teste le comportement attendu) :

```ruby
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

## 2. Setup et outillage

### Gems clés (dans `Gemfile`, groupe `:test`)

- `rspec-rails` — framework de tests.
- `factory_bot_rails` — fabriques de données.
- `simplecov` — rapport de couverture.
- `shoulda-matchers` — matchers concis pour validations / associations.

### Fichiers de configuration

- `spec/spec_helper.rb` — config RSpec + activation SimpleCov, groupes (Models, Controllers, Services, Helpers, Jobs, Mailers).
- `spec/rails_helper.rb` — config Rails + Shoulda Matchers.

### Seuil de couverture

- Seuil minimum CI : **12 %** (objectif progressif vers 60 % sur le cœur métier, +5 % par itération majeure).

## 3. Stratégie de tests

### 3.1 Tests d'invariants métier (immuables)

Règles métier core qui ne changeront jamais.

```ruby
it "prevents overlapping active memberships" do
  person = create(:person)
  create(:membership, person: person, status: :active,
         started_at: Date.current, ended_at: 1.year.from_now)

  overlapping = build(:membership, person: person, status: :active,
                      started_at: 6.months.from_now, ended_at: 18.months.from_now)

  expect(overlapping).not_to be_valid
end

it "requires price_cents to be greater than 0" do
  plan = build(:subscription_plan, price_cents: 0)
  expect(plan).not_to be_valid
end
```

Ces tests sont sacrés : si tu changes la logique métier et qu'ils échouent, **stop** — tu as cassé une règle immuable.

### 3.2 Tests de contrat (interface stable)

Les APIs publiques exposées doivent rester stables.

```ruby
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

### 3.3 Tests de caractérisation (comportement actuel)

Documentent le comportement actuel, pas l'idéal.

```ruby
# Comportement ACTUEL : Pack 10 n'expire jamais
it "never expires for pack10 contributions" do
  book = create(:book_of_entry, :pack10, expires_at: 1.year.ago)
  expect(book.expired?).to be false
end
```

Si dans 6 mois tu changes cette règle :

1. Le test échoue.
2. Tu décides : régression ou nouvelle feature ?
3. Si nouvelle feature → mettre à jour [`../domain/business_logic.md`](../domain/business_logic.md) + le test.
4. Si régression → rejeter le changement.

### 3.4 Patterns spécifiques (services `People::*`)

#### Contrat `Result`

Tous les services `People::*` retournent un objet avec `success?`, `errors`, `message` et un payload spécifique :

```ruby
result = People::MembershipCreator.new(...).call
expect(result).to respond_to(:success?)
expect(result).to respond_to(:errors)
expect(result).to respond_to(:message)
expect(result).to respond_to(:membership)
```

#### Instrumentation (`ActiveSupport::Notifications`)

Les services émettent des événements (`payment.created`, `membership.created`, `membership.upgraded`, `subscription.created` *(cible : `contribution.created`)*, etc.) :

```ruby
captured = []
subscriber = ActiveSupport::Notifications.subscribe("membership.created") do |_n, _s, _f, _i, payload|
  captured << payload
end

People::MembershipCreator.new(person: person, membership_type_id: type.id, recorded_by_id: admin.id).call
ActiveSupport::Notifications.unsubscribe(subscriber)

expect(captured).not_to be_empty
expect(captured.first[:person_id]).to eq(person.id)
```

#### Turbo / Hotwire (request specs)

```ruby
post path, params: params, headers: { "Accept" => "text/vnd.turbo-stream.html" }
expect(response.media_type).to eq("text/vnd.turbo-stream.html")
expect(response.body).to include("turbo-stream")
```

### 3.5 Request specs CRUD inline (admin)

Les contrôleurs admin simplifiés se testent comme des flows intégrés :

- `Admin::EventsController` — création avec `title`, mise à jour partielle (via `compact_blank`), redirections et notices.
- `Admin::MembershipTypesController` — `create` / `update` / `destroy` et validations modèle.
- `Admin::SubscriptionPlansController` *(cible : `Admin::ContributionFormulasController`)* — `update` / `destroy` inline ; `create` délègue à `People::SubscriptionCreator` *(cible : `People::ContributionCreator`)*.

## 4. Workflow TDD au quotidien

### Bug ou edge case détecté

1. Reproduire le bug dans un test (Red).
2. Fixer (Green).
3. Refactor.
4. Commit.

### Nouvelle règle métier

1. Documenter la règle dans [`../domain/business_logic.md`](../domain/business_logic.md).
2. Écrire le test (Red).
3. Implémenter (Green).
4. Refactor.
5. Commit.

### Logique existante qui change

1. Tests existants échouent (Red).
2. Décider : bug ou feature ?
3. Si bug → fixer (Green).
4. Si feature → mettre à jour tests + doc (Green).
5. Refactor.
6. Commit.

## 5. Structure et conventions des tests

```
spec/
  models/                # Validations, associations, scopes
  requests/              # Tests d'intégration des contrôleurs
    admin/
    public/
  services/              # Service objects
  helpers/
  factories/
  support/               # Helpers partagés
  rails_helper.rb
  spec_helper.rb
```

Les `controllers/` purs sont **dépréciés** au profit de `requests/`.

### Conventions de nommage

```ruby
RSpec.describe User, type: :model do
  describe "validations" do
    it { should validate_presence_of(:email) }
  end

  describe "associations" do
    it { should have_many(:memberships) }
  end

  describe "#some_method" do
    context "when condition" do
      it "returns expected result" do
        # ...
      end
    end
  end
end
```

## 6. Outils et commandes

### Scripts locaux

- `bin/test` — suite complète avec couverture.
- `bin/test_fast` — models + services uniquement.
- `bin/test_watch` — watch mode (requiert Guard, gem optionnelle).

### RSpec

```bash
bundle exec rspec
bundle exec rspec --format documentation
bundle exec rspec spec/models/user_spec.rb
bundle exec rspec --tag focus
bundle exec rspec --only-failures
bundle exec rspec --seed 12345
```

### FactoryBot

```ruby
FactoryBot.define do
  factory :user do
    email { "user@example.com" }
    password { "password123" }
    system_role { :member }
  end
end
```

```ruby
user = create(:user)
user = create(:user, email: "custom@example.com")
user = build(:user)
```

### Shoulda Matchers

```ruby
it { should validate_presence_of(:email) }
it { should validate_uniqueness_of(:email) }
it { should validate_length_of(:password).is_at_least(8) }

it { should have_many(:memberships) }
it { should belong_to(:person) }
```

## 7. Couverture (SimpleCov)

### Pourquoi pas 100 % ?

La couverture dit **quelles lignes** sont exécutées par les tests, pas si elles sont **bien testées**. 100 % n'égale pas 100 % de confiance.

Bonnes questions :

- Tous les invariants métier sont-ils couverts ?
- Les edge cases critiques sont-ils couverts ?
- Les chemins d'erreur sont-ils testés ?

### Générer le rapport

```bash
bin/test
# ou ciblé :
bundle exec rspec spec/models/subscription_plan_spec.rb
```

Rapport : `coverage/index.html`.

### Lire le rapport

1. Ouvrir `coverage/index.html`.
2. Cliquer sur un fichier (ex. `app/models/subscription_plan.rb`).
3. Couleurs :
   - **Vert** : ligne couverte.
   - **Rouge** : ligne jamais exécutée.
   - **Gris** : code mort / non exécutable.

### Seuils recommandés

- Minimum CI : 12 % (actuel).
- Acceptable : 30–40 %.
- Bon : 50–60 %.
- Excellent : 70 %+ avec qualité.

### Focus qualité plutôt que quantité

- Tous les invariants métier testés.
- Tous les edge cases critiques testés.
- Tous les services `People::*` testés.
- Tous les contrôleurs Zone 1 testés.

## 8. Gaps connus (snapshot 2025-01-31, à revalider)

Ces listes sont un instantané et doivent être recroisées avec [`../internal/todo.md`](../internal/todo.md) et [`../architecture/models.md`](../architecture/models.md#3-classification-par-zones) avant action.

### Models testés

`User`, `Person`, `Membership`, `Payment`, `PaymentLine`, `MembershipType`, `BookOfEntry` (couverture business complète), `Event` (basique).

### Models non testés

`SubscriptionPlan`, `AccountClaim`, `Attendance`, `AttendanceList`, `Blog`, `Tag`, `TagBlog`, `PriceCatalog`, `PriceEntry`, `PaymentAuditLog`, `MemberNumberHistory`, `EventAttendee`, `Session`, `UserService`.

### Contrôleurs testés (Zone 1)

`Admin::UsersController`, `Admin::PaymentsController`, `Admin::MembershipsController`, `Admin::EventsController`, `Admin::DashboardController`, `SessionsController`, `RegistrationsController`, `CheckoutController`.

### Services testés

L'ensemble des services `People::*`, `AccountClaimManagement::*`, `AttendanceManagement::*`, `AttendanceListManagement::*`, `BlogManagement::*`, `OpeningHoursManagement::*`, `NewsletterManagement::*`, `UserManagement::*` (Updater, Deleter), `EventManagement::*`, `MemberNumberManagement::*`.

### Priorités courtes

1. `OpeningHoursController` (mise à jour via cache).
2. Newsletter (flow authentifié) via `NewsletterManagement::NewsletterUpdater`.
3. `UserDeleter` (suppression / archivage sécurisé).
4. Observabilité : tests d'événements (`ActiveSupport::Notifications`) sur `People::*`.
5. Request specs CRUD inline : `Events`, `MembershipTypes`, `SubscriptionPlans` *(cible : `ContributionFormulas`)*.
6. Edge cases modèles (dates, enums, scopes).

## 9. CI/CD

### RuboCop — rollout progressif (Phase 2+)

- **Baseline** : `rubocop-rails-omakase` dans [`.rubocop.yml`](../../.rubocop.yml) + exclusions projet + override Ezam `Layout/EndOfLine: lf`.
- **Jobs** : [`.github/workflows/ci-lint-audit.yml`](../../.github/workflows/ci-lint-audit.yml) (`lint`) et [`.github/workflows/ci-auto-lint.yml`](../../.github/workflows/ci-auto-lint.yml) — RuboCop est **bloquant** lorsque la baseline est verte (`bundle exec rubocop --format github --force-exclusion`).
- **Élargissement** : activer les cops **par petits lots**, une PR par lot ; pas de refactors métier ni renommage de vocabulaire domaine sans accord ([glossaire](../glossary.md)).
- **Lots suivants suggérés** : après vérif des offenses — LOW (`Style/TrailingCommaInArrayLiteral` / `HashLiteral` si pertinent), puis MEDIUM (`Performance/*`, `Rails/*` au cas par cas), puis HIGH (`Lint/*` sur flux, `Metrics/*`, fichiers `app/models` / `app/services` sensibles) en revue manuelle uniquement.
- **Commandes** : `bundle exec rubocop --format simple --force-exclusion` ; ciblage : `bundle exec rubocop --only NomDuCop chemins… --force-exclusion`.

### `.github/workflows/01-ci.yml`

- Suite RSpec complète.
- Génération SimpleCov + check seuil (bloquant si < 12 %).
- Linting + security audit (`bundle audit`).

### `.github/workflows/02-auto-merge-to-staging.yml`

- Trigger après CI réussi sur `dev`.
- Merge `dev` → `staging` puis déploiement automatique.

### `.github/workflows/03-staging-deploy.yml`

- Suite complète avant déploiement (pas juste smoke tests).
- Vérification du seuil de couverture.
- Blocage si tests échouent ou couverture trop basse.

### Production

- Manuelle via le workflow `04-promote-to-main` (staging → main).

## 10. Troubleshooting

### CI bloquée par la couverture

- Vérifier en local : `open coverage/index.html`.
- Ajouter les tests manquants ou ajuster temporairement le seuil dans `spec/spec_helper.rb` (avec discussion équipe).

### Tests lents

- Utiliser `bin/test_fast` pendant l'itération.
- Ou `bin/test --no-coverage` pour gagner ~30 % sur le run.
- Optimiser les fabriques (préférer `build_stubbed` quand pas de persistence requise).

### Garder la couverture à jour

- Lancer `bin/test` après chaque feature.
- Mettre à jour le badge couverture du `README.md` lors d'augmentations significatives.

## Documentation liée

- [`../domain/business_logic.md`](../domain/business_logic.md) — règles métier.
- [`../architecture/services.md`](../architecture/services.md) — catalogue de services.
- [`../architecture/controllers.md`](../architecture/controllers.md) — état des contrôleurs.
- [`../architecture/models.md`](../architecture/models.md) — modèles, concerns, zones de stabilité.
