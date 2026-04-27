# Classification Zones - Le Circographe

**Date:** 2025-01-27
**Base:** `docs/domain/business_logic.md`

> **Vocabulaire** : `SubscriptionPlan` est le nom de classe actuel ; vocabulaire cible : `ContributionFormula`. `BookOfEntry` → `Contribution`. Voir [glossary.md](glossary.md).

---

**Statut actuel:** ⚠️ Snapshot 2025-01-27 — à revalider régulièrement.  
**Source de vérité:** `to-do.md` (priorités), `docs/domain/business_logic.md` (règles), `docs/architecture/services.md` (services).

---

## Comment utiliser ce document
- Utiliser ces zones comme **cadre** (stabilité/risque).
- Vérifier la réalité du code et des tests avant d’exécuter un plan.
- Reporter toute priorité actuelle dans `to-do.md`.

## Légende

- **🟢 Zone 1 (Stable)** - Tests immédiats requis
- **🟡 Zone 2 (En cours)** - Tests après stabilisation
- **🔵 Zone 3 (Future)** - Pas de code, pas de tests

---

## Models Classification

### 🟢 Zone 1: Comportement Défini

#### Core Business (snapshot)
| Model | Tests (snapshot) | Action (à valider) | Priorité |
|-------|-----------------|---------|----------|
| `User` | ✅ Oui | Compléter si gaps | 🔴 Haute |
| `Person` | ✅ Oui | Compléter si gaps | 🔴 Haute |
| `Membership` | ✅ Oui | Compléter si gaps | 🔴 Haute |
| `Payment` | ✅ Oui | Compléter si gaps | 🔴 Haute |
| `PaymentLine` | ✅ Oui | Compléter si gaps | 🔴 Haute |
| `MembershipType` | ✅ Oui | Compléter si gaps | 🔴 Haute |
| `BookOfEntry` | ✅ Oui | Compléter si gaps | 🔴 Haute |

#### Business Logic (snapshot)
| Model | Tests (snapshot) | Action (à valider) | Priorité |
|-------|-----------------|---------|----------|
| `Event` | ✅ Partiel | Ajouter tests edge cases | 🟡 Moyenne |
| `SubscriptionPlan` | ❌ Non | **Tests critiques** | 🔴 **Haute** |
| `AccountClaim` | ❌ Non | Tests workflow | 🟡 Moyenne |
| `Attendance` | ❌ Non | Tests logique quotidienne | 🟡 Moyenne |

#### Support (snapshot)
| Model | Tests (snapshot) | Action (à valider) | Priorité |
|-------|-----------------|---------|----------|
| `MemberNumberHistory` | ❌ Non | Tests audit | 🔵 Basse |
| `PaymentAuditLog` | ❌ Non | Tests audit | 🔵 Basse |

### 🟡 Zone 2: En Exploration (snapshot)

| Model | Raison | Tests Quand? |
|-------|--------|--------------|
| `AttendanceList` | Logique quotidienne à finaliser | Après validation |
| `UserService` | Service wrapper, usage incertain | Après clarification |

### 🔵 Zone 3: Future / Non Prioritaire (snapshot)

| Model | Statut |
|-------|--------|
| `Blog`, `Tag`, `TagBlog` | CMS basique, pas critique |
| `PriceCatalog`, `PriceEntry` | Tarification, non urgent |
| `EventAttendee` | Legacy? |
| `Session` | Rails system |

---

## Services Classification

### 🟢 Zone 1: Fonctionnels et Testés (snapshot)

| Service | Usage | Tests? | Action |
|---------|-------|--------|---------|
| `MemberManagementService` | ✅ Utilisé partout | ✅ Oui | Maintenir |
| `People::PaymentCreator` | ✅ Critical | ✅ Oui | Maintenir |
| `People::MembershipUpgrader` | ✅ Critical | ✅ Oui | Maintenir |
| `Admin::PaymentsService` | ✅ Utilisé | ❌ Non | **Ajouter tests** |
| `People::NewsletterSignup` | ✅ Utilisé | ❌ Non | Ajouter tests |

