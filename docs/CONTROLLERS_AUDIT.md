# Audit des Contrôleurs - Stratégie TDD

**Date:** 2025-01-31  
**Objectif:** Audit complet des contrôleurs pour préparer l'implémentation de tests TDD  
**Base:** Classification Zones (`docs/ZONES_CLASSIFICATION.md`)

---

## 📊 Résumé Exécutif

**Statut actuel:** ✅ Phase 1 complète - 107 request specs pour 8 contrôleurs critiques  
**Total contrôleurs:** 33  
**Zone 1 (Critiques):** 8 contrôleurs ✅ **100% testé**  
**Zone 2 (En cours):** 10 contrôleurs  
**Zone 3 (Non prioritaire):** 15 contrôleurs

---

## 🎯 Stratégie de Test par Zone

### Zone 1: Tests Immédiats (Protection Critique)

**Approche:** Tests d'intégration (request specs) qui testent les **invariants métier** et **contrats d'interface**.

**Ce qu'on teste:**
- ✅ Autorisation (admin/authentifié/anonyme)
- ✅ Workflows métier complets (CRUD + logique métier)
- ✅ Edge cases critiques (validations, erreurs)
- ✅ Réponses HTTP correctes
- ❌ Pas de détails d'implémentation

### Zone 2: Tests Après Stabilisation

**Approche:** Attendre que la logique se stabilise, puis ajouter tests.

### Zone 3: Pas de Tests (ou Tests Triviaux)

**Approche:** Pas de tests ou tests minimaux pour régression.

---

## 🟢 Zone 1: Contrôleurs Critiques

### Admin Controllers (CRUD Essentiels)

#### 1. `Admin::UsersController` 🔴 **URGENT**

**Complexité:** ⭐⭐⭐⭐⭐ (Très élevée - 505 lignes)

**Actions à tester:**
- `index` - Liste avec filtres, recherche, pagination
- `show` - Affichage Person/User (support format `person_123`)
- `new` - Création avec/without `person_id`
- `create` - Utilise `Admin::UserCreationForm`
- `edit` - Édition User/Person
- `update` - Mise à jour User + Person séparément
- `destroy` - Suppression via `UserManagement::UserDeleter`
- `restore` - Restauration User soft-deleted
- `edit_person` - Édition Person directement

**Invariants métier à tester:**
- ✅ Seuls admin/super_admin peuvent accéder
- ✅ Pas de suppression User avec privilèges ≥ current_user
- ✅ Création User → Person créée automatiquement
- ✅ Update Person → skip_membership_validation activé
- ✅ Destruction Person → User soft-deleted si existe

**Services utilisés:**
- `Admin::UserCreationForm`
- `UserManagement::UserDeleter`
- `PersonQuery`

**Estimation:** 25-30 request specs

---

#### 2. `Admin::PaymentsController` 🔴 **URGENT**

**Complexité:** ⭐⭐⭐⭐ (Élevée - 273 lignes)

**Actions à tester:**
- `index` - Liste avec filtres via `Admin::PaymentsService`
- `new` - Nouveau paiement (optionnel `user_id`)
- `create` - Utilise `PaymentManagement::PaymentCreator`
- `edit` - Édition inline (turbo_stream)
- `update` - Utilise `PaymentManagement::PaymentUpdater`
- `destroy` - Utilise `PaymentManagement::PaymentDeleter`
- `show` - Redirection vers index

**Invariants métier à tester:**
- ✅ Seuls admin/super_admin peuvent accéder
- ✅ Création paiement → `recorded_by_id = Current.user.id`
- ✅ Montant converti euros → centimes
- ✅ Destruction → soft-delete avec audit
- ✅ Totaux recalculés après modifications

**Services utilisés:**
- `Admin::PaymentsService`
- `PaymentManagement::PaymentCreator`
- `PaymentManagement::PaymentUpdater`
- `PaymentManagement::PaymentDeleter`

**Estimation:** 20-25 request specs

---

#### 3. `Admin::MembershipsController` 🔴 **URGENT**

**Complexité:** ⭐⭐⭐⭐ (Élevée - 167 lignes)

**Actions à tester:**
- `index` - Liste des personnes avec adhésions
- `show` - Affichage adhésion actuelle
- `new` - Nouvelle adhésion (optionnel `upgrade=true`)
- `create` - Création/Upgrade via services
  - Upgrade: `MembershipManagement::MembershipUpgrader`
  - Création: `MembershipManagement::MembershipCreator`
