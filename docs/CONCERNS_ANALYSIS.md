# Analyse complète des Concerns - Opportunités d'amélioration

> **Vocabulaire** : ce document mentionne les classes Ruby actuelles (`SubscriptionPlan`, `BookOfEntry`).
> Vocabulaire cible : `SubscriptionPlan` → `ContributionFormula`, `BookOfEntry` → `Contribution`.
> Voir [glossary.md](glossary.md) et [migrations/vocabulary_migration.md](migrations/vocabulary_migration.md).

## 📊 État actuel des Concerns (10 concerns)

### Concerns existants
1. **Dateable** - Gestion des dates et scopes temporels
2. **Priceable** - Conversion centimes/euros
3. **Statusable** - Humanization et vérifications de statuts
4. **Categorizable** - Humanization des catégories
5. **Humanizable** - Humanization de différents enums
6. **Roleable** - Gestion des rôles utilisateur
7. **Versionable** - Gestion des versions (MembershipType, SubscriptionPlan)
8. **Validatable** - Validations communes
9. **Duplicatable** - Détection et fusion de doublons
10. **SoftDeletable** - Soft deletion (archivage) avec `deleted_at`

## 🎯 Opportunités identifiées

### 1. **BookOfEntry** - Plusieurs concerns manquants

**État actuel :**
- ✅ Enum `status` (inactive, active, expired, consumed, suspended)
- ✅ Colonnes `purchased_at`, `expires_at` (datetime)
- ❌ N'inclut aucun concern

**Opportunités :**
- ✅ **Statusable** : Pour `status_humanized`, `active?`, `expired?`, etc.
- ✅ **Dateable** : Pour `formatted_date(:purchased_at)`, `formatted_date(:expires_at)`, `today?(:purchased_at)`, etc.

**Bénéfices :**
- Code DRY (éviter la duplication de méthodes comme `expired?`)
- Cohérence avec les autres modèles
- Formatage de dates standardisé

### 2. **AttendanceList** - Concerns manquants

**État actuel :**
- ✅ Enum `status` (open, close, archived)
- ✅ Colonnes `start_date`, `end_date` (datetime)
- ❌ N'inclut aucun concern

**Opportunités :**
- ✅ **Statusable** : Pour `status_humanized`, `open?`, `close?`, `archived?`
- ✅ **Dateable** : Pour les méthodes de formatage et vérification de dates

**Bénéfices :**
- Humanization des statuts cohérente
- Formatage de dates standardisé

### 3. **AccountClaim** - Concerns manquants

**État actuel :**
- ✅ Enum `status` (pending, confirmed, rejected, expired)
- ✅ Colonne `expires_at` (datetime)
- ❌ N'inclut aucun concern

**Opportunités :**
- ✅ **Statusable** : Pour `status_humanized`, `pending?`, `confirmed?`, etc.
- ✅ **Dateable** : Pour `formatted_date(:expires_at)`, `expired?` (méthode instance)

**Bénéfices :**
- Cohérence avec Payment et Membership
- Formatage standardisé

### 4. **Person** - SoftDeletable manquant

**État actuel :**
- ✅ Colonne `deleted_at`
- ✅ Méthodes custom : `archive!`, `restore!`, `archived?`
- ✅ Scopes : `active`, `archived`
- ❌ Pas de concern dédié

**Opportunité :**
- ✅ **Créer SoftDeletable concern** : Extraire la logique de soft delete

**Bénéfices :**
- Réutilisable pour d'autres modèles
- Code plus maintenable

### 5. **NewsletterSubscriber** - Dateable manquant

**État actuel :**
- ✅ Colonnes `subscribed_at`, `unsubscribed_at` (datetime)
- ❌ N'inclut aucun concern

**Opportunité :**
- ✅ **Dateable** : Pour formatage et vérification de dates

## 📋 Tableau récapitulatif complet

| Modèle | Statusable | Dateable | Priceable | Categorizable | Humanizable | Roleable | Versionable | SoftDeletable | EmailNormalizable |
|--------|-----------|----------|-----------|---------------|-------------|----------|-------------|---------------|------------------|
| **BookOfEntry** | ✅ | ✅ | - | - | - | - | - | - | - |
| **AttendanceList** | ✅ | ✅ | - | - | - | - | - | - | - |
| **AccountClaim** | ✅ | ✅ | - | - | - | - | - | - | - |
| **Person** | - | ✅ | - | - | ✅ | - | - | ✅ | ✅ |
| **NewsletterSubscriber** | - | ✅ | - | - | - | - | - | - | ✅ |
| **User** | - | ✅ | - | - | - | ✅ | - | - | - |
| **Payment** | ✅ | ✅ | ✅ | - | ✅ | - | - | - | - |
| **PaymentLine** | - | - | ✅ | - | - | - | - | - | - |
| **Event** | - | ✅ | - | ✅ | - | - | - | - | - |
| **Attendance** | - | ✅ | - | - | - | - | - | - | - |
| **SubscriptionPlan** | - | - | ✅ | - | ✅ | - | ✅ | - | - |
| **MembershipType** | - | - | ✅ | ✅ | ✅ | - | ✅ | - | - |
| **Membership** | ✅ | ✅ | - | - | - | - | - | - | - |

## 🚀 Plan d'action - COMPLÉTÉ ✅

### Priorité 1 : Quick wins (faible risque, fort impact) ✅
1. ✅ **BookOfEntry** : Ajouté `Statusable` et `Dateable`
2. ✅ **AttendanceList** : Ajouté `Statusable` et `Dateable`
3. ✅ **AccountClaim** : Ajouté `Statusable` et `Dateable`

### Priorité 2 : Refactoring (impact moyen) ✅
4. ✅ **Person** : Créé et utilisé `SoftDeletable` concern
5. ✅ **NewsletterSubscriber** : Ajouté `Dateable`

### Priorité 3 : Documentation et tests ✅
6. ✅ Documenté tous les concerns
7. ✅ Ajouté des tests pour tous les nouveaux concerns utilisés
8. ✅ Optimisé `UsersController` pour utiliser `User.this_month`

## 📝 Notes

- Tous les modèles avec `enum :status` devraient inclure `Statusable`
- Tous les modèles avec des colonnes date/datetime devraient considérer `Dateable`
- Le pattern soft delete dans Person utilise maintenant `SoftDeletable` concern (réutilisable)

## 📚 Documentation liée

- **Architecture Services:** `docs/architecture/services.md` - Pattern Controller → Service → Model
- **Logique Métier:** `docs/domain/business_logic.md` - Règles business complètes par domaine
- **Audit Controllers:** `docs/architecture/controllers.md` - État des tests et stratégie TDD