### 🟡 Zone 2: Fonctionnels mais Non Testés (snapshot)

| Service | Usage | Raison Zone 2 | Tests Quand? |
|---------|-------|---------------|--------------|
| `Web::UserRegistration` | ✅ Utilisé | Workflow complexe, peut évoluer | Après stabilisation |
| `People::Register` | ⚠️ Existe | Orchestrateur CRM (à surveiller) | Tests de régression |
| `People::PaymentUpdater` | ⚠️ Existe | Interface unique paiements | Tests People |
| `People::PaymentCanceller` | ⚠️ Existe | Interface unique paiements | Tests People |
| `People::PaymentRestorer` | ⚠️ Existe | Interface unique paiements | Tests People |
| `People::AccountLinker` | ⚠️ Existe | CRM merge ponctuel | Tests People |
| `UserManagement::UserDeleter` | ⚠️ Existe | Logique soft-delete | Après stabilisation |
| `People::AccountMerger` | ⚠️ Existe | Fusion CRM ponctuelle | Tests People |
| `EventManagement::EventCreator` | ⚠️ Existe | Référencé | Après stabilisation |
| `EventManagement::EventUpdater` | ⚠️ Existe | CRUD standard | Après stabilisation |
| `EventManagement::EventDeleter` | ⚠️ Existe | CRUD standard | Après stabilisation |

### 🔵 Zone 3: Non Implémenté / Future (snapshot)

| Service | Statut |
|---------|--------|
| `People::PaymentRefund` (à concevoir) | Future |
| Operations in `app/services/admin/operations/` | Non utilisées |

---

## Controllers Classification

### 🟢 Zone 1: Critiques (snapshot)

#### Admin Controllers (CRUD Essentiels, snapshot)
| Controller | Usage | Tests (snapshot) | Action (à valider) |
|------------|-------|--------|---------|
| `Admin::UsersController` | 🔴 Critique | ❌ Non | **Tests urgent** |
| `Admin::MembershipsController` | 🔴 Critique | ❌ Non | **Tests urgent** |
| `Admin::PaymentsController` | 🔴 Critique | ❌ Non | **Tests urgent** |
| `Admin::EventsController` | 🔴 Critique | ❌ Non | **Tests urgent** |
| `Admin::DashboardController` | 🔴 Home | ❌ Non | Tests régression |

#### Public Controllers (Authentification, snapshot)
| Controller | Usage | Tests (snapshot) | Action (à valider) |
|------------|-------|--------|---------|
| `SessionsController` | 🔴 Login | ❌ Non | **Tests urgent** |
| `RegistrationsController` | 🔴 Signup | ❌ Non | **Tests urgent** |
| `CheckoutController` | 🔴 Payment | ❌ Non | **Tests urgent** |

### 🟡 Zone 2: En Cours (snapshot)

| Controller | Raison |
|------------|--------|
| `AccountClaimsController` | Workflow à finaliser |
| `PasswordsController` | Feature à stabiliser |
| `Admin::SubscriptionPlansController` | Configuration en cours |
| `Admin::MemberNumbersController` | Admin access |
| Tous autres admin controllers | CRUD standard |

### 🔵 Zone 3: Non Prioritaire (snapshot)

| Controller | Raison |
|------------|--------|
| `HomeController`, `PagesController` | Simple |
| `EventsController` (public), `BlogsController` | Affichage |
| `ContactsController` | Form simple |
| `Admin::BlogsController` | CMS non critique |
| `Admin::AttendancesController`, `Admin::AttendanceListsController` | Logique en exploration |

---

## Gaps Critiques Identifiés (snapshot)

### Code Mort / Inconsistances

❌ **Références à services inexistants:**
- Services dans `app/services/admin/operations/` - Non utilisés

**Action:** Audit et nettoyage

---

## Priorités actuelles

Les priorités actives sont centralisées dans `to-do.md`.  
Ce document conserve uniquement une **classification** par zones.