- `edit` - Édition adhésion
- `update` - Mise à jour dates/type
- `destroy` - Désactivation (status: inactive)

**Invariants métier à tester:**
- ✅ Seuls admin/super_admin peuvent accéder
- ✅ Upgrade Basic → Circus uniquement
- ✅ Upgrade calcule différence de prix correctement
- ✅ Création adhésion → Payment créé automatiquement
- ✅ Destroy → Status inactive (pas de suppression)

**Services utilisés:**
- `MembershipManagement::MembershipCreator`
- `MembershipManagement::MembershipUpgrader`

**Estimation:** 18-22 request specs

---

#### 4. `Admin::EventsController` 🔴 **URGENT**

**Complexité:** ⭐⭐⭐ (Moyenne - 76 lignes)

**Actions à tester:**
- `index` - Liste tous les événements
- `new` - Formulaire création
- `create` - Utilise `EventManagement::EventCreator`
- `edit` - Édition événement
- `update` - Utilise `EventManagement::EventUpdater`
- `destroy` - Suppression événement

**Invariants métier à tester:**
- ✅ Seuls admin/super_admin peuvent accéder
- ✅ Création → `creator_id = current_user.id`
- ✅ Category par défaut: 'other'

**Services utilisés:**
- `EventManagement::EventCreator`
- `EventManagement::EventUpdater`

**Estimation:** 12-15 request specs

---

#### 5. `Admin::DashboardController` 🔴 **MOYENNE PRIORITÉ**

**Complexité:** ⭐ (Simple - 10 lignes)

**Actions à tester:**
- `index` - Affichage dashboard avec cache

**Invariants métier à tester:**
- ✅ Seuls admin/super_admin peuvent accéder
- ✅ Cache notepad et opening_hours

**Estimation:** 3-5 request specs

---

### Public Controllers (Authentification)

#### 6. `SessionsController` 🔴 **URGENT**

**Complexité:** ⭐⭐ (Simple - 25 lignes)

**Actions à tester:**
- `new` - Formulaire login (redirection si déjà connecté)
- `create` - Authentification + rate limiting
- `destroy` - Déconnexion

**Invariants métier à tester:**
- ✅ Accessible sans authentification (`allow_unauthenticated_access`)
- ✅ Rate limiting: 10 tentatives / 3 minutes
- ✅ Login réussi → Session créée + cookie
- ✅ Login échoué → Redirection avec erreur
- ✅ Logout → Session détruite + cookie supprimé

**Services utilisés:**
- `User.authenticate_by`
- `start_new_session_for`

**Estimation:** 8-10 request specs

---

#### 7. `RegistrationsController` 🔴 **URGENT**

**Complexité:** ⭐⭐⭐ (Moyenne - 58 lignes)

**Actions à tester:**
- `new` - Formulaire inscription (redirection si connecté)
- `create` - Utilise `Web::UserRegistration`

**Invariants métier à tester:**
- ✅ Accessible sans authentification
- ✅ Création User → Person + Newsletter si demandé
- ✅ Email existant → Message avec lien "Mot de passe oublié"
- ✅ Person existante sans User → Message "Récupérer mon compte"
- ✅ CGU + Privacy Policy requis
- ✅ Inscription réussie → Email welcome envoyé

**Services utilisés:**
- `Web::UserRegistration`

**Estimation:** 10-12 request specs

---

#### 8. `CheckoutController` 🔴 **URGENT**

**Complexité:** ⭐⭐⭐ (Moyenne - 65 lignes)

**Actions à tester:**
- `create` - Création session Stripe
- `success` - Callback Stripe + création EventAttendee
- `cancel` - Annulation paiement

**Invariants métier à tester:**
- ✅ Requiert authentification
- ✅ Création session Stripe avec metadata correct
- ✅ Success → EventAttendee créé si paiement réussi
- ✅ Cancel → Redirection avec message

**Services utilisés:**
- Stripe API

**Estimation:** 8-10 request specs (avec mocks Stripe)

---

## 🟡 Zone 2: Contrôleurs En Cours

### En Exploration (Tests Après Stabilisation)

