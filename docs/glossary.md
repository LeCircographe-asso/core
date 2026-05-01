# Lexique Métier — Le Circographe

> **Statut** : stable (canonique)
> **Public cible** : contributeur, métier
> **Dernière vérification** : 2026-05-01
> **Sources de vérité** : `app/models/*.rb`, `db/schema.rb`, [`migrations/vocabulary_migration.md`](migrations/vocabulary_migration.md).

> **Source de vérité unique** pour le vocabulaire du domaine. Toute nouvelle PR (code, doc, UI, tests) doit utiliser ce vocabulaire. Les termes listés en section « Termes interdits » sont rejetés en revue. Utilisé pendant la migration `phase0` → `phase4`.

---

## 1. Lexique canonique

### 1.1 Personnes et comptes

#### Personne — `Person`
- **Définition** : entité CRM unique. Source de vérité pour l'identité (nom, email, téléphone, adresse) et pour tout l'historique financier (adhésions, cotisations, paiements, dons). Soft-delete via `Person#archive!` (concern `SoftDeletable`) avec garde-fou `has_financial_data?`.
- **Cycle de vie** : créée à la première interaction (inscription web, papier, paiement IRL). Persiste même quand le compte web est supprimé.
- **Usage correct** :
  - « Créer une personne via `People::PersonCreator` ».
  - « La personne `Person#full_name` a payé son adhésion en cash ».
- **À éviter** :
  - « Créer un utilisateur sans compte web » → utiliser « créer une personne ».
  - Confondre `Person` avec `User`.

#### Compte web — `User`
- **Définition** : compte d'authentification web (email, mot de passe, rôle système). **Chaque `User` est obligatoirement relié à une `Person`** (`belongs_to :person`, `person_id` NOT NULL) ; une `Person` peut exister **sans** `User` (adhésion papier, mineurs, etc.). Tous les attributs de profil (`full_name`, `phone`…) sont délégués vers `Person`.
- **Cycle de vie** : créé via `People::UserAccountCreator` ou callback sur `User` (personne minimale) puis enrichissement CRM ; rattachement explicite via `People::AttachUserToPerson` / `People::AccountLinker`. La suppression du compte (`User#destroy`) coupe l'accès web mais laisse intact le `Person` et son historique (tant que les flux RGPD ne désactivent pas autrement).
- **Usage correct** :
  - « Cette personne n'a pas encore de compte web ».
  - « Le compte web a été archivé, la fiche personne reste active ».
- **À éviter** :
  - « Utilisateur » employé pour désigner la fiche métier (utiliser « personne »).
  - Considérer `User` comme la source de vérité.

---

### 1.2 Adhésion

