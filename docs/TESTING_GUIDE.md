# Guide de Tests et Couverture - Le Circographe

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

## Audit de Couverture

### Coverage Actuel

- **10.42%** de couverture globale
- SimpleCov activé et configuré
- Seuil minimum: 10% (progressif vers 60%)

### Executive Summary

L'application a actuellement une **couverture très faible** à 10.42%. Bien que des tests de qualité existent pour la logique métier core (Membership, Payment processing), la plupart des modèles, contrôleurs et services manquent de couverture de tests.

**Priorité Critique:** Se concentrer sur les tests de contrôleurs pour la zone admin et les modèles business core avant d'étendre le développement de fonctionnalités.

---

## Gaps Identifiés

### Models (24 total, 12 tested = 50%)

#### ✅ **Well Tested Models**
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

#### ❌ **Untested Models (HIGH PRIORITY)**
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

### Controllers (34 total)

#### ✅ **Tested Controllers (Zone 1 - 8 controllers)**
- `Admin::UsersController` - 107 request specs
- `Admin::PaymentsController` - Tests complets
- `Admin::MembershipsController` - Tests complets
- `Admin::EventsController` - Tests complets
- `Admin::DashboardController` - Tests complets
- `SessionsController` - Tests complets
- `RegistrationsController` - Tests complets
- `CheckoutController` - Tests complets

#### ⚠️ **Partially Tested Controllers (Zone 2 - 10 controllers)**
- En exploration, tests après stabilisation

#### ❌ **Untested Controllers (Zone 3 - 16 controllers)**
- Non prioritaires, tests triviaux ou pas de tests

**Estimation:** 25-30 request specs needed for Zone 2 controllers

### Services (21 total)

#### ✅ **All Services Tested (100%)**
- `MembershipManagement::*` - 4 services, tous testés
- `SubscriptionManagement::*` - 2 services, tous testés
- `PaymentManagement::*` - 6 services, tous testés
- `AccountClaimManagement::*` - 2 services, tous testés
- `AttendanceManagement::*` - 1 service, testé
- `AttendanceListManagement::*` - 3 services, tous testés
- `BlogManagement::*` - 3 services, tous testés
- `MembershipTypeManagement::*` - 2 services, tous testés
- `OpeningHoursManagement::*` - 1 service, testé
- `NewsletterManagement::*` - 1 service, testé
- `SubscriptionPlanManagement::*` - 2 services, tous testés
- `UserManagement::*` - 3 services, tous testés
- `PersonManagement::*` - 3 services, tous testés
- `EventManagement::*` - 3 services, tous testés
- `MemberNumberManagement::*` - 2 services, tous testés

**Total:** 44 services, tous testés ✅

---

## Plan d'Action

### Phase 1: Critiques (Semaine 1)

**Models (HIGH PRIORITY):**
1. `SubscriptionPlan` - Critical for pricing logic
2. `AccountClaim` - Workflow for account claiming
3. `Attendance` - Daily attendance logic

**Estimation:** 3 specs, ~50 examples

**Goal:** Augmenter coverage à 15%

### Phase 2: Admin Complet (Semaine 2)

**Controllers Zone 2:**
- Controllers admin restants
- Edge cases modèles

**Estimation:** 15-20 request specs

**Goal:** Augmenter coverage à 25%

### Phase 3: Public & Integration (Semaine 3)

**Controllers Public:**
- Controllers public
- Tests d'intégration end-to-end

**Estimation:** 10-15 request specs

**Goal:** Augmenter coverage à 35%

### Roadmap Long Terme

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