| Controller | Complexité | Raison Zone 2 | Tests Quand? |
|------------|-----------|---------------|--------------|
| `AccountClaimsController` | ⭐⭐ | Workflow à finaliser | Après validation business |
| `PasswordsController` | ⭐⭐ | Feature à stabiliser | Après validation business |
| `Admin::SubscriptionPlansController` | ⭐⭐⭐ | Configuration en cours | Après stabilisation |
| `Admin::MemberNumbersController` | ⭐⭐ | Admin access | Après stabilisation |
| `Admin::MembershipTypesController` | ⭐⭐⭐ | CRUD standard | Après stabilisation |
| `Admin::DonationsController` | ⭐⭐ | CRUD simple | Après stabilisation |
| `Admin::ExportsController` | ⭐⭐ | Export data | Après stabilisation |
| `Admin::OpeningHoursController` | ⭐ | CRUD simple | Après stabilisation |
| `Admin::NotepadsController` | ⭐ | CRUD simple | Après stabilisation |
| `Admin::BlogsController` | ⭐⭐ | CMS non critique | Après stabilisation |

---

## 🔵 Zone 3: Contrôleurs Non Prioritaires

### Pas de Tests (ou Tests Triviaux)

| Controller | Raison |
|------------|--------|
| `HomeController` | Affichage simple |
| `PagesController` | Pages statiques |
| `EventsController` (public) | Affichage liste |
| `BlogsController` (public) | Affichage blog |
| `ContactsController` | Formulaire simple |
| `SettingsController` | Self-service non critique |
| `UsersController` (public) | Profil utilisateur |
| `EventInterestsController` | Feature simple |
| `CookiesController` | Configuration cookies |
| `Admin::PriceCatalogController` | CMS non critique |
| `Admin::AttendanceListsController` | Logique en exploration |
| `Admin::AttendancesController` | Logique en exploration |
| `Admin::SessionsController` | Duplicate SessionsController |
| Autres admin controllers | CRUD non critiques |

---

## 📋 Plan d'Action Prioritaire

### Phase 1: Protection Critique (Semaine 1-2)

**Objectif:** Tests pour 8 contrôleurs Zone 1

**Ordre de priorité:**
1. ✅ `SessionsController` - Auth critique
2. ✅ `RegistrationsController` - Signup critique
3. ✅ `Admin::PaymentsController` - Financier critique
4. ✅ `Admin::MembershipsController` - Business critique
5. ✅ `Admin::UsersController` - Gestion critique
6. ✅ `CheckoutController` - Paiement critique
7. ✅ `Admin::EventsController` - CRUD critique
8. ✅ `Admin::DashboardController` - Home admin

**Estimation totale:** ~100-120 request specs

**Métriques attendues:**
- Coverage controllers Zone 1: 80%+
- Tests passent à 100%
- CI bloquant pour régressions

---

### Phase 2: Complétion Zone 1 (Semaine 3)

**Objectif:** Edge cases + intégrations

- Tests Turbo Stream pour actions AJAX
- Tests formats JSON
- Tests edge cases (permissions, validations)
- Tests intégration avec services

**Estimation:** +30-40 request specs

---

### Phase 3: Zone 2 Progressive (Semaine 4+)

**Objectif:** Stabiliser Zone 2 → Zone 1

- Quand logique stabilisée, ajouter tests
- Migration progressive Zone 2 → Zone 1

---

## 🧪 Structure de Tests Recommandée

### Pattern Request Spec

```ruby
# spec/requests/admin/users_spec.rb
RSpec.describe "Admin::Users", type: :request do
  let(:admin_user) { create(:user, system_role: :admin) }
  let(:regular_user) { create(:user, system_role: :web_visitor) }

  before { sign_in_as admin_user }

  describe "GET /admin/users" do
    context "when authenticated as admin" do
      it "returns success" do
        get admin_users_path
        expect(response).to have_http_status(:success)
      end

      it "filters by active membership" do
        create(:person, :with_active_membership)
        create(:person, :without_membership)

        get admin_users_path, params: { filter: "with_active_membership" }
        
        expect(assigns(:people).count).to eq(1)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        sign_out
        get admin_users_path
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "POST /admin/users" do
    context "with valid params" do
      let(:valid_params) do
        {
          user: {
            first_name: "John",
            last_name: "Doe",
            email: "john@example.com",
            create_web_account: "1",
            email_address: "john@example.com",
            system_role: "web_visitor"
          }
        }
      end

      it "creates a new user and person" do
        expect {
          post admin_users_path, params: valid_params
        }.to change(Person, :count).by(1)
          .and change(User, :count).by(1)
      end

      it "redirects to user show page" do
        post admin_users_path, params: valid_params
        person = Person.last
        expect(response).to redirect_to(admin_user_path("person_#{person.id}"))
      end
    end
  end
end
```

---

## 🔐 Patterns d'Authorization à Tester

