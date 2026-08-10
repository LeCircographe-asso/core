# Logique Métier - Le Circographe

> **Statut** : stable
> **Public cible** : contributeur, métier
> **Dernière vérification** : 2026-08-10
> **Sources de vérité** : `app/models/person.rb`, `app/models/membership.rb`, `app/services/people/*.rb`, `db/seeds/membership_types.rb`, `db/seeds/contribution_formulas.rb`.

**Application:** Gestion complète pour association de cirque  
**Dernière revue contenu:** 2025-11-03  
**Classification:** Zone 1 (Stable) | Zone 2 (En cours) | Zone 3 (Future)  
**État:** ✅ Logique métier complètement réécrite selon vraies règles business (2025-11-03)

> **Vocabulaire DDD-light** (voir [`../glossary.md`](../glossary.md))
>
> Ce document utilise les noms de classes Ruby **canoniques** (`ContributionFormula`, `Contribution`, `People::Contribution*`, `Person#create_contribution!`).
> Le terme « subscription » n'est légitime que pour la **newsletter**.

---

## Classification des Zones

- **Zone 1 (Stable)** - Comportement défini et immuable → Tests immédiats
- **Zone 2 (En cours)** - Logique temporaire/exploration → Tests après stabilisation
- **Zone 3 (Future)** - Non implémenté → Pas de tests

