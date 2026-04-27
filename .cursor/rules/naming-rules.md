# Règles de nommage globales — Le Circographe

Source canonique : [`docs/glossary.md`](../../docs/glossary.md). Ces règles sont appliquées en revue de PR.

---

## 1. Modèles, services, composants

| Concept métier | Nom canonique | Anti-nom |
| --- | --- | --- |
| Personne (CRM) | `Person` | `Customer`, `Member` |
| Compte web | `User` | `Account` |
| Adhésion (annuelle) | `Membership` | `Subscription` |
| Type d'adhésion | `MembershipType` | `MembershipPlan`, `Article*` |
| Cotisation (cirque) | `Contribution` *(code actuel : `BookOfEntry`)* | `Subscription`, `EntryBook` |
| Formule de cotisation | `ContributionFormula` *(code actuel : `SubscriptionPlan`)* | `SubscriptionPlan`, `Plan` |
| Paiement | `Payment` | `Transaction`, `Order` |
| Ligne de paiement | `PaymentLine` | `LineItem`, `Charge` |
| Don | `Donation` | `Gift`, `Tip` |
| Présence | `Attendance` | `Visit`, `CheckIn` |
| Liste de présence | `AttendanceList` | `Roster`, `Sheet` |
| Événement | `Event` | `Activity`, `Session` |
| Inscription événement | `EventAttendee` | `Participant`, `Registration` |
| Newsletter | `NewsletterSubscriber` | `MailingListEntry` |

**Règles** :
- Noms de classes : PascalCase, anglais aligné sur le glossaire.
- Services orchestrateurs : `People::*` pour tout ce qui touche `Person` (création, paiement, adhésion, cotisation, don).
- Composants ViewComponent : `<noun>_<role>_component.rb` (snake_case Zeitwerk).

---

## 2. Méthodes (Ruby)

- snake_case strict, anglais.
- Le verbe en premier (`create_membership!`, pas `membership_create!`).
- Bang (`!`) pour les méthodes qui mutent ou peuvent lever.
- Question (`?`) pour les prédicats.
- Pas de double négation (`active?` ✅, `not_inactive?` ❌).

| Concept | Méthode canonique | Anti-méthode |
| --- | --- | --- |
| Adhésion active ? | `Person#active_membership?` | `has_membership?` |
| Cotisation active ? | `Person#active_contribution?` *(actuel : `active_subscription?`)* | `subscribed?` |
| Cotisation courante | `Person#current_contribution` *(actuel : `current_subscription`)* | `latest_subscription` |
| Rôles subordonnés | `User#subordinate_roles` *(actuel : `inferior_rights`)* | `lower_roles`, `weaker_rights` |
| Création d'adhésion | `Person#create_membership!(type, ...)` | `Person#new_membership` |

---

## 3. Enums

- Toujours en `:symbol` snake_case anglais.
- Zéro doit représenter un état neutre / par défaut quand possible.
- Pas de fourre-tout (`other`, `misc`).

| Enum | Valeurs canoniques |
| --- | --- |
| `Membership.status` | `:pending, :inactive, :active, :expired` |
| `Contribution.status` *(`BookOfEntry.status`)* | `:inactive, :active, :expired, :consumed, :suspended` |
| `Payment.status` | `:pending, :success, :cancel` |
| `Payment.payment_method` | `:cash, :card, :cheque, :transfer, :offered` |
| `User.system_role` | `:web_visitor, :volunteer, :admin, :super_admin` |
| `MembershipType.category` | `:basic, :circus, :event` |
| `ContributionFormula.duration` *(`SubscriptionPlan.duration`)* | `:day, :trimester, :annual, :pack10` |
| `AttendanceList.status` | `:open, :close, :archived` |

---

## 4. Colonnes DB

- snake_case anglais.
- Dates : suffixe `_at` (timestamps précis) ou `_on` (jours).
- Quantités monétaires : suffixe `_cents` (Integer).
- Booléens : préfixe explicite (`is_*`, `has_*`, `was_*`).
- Polymorphic : `<role>_type` + `<role>_id` (ex. `item_type` + `item_id`).

**Conventions de migration** :
- Toute nouvelle colonne dans le périmètre cotisation doit utiliser le mot **`contribution`** (pas `subscription`, sauf pour la table newsletter).
- `payment_lines.item_type` n'accepte que : `Membership`, `MembershipType`, `ContributionFormula` *(actuel : `SubscriptionPlan`)*, `Contribution` *(actuel : `BookOfEntry`)*, `Donation`. Toute valeur `"Payment"` est interdite (legacy à éliminer en `phase1-donation-fix`).

---

## 5. Termes interdits en revue

- `subscription` (sauf newsletter) → utiliser `contribution`.
- `SubscriptionPlan` dans la doc nouvelle → utiliser `ContributionFormula`.
- `BookOfEntry` dans la doc nouvelle (sauf désigner explicitement le sous-type Pack 10) → utiliser `Contribution`.
- `inferior_rights` → utiliser `subordinate_roles`.
- `item_type: "Payment"` pour un don → utiliser `"Donation"`.
- « article d'adhésion » / « article de cotisation » → utiliser « type d'adhésion » / « formule de cotisation ».
- `UserMembership` → utiliser `Membership` (lié à `Person`).

---

## 6. Documentation

- Quand un nom de classe / colonne / méthode est désaligné avec le vocabulaire cible, **ne jamais** masquer le décalage : utiliser la forme `Contribution (code actuel : BookOfEntry)`.
- Quand le code est aligné, supprimer les mentions « code actuel : … » du document (cf. `phase3-model-rename`).

---

## 7. Liens utiles

- [docs/glossary.md](../../docs/glossary.md)
- [docs/domain_model.md](../../docs/domain_model.md)
- [docs/payments.md](../../docs/payments.md)
- [docs/migrations/vocabulary_migration.md](../../docs/migrations/vocabulary_migration.md)
