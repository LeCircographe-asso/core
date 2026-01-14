# Guide de Tests et Couverture - Le Circographe

**Statut actuel:** ⚠️ À revalider régulièrement (snapshot 2025-01-31).  
**Source de vérité:** `to-do.md` + `docs/ZONES_CLASSIFICATION.md`.

---

**Date:** 2025-01-31  
**Status:** ✅ STABLE - Guide complet pour tests et couverture

---

## 📚 Table des Matières

1. [Pourquoi la Couverture est Importante](#pourquoi-la-couverture-est-importante)
2. [Rapport SimpleCov](#rapport-simplecov)
3. [Audit de Couverture](#audit-de-couverture)
4. [Gaps Identifiés](#gaps-identifiés)
5. [Plan d'Action](#plan-daction)

---

## Pourquoi la Couverture est Importante

La couverture de code te dit **quelles lignes de code** ont été exécutées pendant les tests. Mais attention: **100% de couverture ne veut PAS dire 100% de confiance !**

### Bonnes Questions
- ✅ Tous mes cas d'usage métier sont-ils testés ?
- ✅ Les edge cases critiques sont-ils couverts ?
- ✅ Les erreurs sont-elles testées ?

### Mauvaises Questions
- ❌ Ai-je 100% de couverture ? (sans comprendre QUOI est testé)
- ❌ Plus c'est haut, mieux c'est ? (non, qualité > quantité)

---

## Rapport SimpleCov

### Générer le Rapport

```bash
# Tous nos tests critiques
bundle exec rspec spec/models/subscription_plan_spec.rb \
                spec/models/book_of_entry_spec.rb \
                spec/models/account_claim_spec.rb \
                spec/models/attendance_spec.rb \
                spec/models/event_spec.rb \
                spec/services/admin/payments_service_spec.rb

# OU avec bin/test
bin/test
```

Le rapport est généré dans: `coverage/index.html`

### Lire le Rapport

1. **Ouvre** `coverage/index.html` dans ton navigateur
2. **Clique** sur un fichier (ex: `app/models/subscription_plan.rb`)
3. **Lis** les couleurs:
   - 🟢 **Vert** = Ligne couverte (exécutée dans les tests)
   - 🔴 **Rouge** = Ligne non couverte (jamais exécutée)
   - ⚪ **Gris** = Code mort / non-exécutable

### Interpréter les Résultats

**Exemple:**
```
app/models/subscription_plan.rb
  - 85% couverture (51/60 lignes)
  - Lignes non couvertes: 12-15, 42-45 (edge cases)
```

**Action:**
- ✅ Lignes critiques couvertes → OK
- ⚠️ Edge cases non couverts → Ajouter tests si critique
- ❌ Lignes métier non couvertes → **PRIORITÉ HAUTE**

---

## Audit de Couverture (à revalider)

Les chiffres de couverture et la liste des specs présentes doivent être **revalidés** avant d’être utilisés.  
Référence actuelle: `to-do.md` (tests prioritaires) + `docs/ZONES_CLASSIFICATION.md`.

---

## Gaps Identifiés

### Models (snapshot 2025-01-31)

#### ✅ **Well Tested Models** (snapshot)
- `User` - User spec exists
- `Person` - Person spec exists
- `Membership` - Membership spec exists
- `Payment` - Payment spec exists
- `PaymentLine` - PaymentLine spec exists
- `MembershipType` - MembershipType spec exists
- `BookOfEntry` - Comprehensive tests including business logic
- `Event` - Basic tests exist

#### ⚠️ **Partially Tested Models**
- Complex logic tested in integration tests but no dedicated specs

#### ❌ **Untested Models (snapshot)**
- `SubscriptionPlan` - Critical for pricing logic, pack10 subscriptions
- `AccountClaim` - Workflow for account claiming/recovery
- `Attendance` - Event registration, daily attendance
- `AttendanceList` - Attendance management
- `Blog` - CMS functionality
- `Tag` / `TagBlog` - Content management
- `PriceCatalog` / `PriceEntry` - Pricing structure
- `PaymentAuditLog` - Audit trail critical for compliance
- `MemberNumberHistory` - History tracking
- `EventAttendee` - Event management
- `Session` - Session management
- `UserService` - User business logic

**Estimation:** 12 specs needed for models

### Controllers (snapshot 2025-01-31)

#### ✅ **Tested Controllers (snapshot)**
- `Admin::UsersController` - 107 request specs
- `Admin::PaymentsController` - Tests complets
- `Admin::MembershipsController` - Tests complets
- `Admin::EventsController` - Tests complets
- `Admin::DashboardController` - Tests complets
- `SessionsController` - Tests complets
- `RegistrationsController` - Tests complets
- `CheckoutController` - Tests complets

#### ⚠️ **Partially Tested Controllers (snapshot)**
- En exploration, tests après stabilisation

#### ❌ **Untested Controllers (snapshot)**
- Non prioritaires, tests triviaux ou pas de tests

**Estimation:** 25-30 request specs needed for Zone 2 controllers

### Services (snapshot 2025-01-31)

#### ✅ **All Services Tested (snapshot)**
- `People::*` (PersonCreator, Register, Payment*, Subscription*, Membership*, AccountLinker, NewsletterSignup) - specs dédiées
- `AccountClaimManagement::*` - 2 services, tous testés
- `AttendanceManagement::*` - 1 service, testé
- `AttendanceListManagement::*` - 3 services, tous testés
- `BlogManagement::*` - 3 services, tous testés
- `Admin::MembershipTypesController` - CRUD inline (remplace services)
- `Admin::SubscriptionPlansController` - CRUD inline (remplace services)
- `OpeningHoursManagement::*` - 1 service, testé
- `NewsletterManagement::*` - 1 service, testé
- `UserManagement::*` - 2 services critiques (Updater, Deleter) testés
- `EventManagement::*` - 3 services, tous testés
- `MemberNumberManagement::*` - 2 services, tous testés

**Total:** 34 services, tous testés ✅

---

## Plan d'Action (à revalider)

### Phase 1: Critiques (snapshot)

**Models (HIGH PRIORITY):**
1. `SubscriptionPlan` - Critical for pricing logic
2. `AccountClaim` - Workflow for account claiming
3. `Attendance` - Daily attendance logic

**Estimation:** 3 specs, ~50 examples

**Goal:** Augmenter coverage à 15%

### Phase 2: Admin Complet (snapshot)

**Controllers Zone 2:**
- Controllers admin restants
- Edge cases modèles

**Estimation:** 15-20 request specs

**Goal:** Augmenter coverage à 25%

### Phase 3: Public & Integration (snapshot)

**Controllers Public:**
- Controllers public
- Tests d'intégration end-to-end

**Estimation:** 10-15 request specs

**Goal:** Augmenter coverage à 35%

### Roadmap Long Terme (snapshot)

**Phase 4: Coverage 50% (Semaine 4-6)**
- Models restants
- Helpers
- Jobs

**Phase 5: Coverage 60% (Semaine 7-8)**
- Edge cases
- Error handling
- Integration tests

**Phase 6: Maintenance (Ongoing)**
- Nouveaux tests pour nouvelles features
- Révision périodique
- Seuil minimum: 60%

---

## Métriques de Qualité

### Seuils Recommandés

- **Minimum:** 10% (actuel)
- **Acceptable:** 30-40%
- **Bon:** 50-60%
- **Excellent:** 70%+ (avec tests qualité)

### Focus sur Qualité

**Ne pas viser 100% de couverture, mais:**
- ✅ Tous les invariants métier testés
- ✅ Tous les edge cases critiques testés
- ✅ Tous les services testés (100% ✅)
- ✅ Tous les controllers Zone 1 testés (100% ✅)

---

## 📚 Documentation liée

- **TDD Guide:** `docs/TDD_GUIDE.md` - Workflow TDD complet
- **Audit Controllers:** `docs/CONTROLLERS_AUDIT.md` - État des tests controllers
- **Zones Classification:** `docs/ZONES_CLASSIFICATION.md` - Classification Zone 1/2/3