#### Adhésion — `Membership`
- **Définition** : contrat annuel donnant à une `Person` le statut de membre de l'association, lié à un `MembershipType` (Basic / Cirque Plein / Cirque Réduit). Statuts : `pending → active → inactive → expired`. Une seule adhésion active par personne (validation d'overlap).
- **Cycle de vie** : créée via `People::MembershipCreator`, upgrade via `People::MembershipUpgrader` (plein tarif du nouveau type, pas de prorata), renouvellement via `Person#renew_membership!` (nouveau numéro d'adhérent annuel).
- **Usage correct** :
  - « Adhésion Cirque Tarif Réduit active jusqu'au 31/12/2026 ».
  - « Upgrade Basic → Circus : 7 € (plein tarif Cirque Réduit) ».
- **À éviter** :
  - « Abonnement » pour parler d'une adhésion.
  - Confondre adhésion (statut associatif annuel) et cotisation (accès cirque).

#### Type d'adhésion — `MembershipType`
- **Définition** : catalogue versionné des tarifs d'adhésion (`category: :basic | :circus | :event`). Versionnage via `version`, `effective_from`, `effective_until`.
- **Usage correct** :
  - « Le `MembershipType` Cirque Tarif Réduit est à 7 € depuis le 01/01/2026 ».
- **À éviter** :
  - « Article d'adhésion » (concept introduit dans certains seeds, non canonique).

---

### 1.3 Cotisation (accès cirque)

#### Formule de cotisation — `ContributionFormula` (cible) / `SubscriptionPlan` (legacy)
- **Définition** : catalogue versionné des formules d'accès cirque. Quatre durées : `:day` (journée), `:trimester` (≈90 j), `:annual` (1 an), `:pack10` (10 séances). Versionnage identique à `MembershipType`.
- **Disponibilité** : `ContributionFormula.available_for(person)` ne retourne que les formules autorisées (actuellement : exige une adhésion Cirque active).
- **Usage correct** :
  - « La formule Pack 10 coûte 30 € et donne 10 séances ».
  - « Trois formules sont actives : Journée (4 €), Trimestre (60 €), Annuel (120 €) ».
- **À éviter** :
  - « Plan d'abonnement » → utiliser « formule de cotisation ».
  - `SubscriptionPlan` dans la nouvelle documentation (rester à `ContributionFormula` + alias legacy uniquement quand on parle du code actuel).
  - « Article de cotisation » (concept seed non canonique).

#### Cotisation — `Contribution` (cible) / `BookOfEntry` (legacy)
- **Définition** : instance achetée par une `Person`, dérivée d'une `ContributionFormula`. Matérialise le droit d'accès cirque effectivement payé.
  - Pack 10 : `sessions_remaining` initialisé à `sessions_count` (10 par défaut), pas d'expiration (`expires_at = nil`).
  - Trimestre / Annuel / Day : `sessions_remaining = nil`, expiration via `expires_at`.
- **Cycle de vie** : créée via `People::ContributionCreator` (legacy : `People::SubscriptionCreator`). Suspension automatique si l'adhésion Cirque expire ; réactivation à la souscription d'une nouvelle adhésion active.
- **Règles d'upgrade** :
  - Pack 10 → Trimestre / Annuel : Pack 10 suspendu (sessions conservées), nouvelle cotisation au plein tarif, **pas de prorata**.
  - Trimestre → Annuel : prorata temporel (montant Annuel − valeur du temps restant sur Trimestre).
  - Day non upgradable.
- **Usage correct** :
  - « La cotisation Pack 10 d'Alice a 7 séances restantes ».
  - « Bob a une cotisation Annuelle qui expire le 15/06/2027 ».
- **À éviter** :
  - `BookOfEntry` dans la nouvelle documentation. Le code utilise encore ce nom : indiquer « code actuel : `BookOfEntry` » uniquement quand nécessaire.
  - « Carnet » sauf pour spécifier le sous-type Pack 10. « Cotisation Pack 10 » est préféré.
  - « Subscription » (anglicisme commercial — cf. § 1.7).
  - « Abonnement » (terme commercial inadapté à une asso loi 1901).

---

### 1.4 Paiements et dons

#### Paiement — `Payment`
- **Définition** : transaction financière unique regroupant **une ou plusieurs** `PaymentLine`. Méthodes : `:cash`, `:card`, `:cheque`, `:transfer`, `:offered`. Statuts : `:pending → :success | :cancel`. Anonymisation RGPD via `Payment#anonymize!`.
- **Usage correct** :
  - « Paiement de 17 € : 7 € adhésion + 10 € cotisation ».
  - « Paiement offert (`:offered`) avec `offer_reason` obligatoire ».

#### Ligne de paiement — `PaymentLine`
- **Définition** : ligne polymorphique d'un paiement. Référence un item via `item_type` + `item_id`.
- **Valeurs canoniques de `item_type`** :
  - `"Membership"` → adhésion créée par ce paiement.
  - `"MembershipType"` → renouvellement / achat sur le catalogue.
  - `"ContributionFormula"` (cible) / `"SubscriptionPlan"` (legacy) → achat d'une cotisation.
  - `"Contribution"` (cible) / `"BookOfEntry"` (legacy, rare) → cotisation existante.
  - `"Donation"` → don. **Création** : `People::PaymentCreator` conserve `"Donation"` sur les lignes de don. Des lignes **historiques** peuvent encore avoir `item_type: "Payment"` jusqu’au backfill complet — voir [payments.md](payments.md).
- **Invariant** : la somme des lignes = `payment.total_cents`.
- **À éviter** :
  - `item_type: "Payment"` pour un don dans toute nouvelle documentation ou code (utiliser `"Donation"`).

#### Don — `Donation`
- **Définition** : paiement volontaire sans contrepartie, conservé pour reçu fiscal éventuel.
- **Représentation actuelle (code)** : `PaymentLine` avec `item_type: "Donation"` (création via `People::PaymentCreator`). Données anciennes : encore `item_type: "Payment"` sur certaines lignes jusqu’à migration — voir `phase1-donation-fix` et [payments.md](payments.md).
- **Représentation cible** : même schéma polymorphique ; nettoyage DB (`Payment` legacy, champ `payments.donation`, validations strictes sur `item_type`).
- **Usage correct** :
  - « Don de 5 € lors d'une adhésion ».
  - « Le paiement contient deux lignes : adhésion + don ».
- **À éviter** :
  - Confondre un don avec une cotisation ou une adhésion.
  - Stocker un don directement sur `Payment#donation` (champ historique à éliminer).

---

### 1.5 Présences et événements

#### Présence — `Attendance`
- **Définition** : trace de présence d'une `Person`, soit pour l'entraînement libre quotidien, soit pour un événement.
- **Règles** :
  - Entraînement libre : unicité `person_id + date` (pas d'`event_id`). Décrémente la cotisation utilisée (`Contribution#use_session!`) si applicable.
  - Événement : unicité `person_id + event_id`.

#### Liste de présence — `AttendanceList`
- **Définition** : conteneur d'`Attendance` pour un jour ou un événement. Statuts : `:open`, `:close`, `:archived`. La liste « training » quotidienne est créée par `AttendanceListManagement::DailyListGenerator` (skip lundi).

#### Événement — `Event`
- **Définition** : événement organisé (cours, stage, performance), avec date, catégorie. Inscriptions via `EventAttendee` (`Person ↔ Event`).

#### Temps d’accueil en création
- **Définition** : accueil d’un projet créatif au sein du lieu (cirque, arts graphiques, etc.), à distinguer de l’adhésion ou de la cotisation cirque.
- **Usage correct** : tout libellé public (pages Contact, FAQ, Adhérer, partenaires) utilise cette formulation.
- **Code / formulaire de contact** : valeur de catégorie **`creative_hosting`** ; le slug legacy **`residence`** est encore accepté et normalisé vers `creative_hosting`. Boîte mail : `CONTACT_EMAIL_CREATIVE_HOSTING`, avec repli sur **`CONTACT_EMAIL_RESIDENCE`** si la nouvelle variable n’est pas définie.
- **À éviter** : « résidence » pour désigner ce dispositif (terme legacy en communication).

---

### 1.6 Newsletter

#### Abonné newsletter — `NewsletterSubscriber`
- **Définition** : table dédiée, **indépendante** de `Person`. Une entrée newsletter peut exister sans `Person`. Liaison automatique si l'email correspond à une `Person`.
- **Usage correct** :
  - « S'inscrire à la newsletter via `People::NewsletterSignup` ».
- **Note importante** : dans le contexte newsletter, le terme anglais **« subscription / unsubscription » est légitime** (sens mailing). Ne pas le remplacer par « cotisation » dans ce contexte.

---

### 1.7 Termes explicitement interdits

| Terme à proscrire | Terme cible | Raison |
| --- | --- | --- |
| `subscription` (sens cotisation cirque) | `contribution` | Ambiguïté avec abonnement Stripe / abonnement mailing. Inadapté à une asso 1901. |
| `SubscriptionPlan` (en doc) | `ContributionFormula` | Nom legacy ; en doc on préfère le nom canonique avec alias entre parenthèses si nécessaire. |
| `book_of_entry`, `BookOfEntry` (en doc) | `contribution`, `Contribution` | Legacy : ne désigne plus que les Pack 10, mais conceptuellement c'est l'instance d'une cotisation. |
| `abonnement` | `cotisation` | Terme commercial inadapté. |
| `inferior_rights` | `subordinate_roles` | Logique inversée trompeuse (ne lit pas comme « rôles subordonnés »). |
| `item_type: "Payment"` (pour un don) | `item_type: "Donation"` | Hack polymorphique masquant la nature du don. |
| « article d'adhésion » / « article de cotisation » | « type d'adhésion » / « formule de cotisation » | Concept non canonique introduit dans les seeds. |
| `UserMembership` | `Membership` (lié à `Person`) | Modèle déprécié — adhésion appartient à `Person`, pas `User`. |
| « carnet d'entrées » (sauf Pack 10) | « cotisation » | Le carnet est un sous-type, pas le concept général. |

> Le terme **`subscription`** dans le contexte **newsletter** (mailing) est **conservé** : il s'agit du vocabulaire technique standard du domaine emailing.

---

## 2. Glossaire récapitulatif (FR ↔ EN code)

| Terme français | Terme anglais (code) | Statut | Note |
| --- | --- | --- | --- |
| Personne | `Person` | canonique | source de vérité CRM |
| Compte web | `User` | canonique | optionnel **pour une Person** (pas toujours de compte) ; **obligatoire pour un User** (toujours une Person liée) |
| Adhésion | `Membership` | canonique | annuel |
| Type d'adhésion | `MembershipType` | canonique | catalogue versionné |
| Cotisation | `Contribution` | **cible** (legacy : `BookOfEntry`) | instance achetée |
| Formule de cotisation | `ContributionFormula` | **cible** (legacy : `SubscriptionPlan`) | catalogue versionné |
| Paiement | `Payment` | canonique | transaction multi-lignes |
| Ligne de paiement | `PaymentLine` | canonique | polymorphique |
| Don | `Donation` | **cible** (legacy : `item_type: "Payment"`) | reçu fiscal |
| Présence | `Attendance` | canonique | entraînement / événement |
| Liste de présence | `AttendanceList` | canonique | quotidienne ou événement |
| Événement | `Event` | canonique | inscriptions via `EventAttendee` |
| Temps d’accueil en création | formulaire contact : `creative_hosting` (`residence` legacy) | canonique (UI FR) | env : `CONTACT_EMAIL_CREATIVE_HOSTING` (+ fallback `CONTACT_EMAIL_RESIDENCE`) |
| Inscription événement | `EventAttendee` | canonique | jointure `Person × Event` |
| Numéro d'adhérent | `member_number` | canonique | format `25U001` / `25C001` |
| Newsletter | `NewsletterSubscriber` | canonique | table indépendante |

---

## 3. Règles d'usage rapides

1. **Adhésion ≠ cotisation.** L'adhésion est annuelle, donne un statut. La cotisation est un droit d'accès cirque payé séparément (Pack 10, Trimestre, Annuel, Journée).
2. **Une cotisation ne peut exister sans adhésion Cirque active.**
3. **Un don n'est ni une adhésion, ni une cotisation.** C'est une `PaymentLine` à part entière.
4. **`Person` et `User` ne fusionnent jamais implicitement.** Toute liaison passe par `People::AccountLinker`.
5. **Newsletter ≠ cotisation.** Le mot anglais « subscription » dans ce contexte est autorisé.
6. **Quand le code n'est pas encore aligné** sur le vocabulaire cible, la documentation utilise la forme :
   > « **Vocabulaire cible : `Contribution`** (code actuel : `BookOfEntry`) ».

---

## 4. Documents liés

- [domain_model.md](domain_model.md) — diagramme du modèle de domaine cible.
- [payments.md](payments.md) — détail Payment / PaymentLine / Donation et dette technique.
- [migrations/vocabulary_migration.md](migrations/vocabulary_migration.md) — mapping ancien → nouveau et statut par phase.
- [domain/business_logic.md](domain/business_logic.md) — règles métier détaillées par domaine.
- [architecture/services.md](architecture/services.md) — services et orchestrateurs (`People::*`).