### Admin Controllers

```ruby
context "authorization" do
  it "allows admin access" do
    sign_in_as create(:user, system_role: :admin)
    get admin_users_path
    expect(response).to have_http_status(:success)
  end

  it "allows super_admin access" do
    sign_in_as create(:user, system_role: :super_admin)
    get admin_users_path
    expect(response).to have_http_status(:success)
  end

  it "denies volunteer access" do
    sign_in_as create(:user, system_role: :volunteer)
    get admin_users_path
    expect(response).to redirect_to(root_path)
  end

  it "denies unauthenticated access" do
    get admin_users_path
    expect(response).to redirect_to(new_session_path)
  end
end
```

### Public Controllers

```ruby
context "authorization" do
  it "allows unauthenticated access to new" do
    get new_registration_path
    expect(response).to have_http_status(:success)
  end

  it "allows authenticated access" do
    sign_in_as create(:user)
    get new_registration_path
    expect(response).to redirect_to(root_path)
  end
end
```

---

## 🎯 Invariants Métier Critiques par Domaine

### Users Management
- ✅ Un User ne peut pas être supprimé par un User avec privilèges ≤
- ✅ Création User → Person créée automatiquement
- ✅ Person sans User peut exister (prospects, newsletter)

### Payments
- ✅ Montant toujours en centimes en DB
- ✅ `recorded_by_id` toujours défini (audit trail)
- ✅ Destruction → soft-delete (pas de hard delete)

### Memberships
- ✅ Upgrade Basic → Circus uniquement
- ✅ Pas de downgrade Circus → Basic
- ✅ Création adhésion → Payment créé automatiquement

### Authentication
- ✅ Rate limiting: 10 tentatives / 3 minutes
- ✅ Session créée avec cookie httponly
- ✅ Logout → Session détruite

---

## 📊 Métriques de Succès

### Phase 1 (Semaine 1-2)
- ✅ 8 contrôleurs Zone 1 testés
- ✅ 100-120 request specs écrits
- ✅ Coverage controllers Zone 1: 80%+
- ✅ Tous tests passent à 100%

### Phase 2 (Semaine 3)
- ✅ Edge cases testés
- ✅ Intégrations services testées
- ✅ Coverage controllers Zone 1: 90%+

### Phase 3 (Semaine 4+)
- ✅ Zone 2 progressive → Zone 1
- ✅ Coverage globale: 60%+

---

## 🔧 Helpers et Support Files Nécessaires

### Request Spec Helper

```ruby
# spec/support/request_helpers.rb
module RequestHelpers
  def sign_in_as(user)
    # Créer session + cookie
    session = user.sessions.create!(
      user_agent: "Test Agent",
      ip_address: "127.0.0.1"
    )
    cookies.signed[:session_id] = session.id
    Current.user = user
    Current.session = session
  end

  def sign_out
    Current.session&.destroy
    cookies.delete(:session_id)
    Current.user = nil
    Current.session = nil
  end
end
```

### Factory Traits

```ruby
# spec/factories/people.rb
FactoryBot.define do
  factory :person do
    # ...
    
    trait :with_active_membership do
      after(:create) do |person|
        create(:membership, person: person, status: :active)
      end
    end
    
    trait :without_user_account do
      user { nil }
    end
  end
end
```

---

## ✅ Checklist Démarrage

### Avant de Commencer
- [ ] Lire `docs/TEST_STRATEGY_UNSTABLE_LOGIC.md`
- [ ] Lire `docs/BUSINESS_LOGIC.md` (Zone 1)
- [ ] Comprendre architecture Person-Based
- [ ] Setup helpers request spec
- [ ] Créer factories nécessaires

### Pour Chaque Contrôleur
- [ ] Identifier actions critiques
- [ ] Identifier invariants métier
- [ ] Identifier services utilisés
- [ ] Écrire tests authorization d'abord
- [ ] Écrire tests happy path
- [ ] Écrire tests edge cases
- [ ] Vérifier coverage > 80%

---

## 📚 Références

- **Business Logic:** `docs/BUSINESS_LOGIC.md`
- **Zones Classification:** `docs/ZONES_CLASSIFICATION.md`
- **Test Strategy:** `docs/TEST_STRATEGY_UNSTABLE_LOGIC.md`
- **TDD Approach:** `docs/TDD_REALISTIC_APPROACH.md`

---

**Prochaine Étape:** Commencer Phase 1 avec `SessionsController` (plus simple) pour établir patterns et helpers.

