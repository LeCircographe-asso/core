# Modèle de Domaine — Le Circographe

> **Statut** : stable
> **Public cible** : contributeur
> **Dernière vérification** : 2026-05-01
> **Sources de vérité** : `db/schema.rb`, `app/models/person.rb`, `app/models/membership.rb`, `app/models/payment.rb`, `app/models/payment_line.rb`.

> Vocabulaire utilisé : voir [glossary.md](glossary.md).
> **Pattern** : Person-Based / DDD-light.

---

## 1. Vue d'ensemble

```mermaid
erDiagram
  Person ||--o| User : "≤1 compte web par Person"
  Person ||--o{ Membership : "souscrit"
  Person ||--o{ Contribution : "achète"
  Person ||--o{ Attendance : "présence"
  Person ||--o{ Payment : "règle"
  Person ||--o{ EventAttendee : "inscrit"
  Person ||--o| NewsletterSubscriber : "lié par email"

  MembershipType ||--o{ Membership : "type"
  ContributionFormula ||--o{ Contribution : "formule"
  Event ||--o{ EventAttendee : "inscriptions"
  AttendanceList ||--o{ Attendance : "regroupe"

  Payment ||--o{ PaymentLine : "contient"
  PaymentLine }o..|| Membership : "polymorphic item"
  PaymentLine }o..|| ContributionFormula : "polymorphic item"
  PaymentLine }o..|| MembershipType : "polymorphic item"
  PaymentLine }o..|| Donation : "polymorphic item (cible)"

  Person ||--o{ MemberNumberHistory : "audit numéro"
  Payment ||--o{ PaymentAuditLog : "audit transactionnel"
```

> **Légende** :
> - `Contribution` et `ContributionFormula` sont les noms canoniques actuels.
> - `Donation` n'a pas de table dédiée ; elle est représentée par `PaymentLine.item_type = "Donation"`.

---

## 2. Responsabilités par agrégat

### 2.1 Personnes et comptes

#### `Person` — Aggregate Root CRM
- **Compte web** : `has_one :user, dependent: :restrict_with_error` — au plus un `User` ; pas de suppression « dure » de la fiche tant qu'un compte web existe (flux RGPD / archive à utiliser).
- **Identité** : `full_name`, `phone`, `email`, `address`, `birth_date`.
- **Tarif réduit** : `reduced_rate_eligible`, `reduced_rate_reason`, `reduced_rate_proof`.
- **Soft delete** : `deleted_at` (concern `SoftDeletable`).
- **Méthodes métier** :
  - `People::MembershipCreator` — adhésion + paiement + numéro d'adhérent.
  - `People::MembershipUpgrader` — plein tarif du nouveau type.
  - `Person#renew_membership!(...)` — nouvelle adhésion + nouveau numéro annuel.
  - `People::ContributionCreator` — création cotisation + paiement.
  - `People::ContributionUpgrader` — upgrade cotisation + paiement.
  - `Person#archive!` / `Person#restore!`.
- **Garde-fou** : `has_financial_data?` empêche la suppression dure si l'historique financier est non vide.

#### `User` — Compte web
- **Invariant** : `belongs_to :person` **obligatoire** en base (`users.person_id` NOT NULL). À la création sans `person` explicite, le modèle attache une `Person` minimale (prénom/nom stub + email aligné sur le compte).
- **Authentification** : email, password, sessions, password_reset_token.
- **Rôle** : `system_role` enum `:super_admin | :admin | :volunteer | :web_visitor`.
- **Délégation** : `delegate :full_name, :phone, ... to: :person`.
- **Liaison / fusion** : rattachement nominal `People::AttachUserToPerson` ; orchestration admin/scripts `People::AccountLinker` ; fusion de fiches `People::AccountMerger`.
- **Soft delete** : `User#archive!` (admin uniquement).

---

### 2.2 Adhésion

#### `Membership` — Contrat annuel
- **Lien** : `belongs_to :person`, `belongs_to :membership_type`.
- **Dates** : `started_at`, `ended_at` (1 an par défaut).
- **Statuts** : `:pending → :active → :inactive → :expired`.
- **Validations** : `ended_at > started_at`, pas d'overlap actif (sauf `skip_overlap_validation`).
- **Méthodes** : `#can_upgrade_to?(type)`, `#upgrade_to!(type, started_at)`, `#basic?`, `#circus?`.

#### `MembershipType` — Catalogue versionné
- **Champs** : `name`, `category` (`:basic | :circus | :event`), `price_cents`, `version`, `effective_from`, `effective_until`, `created_by_user_id`, `change_reason`.
- **Concern** : `Versionable`.

---

### 2.3 Cotisation (accès cirque)

#### `Contribution` — Instance achetée
- **Lien** : `belongs_to :person`, `belongs_to :contribution_formula`.
- **Champs** : `sessions_remaining` (Pack 10 uniquement), `purchased_at`, `expires_at`, `status`.
- **Statuts** : `:inactive | :active | :expired | :consumed | :suspended`.
- **Méthodes** :
  - `#can_use?` — vérifie adhésion Cirque active + sessions restantes.
  - `#use_session!` — décrémente `sessions_remaining` (Pack 10).
  - `#refund_session!` — recrédite (annulation présence).
  - `#suspend!(reason:)` / `#reactivate!`.
- **Note** : `day` est une cotisation à usage unique valable jusqu'à la fin du jour d'achat ; `trimester` et `annual` restent des cotisations à durée avec expiration.

