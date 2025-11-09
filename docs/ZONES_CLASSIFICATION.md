# Classification Zones - Le Circographe

**Date:** 2025-01-27  
**Base:** `docs/BUSINESS_LOGIC.md`

---

## Légende

- **🟢 Zone 1 (Stable)** - Tests immédiats requis
- **🟡 Zone 2 (En cours)** - Tests après stabilisation
- **🔵 Zone 3 (Future)** - Pas de code, pas de tests

---

## Models Classification

### 🟢 Zone 1: Comportement Défini

#### Core Business
| Model | Tests Existants? | Action | Priorité |
|-------|-----------------|---------|----------|
| `User` | ✅ Oui | Compléter si gaps | 🔴 Haute |
| `Person` | ✅ Oui | Compléter si gaps | 🔴 Haute |
| `Membership` | ✅ Oui | Compléter si gaps | 🔴 Haute |
| `Payment` | ✅ Oui | Compléter si gaps | 🔴 Haute |
| `PaymentLine` | ✅ Oui | Compléter si gaps | 🔴 Haute |
| `MembershipType` | ✅ Oui | Compléter si gaps | 🔴 Haute |
| `BookOfEntry` | ✅ Oui | Compléter si gaps | 🔴 Haute |

#### Business Logic
| Model | Tests Existants? | Action | Priorité |
|-------|-----------------|---------|----------|
| `Event` | ✅ Partiel | Ajouter tests edge cases | 🟡 Moyenne |
| `SubscriptionPlan` | ❌ Non | **Tests critiques** | 🔴 **Haute** |
| `AccountClaim` | ❌ Non | Tests workflow | 🟡 Moyenne |
| `Attendance` | ❌ Non | Tests logique quotidienne | 🟡 Moyenne |

#### Support
| Model | Tests Existants? | Action | Priorité |
|-------|-----------------|---------|----------|
| `MemberNumberHistory` | ❌ Non | Tests audit | 🔵 Basse |
| `PaymentAuditLog` | ❌ Non | Tests audit | 🔵 Basse |

### 🟡 Zone 2: En Exploration

| Model | Raison | Tests Quand? |
|-------|--------|--------------|
| `AttendanceList` | Logique quotidienne à finaliser | Après validation |
| `UserService` | Service wrapper, usage incertain | Après clarification |

### 🔵 Zone 3: Future / Non Prioritaire

| Model | Statut |
|-------|--------|
| `Blog`, `Tag`, `TagBlog` | CMS basique, pas critique |
| `PriceCatalog`, `PriceEntry` | Tarification, non urgent |
| `EventAttendee` | Legacy? |
| `Session` | Rails system |

---

## Services Classification

### 🟢 Zone 1: Fonctionnels et Testés

| Service | Usage | Tests? | Action |
|---------|-------|--------|---------|
| `MemberManagementService` | ✅ Utilisé partout | ✅ Oui | Maintenir |
| `People::PaymentCreator` | ✅ Critical | ✅ Oui | Maintenir |
| `People::MembershipUpgrader` | ✅ Critical | ✅ Oui | Maintenir |
| `Admin::PaymentsService` | ✅ Utilisé | ❌ Non | **Ajouter tests** |
| `People::NewsletterSignup` | ✅ Utilisé | ❌ Non | Ajouter tests |

### 🟡 Zone 2: Fonctionnels mais Non Testés

| Service | Usage | Raison Zone 2 | Tests Quand? |
|---------|-------|---------------|--------------|
| `Web::UserRegistration` | ✅ Utilisé | Workflow complexe, peut évoluer | Après stabilisation |
| `People::Register` | ⚠️ Existe | Orchestrateur CRM (à surveiller) | Tests de régression |
| `People::PaymentCreator` | ⚠️ Existe | Interface unique paiements | Tests People |
| `People::PaymentUpdater` | ⚠️ Existe | Interface unique paiements | Tests People |
| `People::PaymentCanceller` | ⚠️ Existe | Interface unique paiements | Tests People |
| `People::PaymentRestorer` | ⚠️ Existe | Interface unique paiements | Tests People |
| `People::AccountLinker` | ⚠️ Existe | CRM merge ponctuel | Tests People |
| `UserManagement::UserDeleter` | ⚠️ Existe | Logique soft-delete | Après stabilisation |
| `People::AccountMerger` | ⚠️ Existe | Fusion CRM ponctuelle | Tests People |
| `EventManagement::EventCreator` | ⚠️ Existe | Référencé | Après stabilisation |
| `EventManagement::EventUpdater` | ⚠️ Existe | CRUD standard | Après stabilisation |
| `EventManagement::EventDeleter` | ⚠️ Existe | CRUD standard | Après stabilisation |

### 🔵 Zone 3: Non Implémenté / Future

| Service | Statut |
|---------|--------|
| `People::PaymentRefund` (à concevoir) | Future |
| Operations in `app/services/admin/operations/` | Non utilisées |