**Voir [`../architecture/models.md`](../architecture/models.md#3-classification-par-zones) pour détails complets.**

### Stratégie Backend - Logique Métier Immuable

**Objectif:** Comprendre, documenter et rendre immuable la logique métier.

**Problème:** Logique métier encore en mouvement → Pas clair ce qui doit être testé → Risque de tests sur code instable

**Solution: 3 Zones**

1. **Zone 1: Logique Définie (Maintenant)** - Fonctionnel et stable → Tests immédiats
2. **Zone 2: Logique En Cours (Prototype)** - Fonctionnel mais pourrait changer → Tests après stabilisation
3. **Zone 3: Logique Future (À Définir)** - Non implémenté → Documentation seulement

**Workflow:**
1. Documenter la logique métier dans `docs/domain/business_logic.md`
2. Classifier le code par zone
3. Tester Zone 1 immédiatement
4. Attendre stabilisation pour Zone 2
5. Documenter seulement pour Zone 3

---

# Domaines Métier

## 1. Membership (Adhésions)

### Zone 1: Comportement Défini

#### Durée et Statuts
- **Durée standard:** 1 an, calculée de `started_at` à `ended_at` (dates inclusives)
- **Statuts:** `pending` → `active` → `inactive` → `expired`
- **Activation:** Immédiate après paiement réussi
- **Expiration:** Quand `ended_at < Date.current` → passage en `expired`
- **Renouvellement:** Crée une nouvelle adhésion datée à partir de la nouvelle souscription

#### Types d'Adhésions
- **Simple:** 1€ - Adhésion standard sans accès cirque
- **Cirque:** 10€ - Adhésion avec accès cirque - tarif plein
- **Cirque:** 7€ - Adhésion avec accès cirque - tarif réduit (RSA, Mineur, Handicap, Étudiant)

#### Règles de Référence
```ruby
# Validation: ended_at > started_at
# Validation: Pas d'overlapping active memberships (sauf si skip_overlap_validation)
# Enum status: pending(0), inactive(1), active(2), expired(3)
# Expiration automatique: status passe à expired si Date.current > ended_at
```

#### Upgrades Possibles
- ✅ Basic → Circus (avec tout tarif: Plein, Réduit, etc.)
- ✅ Circus → Circus (changement de tarif uniquement: Plein ↔ Réduit)
- ❌ Circus → Basic (interdit)
- ❌ Même type (interdit)

**RÈGLE CRITIQUE:** Upgrade = **plein tarif** du nouveau type (pas de prorata)

#### Logique Métier
```ruby
Membership#can_upgrade_to?(membership_type)
Membership#upgrade_to!(new_type, started_at)
Membership#basic?
Membership#circus?
People::MembershipCreator.call(...) # Crée + paiement + numéro
People::MembershipUpgrader.call(...) # Full price du nouveau type
Person#renew_membership!(membership_type, ...) # Nouveau numéro chaque année
```

### Zone 2: En Cours de Validation

- [ ] Renouvellement automatique
- [ ] Gestion des abonnements suspendus

### Zone 3: Future

- [ ] Programmes de fidélité
- [ ] Parrainage
- [ ] Adhésions familiales

---

## 2. Payment (Paiements)

### Zone 1: Comportement Défini

#### Intégration Stripe
- **Provider:** Stripe pour paiements
- **Workflow:** Enregistrement → Traitement → Succès/Échec
- **Statuts:** `pending` → `success` / `failed`

#### Types de Paiements
- **Membership:** Activation adhésion
- **`ContributionFormula`** — formule de cotisation (pack10, annual, etc.)
- **MembershipType:** Nouvelle adhésion

#### Logique Métier Person-Based

```ruby
People::MembershipCreator.call(...)   # Crée membership + payment + payment_line
People::MembershipUpgrader.call(...)  # Crée payment full price + payment_line
People::ContributionCreator.call(...) # Crée contribution + payment + payment_line
People::ContributionUpgrader.call(...) # Prorata + payment + payment_line
```

#### Payment Lines
- Un paiement peut contenir plusieurs lignes
- Chaque ligne référence un item (Membership, Plan, etc.)
- Traitement séquentiel de toutes les lignes

#### Anonymisation RGPD
```ruby
Payment#anonymize! # garde person_id, stocke original_person_identifier, marque anonymized_at
```

### Zone 2: En Cours de Validation

- [ ] Paiements en plusieurs fois

### Zone 3: Future

- [ ] Virements bancaires
- [ ] Chèques
- [ ] Aides sociales/gouvernementales

---

## 3. User & Authentication

### Zone 1: Comportement Défini

#### Création de Compte
- **Email required:** Unicité validée
- **Password:** Sécurisé avec bcrypt
- **CGU:** Acceptation obligatoire (sauf admin)
- **Privacy Policy:** Acceptation obligatoire (sauf admin)

#### Sessions
- **Session tokens:** Sécurisés, expirent
- **Password reset:** Token 15 min
- **Login/Logout:** Standard

#### Rôles Système
```ruby
enum system_role: [:super_admin, :admin, :volunteer, :web_visitor]
```

#### Person Architecture (Nouvelle)
- **Entity / Account pattern:**
  - **Person = Entity CRM** (identité unique, historique financier, soft delete via `SoftDeletable`).
  - **User = Account** (accès web) **toujours lié à une `Person`** (`belongs_to :person`, NOT NULL). Une Person peut exister sans User ; l’inverse non.
- **Conséquences :**
  - Création web : `People::Register` / `Web::UserRegistration` ou équivalent ; sinon callback sur `User` crée une **Person minimale** si absente.
  - Création admin : `People::Register` orchestre Person + User (+ Membership optionnel) ; `People::PersonCreator` disponible pour les scripts.
  - Rattachement / enrichissement : `People::AttachUserToPerson`, `People::AccountLinker`, fusions `People::AccountMerger`.
  - Suppression User : coupe l’accès web (`destroy`), la Person et ses paiements restent.
  - Suppression Person : passe par `UserManagement::UserDeleter` qui archive la Person (`Person#archive!`) seulement si aucune donnée financière (sauf super_admin). Tant qu’un `User` existe, `Person` ne peut pas être détruite implicitement (`restrict_with_error`).
- **Délégation:** User délègue attributs à Person (`delegate :full_name, :phone, ...`).

#### Tarifs Réduits
- **Attributs:** `reduced_rate_eligible`, `reduced_rate_reason`, `reduced_rate_proof`
- **Justificatifs:** RSA, Mineur, Situation Handicap, Étudiant, Autre
- **Usage:** Tracking pour statistiques et audit

### Zone 2: En Cours de Validation

- [ ] Account claiming workflow
- [ ] OAuth providers (Google, Facebook)
- [ ] 2FA/MFA

### Zone 3: Future

- [ ] SSO
- [ ] Gestion avancée permissions
- [ ] Audit de connexions

---

## 4. ContributionFormula (Formules de cotisation)

### Zone 1: Comportement Défini

#### Durées disponibles
```ruby
enum duration: {
  day: 0,           # Journée
  trimester: 1,     # Trimestre (≈ 90 jours)
  annual: 2,        # Annuel (365 jours)
  pack10: 3         # Pack de 10 séances
}
```

#### Pack10 (cas particulier)
- **Cotisation associée** : une `Contribution` est créée automatiquement après paiement.
- **Sessions** : nombre défini par la formule (`sessions_count`, par défaut 10).
- **Validité** : `validity_days` informatif. Le Pack 10 **n'expire pas** (`expires_at` nil).

#### Règles métier
- **Prix** : en centimes (`price_cents`).
- **Versionnage** : chaque formule est versionnée (`version`, `effective_from`, `effective_until`).
- **Disponibilité** : `ContributionFormula.available_for(person)` retourne les formules autorisées (actuellement : exige une `Membership` Cirque active).

### Zone 2: En cours de validation

- [ ] Formules personnalisées
- [ ] Promotions / codes réduction
- [ ] Pause de cotisation

### Zone 3: Futur

- [ ] Cotisations récurrentes automatiques
- [ ] Formules famille
- [ ] Offres groupées

---

## 5. Contribution (Cotisations)

> **Vocabulaire** : « cotisation » = `Contribution`.
>
> Le terme « carnet d'entrées » reste légitime quand on désigne explicitement le sous-type Pack 10. Pour parler du concept général, utiliser « cotisation ».

### Zone 1: Comportement Défini

> **Note métier** : dans l'usage actuel de l'association, la cotisation Pack 10 matérialise les séances restantes. Les attributs liés aux durées Trimestre / Annuel / Day restent portés par `Contribution`.

#### Création
- **Déclencheur** : paiement d'une `ContributionFormula` de type `pack10`.
- **Personne** : `belongs_to :person` (titulaire).
- **Sessions** : `sessions_remaining` initialisé à `sessions_count` (10 par défaut).

#### Utilisation
```ruby
Contribution#can_use?
  # - Adhésion Cirque active ?
  # - Sessions restantes > 0 ?
  # - Statut active ?

Contribution#use_session!
  # - Décrémente sessions_remaining
  # - Statut → consumed si 0
```

#### Expiration (Pack 10 uniquement)
- **Pack 10** : pas d'`expires_at` (durée infinie tant que sessions restantes).
- **Non-pack (legacy)** : expirerait selon `validity_days`. Hors périmètre runtime actuel.

#### Suspension & réactivation
```ruby
Contribution#suspend!(reason:)  # statut → suspended (cas upgrade Pack 10 → Trimestre / Annuel)
Contribution#reactivate!        # statut → active
Contribution.reactivate_suspended_packs_for_person(person)  # auto après expiration Trimestre / Annuel
```

#### Règles d'upgrade
- **Pack 10 → Trimestre / Annuel** : autorisé (Pack 10 suspendu, sessions conservées, **pas de prorata**).
- **Trimestre → Annuel** : autorisé (prorata temporel sur le temps restant).
- **Day → autre** : interdit.

### Zone 2: En cours de validation

- [ ] Transfert de séances entre cotisations
- [ ] Extension de validité

### Zone 3: Futur

- [ ] Cartes cadeaux
- [ ] Système de points

---

## 6. Events (Événements)

### Zone 1: Comportement Défini

#### Création Événement
- **Name/Title:** Requis (accès via attribut virtuel `title`)
- **Date:** Requise
- **Category:** Enum (default: circus)
  
> Implémentation admin: CRUD inline dans `Admin::EventsController` (plus de service EventManagement dans le flux admin).

#### Inscription
- **Person:** Une personne peut s'inscrire à un événement
- **EventAttendee:** Lien Person ↔ Event
- **Validation:** Unicité person_id + event_id

### Zone 2: En Cours de Validation

- [ ] Limite de places
- [ ] Listes d'attente
- [ ] Annulation/Rem placement

### Zone 3: Future

- [ ] Événements récurrents
- [ ] Invitations personnalisées
- [ ] Certificats de participation

---

## 7. Attendance (Présences)

### Zone 1: Comportement Défini

#### Types de Présences
- **Event attendance:** Person inscrite à un événement
- **Daily attendance:** Présence quotidienne (attendance_list)

#### Règles
- **Event:** Unicité person_id + event_id
- **Daily:** Unicité person_id + date (si pas event_id)

#### Contribution Integration
- **Auto-decrement:** Décrémente sessions_remaining si contribution liée
- **Can_use check:** Vérifie logique can_use? avant
- **Daily free training list:** `AttendanceListManagement::DailyListGenerator` crée chaque jour (hors lundi) la liste d'émargement « training » pour l'entraînement libre.

#### Check-in Entraînement Libre (Zone 1)
- **Service principal:** `AttendanceManagement::CheckInService`
  - Résout la personne (`person_id` ou `Current.user.person`).
  - Garantit l’existence d’une liste d’entraînement libre via `DailyListGenerator` (skip lundi).
  - Choisit automatiquement la cotisation utilisable (`pack10` prioritaire, sinon day pass, puis illimité) si `contribution_id` absent.
  - Délègue la création d’une présence à `AttendanceCreator`.
- **Instrumentation:** déclenche les événements `attendance.created`, `attendance.deleted`, `attendance_list.daily_created`.
- **Rôle de la cotisation:**
  - `use_session!` lors du check-in (décrément).
  - `refund_session!` via `AttendanceManagement::AttendanceRemover` en cas de suppression.
- **Présentations quotidiennes:** `AttendanceManagement::DailyFreeTrainingPresenter` assemble les métriques (total, pack10, day pass) pour le dashboard.
- **Flux utilisateur:**
  1. L’admin clique « check-in » → service check-in.
  2. La présence apparaît sur la liste du jour (Turbo stream).
  3. En cas d’annulation, `AttendanceRemover` détruit la présence + recrédite le carnet si applicable.
  4. Le dashboard consomme le presenter pour les stats.

> **Tests clés:**
> - `spec/services/attendance_management/check_in_service_spec.rb`
> - `spec/services/attendance_management/daily_list_generator_spec.rb`
> - `spec/services/attendance_management/attendance_remover_spec.rb`
> - `spec/services/attendance_management/daily_free_training_presenter_spec.rb`

### Zone 2: En Cours de Validation

- [ ] Présences groupées
- [ ] Système de badges
- [ ] Stats personnalisées

### Zone 3: Future

- [ ] QR codes pour check-in
- [ ] Géolocalisation
- [ ] Intégration calendrier

---

## 8. Member Numbers (Numéros d'Adhérent)

### Zone 1: Comportement Défini

#### Format
- **Pattern:** "25U001" (année + U/B + séquence)
  - U = Basique
  - C = Cirque
- **Assignment:** Automatique à la création membership via `Person#create_membership!`
- **Renouvellement:** Nouveau numéro chaque année (incrémenté depuis le début d'année)

#### History
- **Audit:** Tous les changements tracés dans MemberNumberHistory
- **Person:** Un numéro par personne (identifiant unique par année)
- **Changement:** Numéro change si changement catégorie (Basic ↔ Circus)

#### Méthodes
```ruby
MemberManagementService.assign_member_number(person, category) # Génération auto
MemberManagementService.generate_member_number(category) # Génération nouvelle
Person#handle_member_number_change!(old_type, new_type, recorded_by) # Upgrade
```

### Zone 2: En Cours de Validation

- [x] Réassignation de numéros ✅ (via upgrade)
- [ ] Numéros spéciaux

### Zone 3: Future

- [ ] Numéros personnalisés
- [ ] Intégration badges

---

## 9. Account Claims (Réclamations de Compte)

### Zone 1: Comportement Défini

#### Processus
- **Token:** Sécurisé, unique
- **Status:** pending → confirmed / rejected / expired
- **Expiry:** Expire après durée définie

#### Workflow
- Person sans User existant
- Génération token confirmation
- Email de réclamation
- Confirmation → Création User

### Zone 2: En Cours de Validation

- [ ] Expiry automatique
- [ ] Processus de rejet

### Zone 3: Future

- [ ] Auto-merge de comptes
- [ ] Vérification téléphone

---

## 10. Pricing (Tarification)

### Zone 1: Comportement Défini

#### Structure
- **PriceCatalog:** Catalogue de prix
- **PriceEntry:** Entrées individuelles
- **Versioning:** Gestion de versions

#### Logique
- Prix en centimes
- Historique des changements
- Effectivité par date

### Zone 2: En Cours de Validation

- [ ] Promotions temporaires
- [ ] Tarifs dégressifs

### Zone 3: Future

- [ ] Tarification dynamique
- [ ] A/B testing de prix

---

## 11. CMS (Blog)

### Zone 1: Comportement Défini

#### Articles
- **Blog:** Articles publiés
- **Tags:** Catégorisation
- **TagBlog:** Lien Blog ↔ Tag

#### Workflow
- Création par admin
- Publication/Non-publication
- Catégorisation

### Zone 2: En Cours de Validation

- [ ] Workflow de rédaction
- [ ] Prévisualisation

### Zone 3: Future

- [ ] Commentaires
- [ ] Newsletter automatisée depuis blog

---

## 12. Newsletter

### Zone 1: Comportement Défini

#### Table Dédiée: `newsletter_subscribers`
- **Indépendante de Person:** Newsletter peut exister sans compte
- **Tracking complet:** subscribed, subscribed_at, unsubscribed_at
- **Audit trail:** source (web/admin/import), notes
- **Merge automatique:** Link vers Person si email existe
- **Scopes:** subscribed, unsubscribed, orphaned, linked

#### Inscription
- **Service:** `People::NewsletterSignup` (remplace `NewsletterSignupService`)
- **Provider:** Mailjet
- **Opt-in:** Consentement requis
- **Instrumentation:** `people.newsletter_signed_up`, `people.newsletter_signup.skipped`, `people.newsletter_signup.failed`

#### Méthodes
```ruby
NewsletterSubscriber#unsubscribe!
NewsletterSubscriber#resubscribe!
NewsletterSubscriber#link_to_person!(person)
```

### Zone 2: En Cours de Validation

- [ ] Sélections de destinataires
- [ ] Templates

### Zone 3: Future

- [ ] A/B testing
- [ ] Analytics avancées

---

# Services Métier

## Services Zone 1 (Testés)

✅ `MemberManagementService` - Assignation numéros  
✅ `People::MembershipCreator` - Création adhésions  
✅ `People::MembershipUpgrader` - Upgrades membres  
✅ `People::ContributionCreator` - Création cotisations  
✅ `People::PaymentCreator` - Création paiements  
✅ `Admin::PaymentsService` - Filtrage/query paiements  
✅ `People::NewsletterSignup` - Inscriptions newsletter  

## Modèles Zone 1 (Testés)

✅ `Person#create_membership!` - Création adhésion + paiement + numéro  
✅ `Person#renew_membership!` - Renouvellement avec nouveau numéro  
✅ `Person#create_contribution!` - Création cotisation + paiement  
✅ `People::MembershipUpgrader` - Upgrade membership plein tarif
✅ `People::ContributionUpgrader` - Upgrade cotisation avec prorata
✅ `Contribution#suspend!` / `reactivate!` - Suspension cotisations  
✅ `Payment#anonymize!` - Marquage RGPD compatible DB

## Services Zone 2 (En Exploration)

⚠️ `UserManagement::UserCreator` - Création utilisateurs  

## Services Zone 3 (Obsolètes/Supprimés)

❌ `Payments::Process` - OBSOLÈTE (remplacé par Person-based logic)  
❌ `Memberships::Upgrade` - OBSOLÈTE (remplacé par People::MembershipUpgrader)  
❌ `PersonManagement::PersonCreator` - SUPPRIMÉ (remplacé par `People::PersonCreator`, plus aucune trace de `PersonManagement` dans `app/`)  
❌ `EventManagement::*` - SUPPRIMÉ (`app/services/event_management/` n'existe plus, CRUD inline dans `Admin::EventsController` — cf. ligne 305)  

---

# Plan d'Activation People::Register (2025-11-08)

## Objectif

Unifier la création Person → Membership → Payment autour d'un orchestrateur `People::Register` afin de supprimer la logique dupliquée dans les formulaires admin et les services historiques.

## Architecture Cible

```
Admin::UserCreationForm
  └── People::Register.call
        ├── People::PersonCreator
        ├── People::UserAccountCreator (optionnel)
        └── People::MembershipCreator (paiement inclus)
```

## Étapes

1. **Recréer les services** `people/person_creator.rb`, `user_account_creator.rb`, `membership_creator.rb`, `register.rb` conformément aux specs.
2. **Brancher le dashboard** : remplacer la logique inline de `Admin::UserCreationForm` (et assimilés) par un appel unique à `People::Register`.
3. **Nettoyer les doublons** : supprimer les créations directes (`Person.create!`, `person.create_membership!`, etc.) hors services People::*.
4. **Réactiver les tests** : ajouter `shoulda-matchers`, `rails-controller-testing`, puis réhabiliter progressivement `spec/disabled/**`.
5. **Documenter les flux** : MAJ des diagrammes et du changelog une fois l'activation terminée.

## Contrôles

- Grep régulier sur `app/` pour s'assurer que les créations passent par `People::Register`.
- Vérification UI : création depuis `/admin/users/new`, upgrade membership, paiement manuel.
- Instrumentation disponible : évènement `people.register` (success/failure) + logs `Rails.logger` pour audit.

## Statut (2025-11-08)

- **Logique écrite :** ✅ services `People::PersonCreator`, `UserAccountCreator`, `MembershipCreator`, `MembershipUpgrader`, `MembershipUpdater`, `MembershipDeactivator`, `Register`, `Payment*`, `Contribution*`
- **Branchée UI :** ✅ Admin (`Admin::UserCreationForm`, `Admin::MembershipsController`, `Admin::PaymentsController`, `Admin::ContributionFormulasController`) & Web (`Web::UserRegistration`) délèguent aux services People::*
- **Tests :** ✅ `bundle exec rspec` (1054 exemples, 0 échec)
- **Coverage :** ✅ 53.9 % (seuil SimpleCov 12 % respecté)

## Actions de migration (en cours)

1. ✅ **Réactivation complète** des suites RSpec (`bundle exec rspec`)
    - `spec/services/member_management_service_spec.rb`
    - `spec/models/person_spec.rb`
2. ✅ **Brancher tous les flux d’adhésion** sur `People::*`
    - `Web::UserRegistration` → `People::Register`
    - `MembershipManagement::MembershipCreator/Updater/Deactivator/Upgrader` → `People::Membership*`
3. ⏳ **Prochaines priorités**
    - Mettre à jour `docs/internal/ux_audit_2025_01.md` / guides internes (nouvelle architecture People)
    - ✅ Migrer seeds (`db/seeds/sample_people.rb`, `db/seeds/bulk_users.rb`, `db/seeds/add_memberships_and_payments.rb`, `db/seeds/admin.rb`) sur services People
    - ✅ Mettre à jour scripts de test (`scripts/test_person_first_refactoring.rb`, `scripts/test_all_scenarios.rb`) pour consommer `People::Register`
    - ⚠️ Documenter / refondre les scripts legacy (`scripts/fix_person_user_merge.rb`, tâches rake de migration) vers les futurs services `People::AccountLinker`
    - Exploiter instrumentation/logging `people.register` en staging + plan de nettoyage des services historiques

## Nettoyage futur

- Finaliser le retrait de `UserManagement::AccountCreator` lorsque plus aucune dépendance directe ne subsiste.
- `People::PersonCreator` ne fusionne plus automatiquement les fiches : les créations sans `existing_person` échouent désormais si l'email ou le téléphone est déjà utilisé, ce qui protège les données CRM du dashboard admin.
- `People::PaymentCreator` et `People::ContributionCreator` centralisent la création des paiements / cotisations (les services historiques `PaymentManagement::*` et `SubscriptionManagement::*` ont été retirés).
- `People::AccountLinker` gère la reliaison manuelle Person/User avec instrumentation (`people.account_linked`).
- Retirer les appels directs à `Person#create_membership!` en dehors de `People::MembershipCreator`.
- Supprimer les services historiques restants (ex. `Payments::Process`) une fois la migration terminée.
- Réviser les seeds et scripts (`db/seeds`, `scripts/`) pour utiliser les nouveaux services.
- Encapsuler les scripts CRM spéciaux (merge/link) via `People::AccountLinker` ou futurs services dédiés.

## Correspondance services (ancien → nouveau)

| Ancien service / form | Nouveau service People::* | État |
| --- | --- | --- |
| `Admin::UserCreationForm` + logique inline | `People::Register` (dashboard) | ✅ Branché |
| `PersonManagement::PersonCreator` (backend, web) | `People::PersonCreator` | ❌ Supprimé |
| `UserManagement::AccountCreator` | `People::UserAccountCreator` | ❌ Supprimé |
| `UserManagement::UserCreator` | `People::UserAccountCreator` | ✅ Branché |
| `People::AccountLinker` (script merge) | `People::AccountLinker` (+ `People::AttachUserToPerson`) | ✅ Branché |
| `MembershipManagement::MembershipCreator` | `People::MembershipCreator` | ❌ Supprimé |
| `MembershipManagement::MembershipUpgrader` | `People::MembershipUpgrader` | ❌ Supprimé |
| `MembershipManagement::MembershipUpdater` | `People::MembershipUpdater` | ❌ Supprimé |
| `MembershipManagement::MembershipDeactivator` | `People::MembershipDeactivator` | ❌ Supprimé |
| `Person#create_membership!` appels directs | `People::MembershipCreator` | 🔄 à généraliser |
| `Web::UserRegistration` (PersonManagement + AccountCreator) | `People::Register` | ✅ Branché |
| `PaymentManagement::PaymentCreator/WithLines` | `People::PaymentCreator` | ❌ Supprimé |
| `PaymentManagement::PaymentUpdater` | `People::PaymentUpdater` | ❌ Supprimé |
| `PaymentManagement::PaymentDeleter` | `People::PaymentCanceller` | ❌ Supprimé |
| `PaymentManagement::PaymentRestorer` | `People::PaymentRestorer` | ❌ Supprimé |
| `SubscriptionManagement::SubscriptionCreator` | `People::ContributionCreator` | ❌ Supprimé |
| `SubscriptionManagement::SubscriptionUpgrader` | `People::ContributionUpgrader` | ❌ Supprimé |
| Scripts/Seeds divers | `People::Register` (legacy scripts à convertir) | ⏳ En cours |

---

# Validation & Tests

## Stratégie par Zone

### Zone 1 → Tests Immédiats
```
✅ Validations critiques
✅ Associations importantes
✅ Logique métier définie
✅ Workflows complets
```

### Zone 2 → Tests Après Stabilisation
```
⏳ Attendre validation business
⏳ Écrire tests quand logique stable
⏳ Documentation comportement temporaire
```

### Zone 3 → Pas de Tests
```
❌ Pas de code = pas de tests
❌ Spécification uniquement
```

---

# Notes Importantes

## Architecture Actuelle

**Person-Based:** `User` `belongs_to` `Person` (obligatoire) ; `Person` `has_one` `User` (optionnel). Relation 1‑to‑0..1 du point de vue Person.  
**Résultat:** Séparation données authentification vs profil, sans « User sans Person » en base.

## Concerns Utilisés

- `Statusable` - Gestion statuts (expired?, active?, etc.)
- `Dateable` - Gestion dates
- `Roleable` - Gestion rôles et permissions
- `Humanizable` - Affichage humain
- `Versionable` - Versioning des données

## Intégrations

- **Stripe:** Paiements
- **Mailjet:** Emails/Newsletter
- **Kamal:** Déploiement

---

**Prochaine Révision:** Après stabilisation des Zones 2  
**Dernière Mise à Jour:** 2025-11-09

---

## Changelog Récent

### Consolidation People + DRY (2025-11-09)

- Admin: CRUD inline pour `MembershipTypes`, `ContributionFormulas`, `Events` (abandon des services *Management* sur ces flux).
- Formules: `ContributionFormula.available_for(person)` unifie la sélection des formules autorisées.
- UI: Options de méthode de paiement centralisées via helper.
- Instrumentation: événements ajoutés pour adhésions, cotisations, newsletter.
- Seeds/Tasks: migration des Person sans adhésion via `Person#create_membership!`.
- Nettoyage: suppression des reliques `Payments::Process` (désactivés).

### Réécriture Complète Logique Métier (2025-11-03)

**Upgrades d'Adhésions:**
- **Changement:** Upgrade = **plein tarif** du nouveau type (pas de prorata)
- **Impact:** Basic 1€ → Circus Réduit 7€ = payer 7€ (pas 6€)
- **Méthode:** `People::MembershipUpgrader` - Facture `new_type.price_cents`

**Renouvellements:**
- **Nouveau:** `Person#renew_membership!` - Crée nouvelle adhésion + **nouveau numéro d'adhérent**
- **Impact:** Chaque année, incrémente numéro (25U001 → 25U002 → ...)
- **Historique:** Tous changements tracés dans MemberNumberHistory

**Prorata Cotisations:**
- **Contrôleur:** `Person#upgrade_contribution!`
- **Jour → autre plan:** interdit (journée non cumulable, pas d’upgrade possible)
- **Pack10 → Trimestre/Année:** pack suspendu (sessions conservées), **pas** de prorata — on paie le nouveau plan plein tarif
- **Trimestre → Année:** prorata temporel appliqué (montant Année – valeur temps restant sur Trimestre)
- **Réactivation automatique:** Pack10 suspendu se réactive une fois le Trimestre/Année arrivé à expiration
- **Durées:**
  - `day` : `purchased_at` à fin de journée (`end_of_day`)
  - `trimester` : 3 mois (≈90 jours) à partir de `purchased_at`
  - `annual` : 1 an à partir de `purchased_at`
  - `pack10` : pas d’expiration (`expires_at` nil) ; suspendu si upgrade
- **Suspension/Expiration:**
  - Si l’adhésion (`membership`) expire, toutes les cotisations associées (`Contribution`) sont suspendues jusqu’à renouvellement/adhésion active.
  - Réactivation automatique quand une nouvelle adhésion circus redevient active.

**Tarifs Réduits:**
- **Nouveau:** Attributs `reduced_rate_eligible`, `reduced_rate_reason`, `reduced_rate_proof` sur Person
- **UI:** Formulaire Stimulus toggle pour justificatif
- **Affichage:** Carte bleue dans UserInfoComponent si éligible

**Anonymisation RGPD:**
- **Nouveau:** `Payment#anonymize!` - garde `person_id`, stocke un hash de traçabilité, marque `anonymized_at`
- **Usage:** marquage d'anonymisation sans casser l'historique CRM/comptable

**Seed Amélioré:**
- **Nouveau:** `db/seeds/add_memberships_and_payments.rb` - Utilise logique métier complète
- **Résultat:** 53 membres avec numéros + paiements + historique correct

### Simplification Architecture (2025-01-31)

**MembershipType category enum:**
- **Avant:** `basic`, `circus_full`, `circus_reduced` (3 catégories confuses)
- **Après:** `basic`, `circus`, `event` (3 catégories claires)
- **Impact:** Circus Full et Reduced sont des tarifs, pas des catégories distinctes
- **Avantage:** Ajout facile de tarifs Circus (Student, Senior, etc.) sans modifier code

**Newsletter:**
- **Nouveau:** Table `newsletter_subscribers` dédiée
- **Avant:** Booléen sur Person
- **Avantage:** Tracking indépendant, merge email simplifié, audit trail complet

**Payment relations:**
- **Supprimé:** Legacy `user_id`, `order_id`
- **Conservé:** Architecture Person-Based uniquement
- **Avantage:** Tests simplifiés -50% complexité

**Score modèle:** 7/10 → 9/10 ✅

### Architecture Services (2025-01)

**Pattern:** Controller → Service → Model

**Services créés (44 services dans 15 domaines):**
- `MembershipManagement::*` (4 services) – supprimés au profit de `People::Membership*`
- `SubscriptionManagement::*` (2 services)
- `