#### `ContributionFormula` — Catalogue versionné
- **Champs** : `name`, `duration` enum (`:day | :trimester | :annual | :pack10`), `price_cents`, `sessions_count`, `validity_days`, `version`, `effective_from`, `effective_until`.
- **Méthode** : `.available_for(person)` — exige une adhésion Cirque active.

---

### 2.4 Paiements et dons

#### `Payment` — Transaction
- **Lien** : `belongs_to :person`, `belongs_to :recorded_by, class_name: "User"`.
- **Champs** : `total_cents`, `status` (`:pending | :success | :cancel`), `payment_method` (`:cash | :card | :cheque | :transfer | :offered`), `uuid`, `notes`.
- `offer_reason` est persisté dans `payments` et requis pour un paiement `:offered`.
- **RGPD** : `Payment#anonymize!` garde `payments.person_id`, stocke un hash de traçabilité dans `original_person_identifier` et marque `anonymized_at`.
- **Audit** : `PaymentAuditLog`.

#### `PaymentLine` — Ligne polymorphique
- **Champs** : `payment_id`, `item_type`, `item_id`, `amount_cents`, `description`.
- **Items canoniques** : `Membership`, `MembershipType`, `ContributionFormula`, `Contribution`, `Donation`.
- **Invariant** : `payment.payment_lines.sum(:amount_cents) == payment.total_cents`.

#### `Donation`
- Pas de table dédiée. Représenté par une `PaymentLine` avec `item_type: "Donation"` à la création (`People::PaymentRecorder`). Vérifier les données historiques `item_type: "Payment"` avant suppression de compatibilité — voir [payments.md](payments.md).

---

### 2.5 Présences et événements

#### `Attendance`
- **Lien** : `belongs_to :person`, `belongs_to :attendance_list` (optionnel), `belongs_to :event` (optionnel), `belongs_to :contribution` (alias legacy `book_of_entry`).
- **Règles d'unicité** : `person_id + date` (entraînement libre) ou `person_id + event_id` (événement).
- **Effet de bord** : décrémente la cotisation utilisée si applicable.

#### `AttendanceList`
- **Statuts** : `:open | :close | :archived`.
- **Génération quotidienne** : `AttendanceListManagement::DailyListGenerator` (skip lundi).

#### `Event` & `EventAttendee`
- **Event** : `name`, `event_date`, `category` (default: `:circus`).
- **EventAttendee** : jointure `Person × Event` avec unicité `person_id + event_id`.

---

### 2.6 Audit et CRM

#### `MemberNumberHistory`
- Trace tout changement de numéro d'adhérent (`from_number`, `to_number`, `reason`, `changed_by`).

#### `PaymentAuditLog`
- Trace toute opération sur `Payment` (création, annulation, restauration, anonymisation).

#### `AccountClaim`
- Workflow de réclamation de compte : `:pending → :confirmed | :rejected | :expired` avec token sécurisé.

#### `NewsletterSubscriber`
- Table indépendante de `Person`. Lien automatique si l'email correspond.

---

## 3. Diagramme des cycles de vie

### 3.1 Adhésion

```mermaid
stateDiagram-v2
  [*] --> pending : create_membership
  pending --> active : paiement réussi
  active --> inactive : upgrade vers nouveau type
  inactive --> [*] : remplacée
  active --> expired : ended_at < today
  expired --> [*] : renew_membership crée nouvelle
```

### 3.2 Cotisation (`Contribution`)

```mermaid
stateDiagram-v2
  [*] --> active : create_contribution
  active --> consumed : sessions_remaining == 0 (Pack 10)
  active --> expired : expires_at < today (non Pack 10)
  active --> suspended : adhésion Cirque expirée
  suspended --> active : nouvelle adhésion Cirque active
  active --> suspended : upgrade Pack 10 → Trimestre/Annuel
```

### 3.3 Paiement

```mermaid
stateDiagram-v2
  [*] --> pending : create_payment
  pending --> success : success!
  pending --> cancel : cancel!
  success --> [*]
  cancel --> [*]
```

---

## 4. Flux de création (orchestration `People::Register`)

```mermaid
sequenceDiagram
  participant UI as Admin UI
  participant Reg as People::Register
  participant PC as People::PersonCreator
  participant UAC as People::UserAccountCreator
  participant MC as People::MembershipCreator
  participant PayR as People::PaymentRecorder

  UI->>Reg: call(person_attrs, user_attrs?, membership_type_id?)
  Reg->>PC: create Person
  PC-->>Reg: Person
  alt user_attrs présents
    Reg->>UAC: create User pour Person
    UAC-->>Reg: User
  end
  alt membership_type_id présent
    Reg->>MC: create Membership + Payment
    MC->>PayR: create Payment + PaymentLine
    PayR-->>MC: Payment
    MC-->>Reg: Membership
  end
  Reg-->>UI: success(person, user?, membership?)
```

> **Inscription web** : les flux qui ne passent pas par `People::Register` créent tout de même un couple `User` + `Person` via le callback `User` (personne minimale), puis enrichissement CRM au fil du temps.

---

## 5. Documents liés

- [glossary.md](glossary.md) — vocabulaire canonique.
- [payments.md](payments.md) — détail Payment / PaymentLine / Donation.
- [migrations/vocabulary_migration.md](migrations/vocabulary_migration.md) — mapping ancien → nouveau.
- [domain/business_logic.md](domain/business_logic.md) — règles métier complètes.
- [architecture/services.md](architecture/services.md) — services `People::*` et orchestrateurs (`Register`, `AttachUserToPerson`, `AccountLinker`, paiements).