---

## Controllers Classification

### 🟢 Zone 1: Critiques

#### Admin Controllers (CRUD Essentiels)
| Controller | Usage | Tests? | Action |
|------------|-------|--------|---------|
| `Admin::UsersController` | 🔴 Critique | ❌ Non | **Tests urgent** |
| `Admin::MembershipsController` | 🔴 Critique | ❌ Non | **Tests urgent** |
| `Admin::PaymentsController` | 🔴 Critique | ❌ Non | **Tests urgent** |
| `Admin::EventsController` | 🔴 Critique | ❌ Non | **Tests urgent** |
| `Admin::DashboardController` | 🔴 Home | ❌ Non | Tests régression |

#### Public Controllers (Authentification)
| Controller | Usage | Tests? | Action |
|------------|-------|--------|---------|
| `SessionsController` | 🔴 Login | ❌ Non | **Tests urgent** |
| `RegistrationsController` | 🔴 Signup | ❌ Non | **Tests urgent** |
| `CheckoutController` | 🔴 Payment | ❌ Non | **Tests urgent** |

### 🟡 Zone 2: En Cours

| Controller | Raison |
|------------|--------|
| `AccountClaimsController` | Workflow à finaliser |
| `PasswordsController` | Feature à stabiliser |
| `Admin::SubscriptionPlansController` | Configuration en cours |
| `Admin::MemberNumbersController` | Admin access |
| Tous autres admin controllers | CRUD standard |

### 🔵 Zone 3: Non Prioritaire

| Controller | Raison |
|------------|--------|
| `HomeController`, `PagesController` | Simple |
| `EventsController` (public), `BlogsController` | Affichage |
| `ContactsController` | Form simple |
| `Admin::BlogsController` | CMS non critique |
| `Admin::AttendancesController`, `Admin::AttendanceListsController` | Logique en exploration |

---

## Plan d'Action Prioritaire

### Phase 1: Protection Critique (Semaine 1-2)

**Objectif:** 40% coverage, focus sur business critique

#### Models Zone 1 Urgents
- [ ] `SubscriptionPlan` - **CRITIQUE** (pricing)
- [ ] Compléter tests existants si gaps
  - User, Person, Membership, Payment

#### Services Zone 1 Urgents
- [ ] `Admin::PaymentsService` - Utilisé, ajouter tests
- [ ] Compléter tests existants si gaps

#### Controllers Zone 1 Urgents
- [ ] `Admin::UsersController` - Request specs
- [ ] `Admin::PaymentsController` - Request specs
- [ ] `Admin::MembershipsController` - Request specs
- [ ] `Admin::EventsController` - Request specs
- [ ] `SessionsController` - Auth specs
- [ ] `RegistrationsController` - Signup specs
- [ ] `CheckoutController` - Payment specs

**Estimation:** 9 specs critiques

### Phase 2: Complet Zone 1 (Semaine 3-4)

**Objectif:** 60% coverage, Zone 1 complète

#### Models Zone 1 Restants
- [ ] `AccountClaim` - Workflow
- [ ] `Attendance` - Logique quotidienne
- [ ] `Event` - Edge cases
- [ ] Support: `MemberNumberHistory`, `PaymentAuditLog`

#### Services Zone 1 Restants
- [ ] `People::NewsletterSignup` - Email signup
- [ ] Compléter Coverage existants

#### Controllers Zone 1 Restants
- [ ] Autres admin controllers critiques
- [ ] `Admin::DashboardController`

**Estimation:** +15 specs

### Phase 3: Zone 2 Progressive (Semaine 5+)

**Objectif:** Stabiliser Zone 2 → Zone 1

#### Stabiliser Services Zone 2
- [ ] `Web::UserRegistration` - Stabiliser, puis tester
- [ ] `People::Register` & déclinaisons (monitoring en production)
- [ ] `UserManagement::UserDeleter` - Stabiliser, puis tester

**Estimation:** +18 specs (progressif)

---

## Gaps Critiques Identifiés

### Code Mort / Inconsistances

❌ **Références à services inexistants:**
- Services dans `app/services/admin/operations/` - Non utilisés

**Action:** Audit et nettoyage

---

## Résumé Priorités

### 🔴 Immédiat (Zone 1 Critique)
1. `SubscriptionPlan` model
2. Admin controllers: Users, Payments, Memberships, Events
3. Public controllers: Sessions, Registrations, Checkout
4. `Admin::PaymentsService` service

### 🟡 Court Terme (Zone 1 Restant)
5. `AccountClaim`, `Attendance` models
6. Autres admin controllers
7. `People::NewsletterSignup`

### 🔵 Moyen Terme (Zone 2 → 1)
8. Services en exploration
9. Features en cours

### ⚪ Long Terme
10. CMS, Pricing, Features future

---

**Prochaine Revue:** Après Phase 1

