# Logique Métier - Le Circographe

**Application:** Gestion complète pour association de cirque  
**Date:** 2025-11-03  
**Classification:** Zone 1 (Stable) | Zone 2 (En cours) | Zone 3 (Future)  
**État:** ✅ Logique métier complètement réécrite selon vraies règles business (2025-11-03)

---

## Classification des Zones

- **Zone 1 (Stable)** - Comportement défini et immuable → Tests immédiats
- **Zone 2 (En cours)** - Logique temporaire/exploration → Tests après stabilisation
- **Zone 3 (Future)** - Non implémenté → Pas de tests

**Voir `docs/ZONES_CLASSIFICATION.md` pour détails complets.**

### Stratégie Backend - Logique Métier Immuable

**Objectif:** Comprendre, documenter et rendre immuable la logique métier.

**Problème:** Logique métier encore en mouvement → Pas clair ce qui doit être testé → Risque de tests sur code instable

**Solution: 3 Zones**

1. **Zone 1: Logique Définie (Maintenant)** - Fonctionnel et stable → Tests immédiats
2. **Zone 2: Logique En Cours (Prototype)** - Fonctionnel mais pourrait changer → Tests après stabilisation
3. **Zone 3: Logique Future (À Définir)** - Non implémenté → Documentation seulement

**Workflow:**
1. Documenter la logique métier dans `docs/BUSINESS_LOGIC.md`
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
- **Basic:** 1€ - Adhésion standard sans accès cirque
- **Circus Plein:** 10€ - Adhésion avec accès cirque tarif normal
- **Circus Réduit:** 7€ - Adhésion avec accès cirque tarif réduit (RSA, Mineur, Handicap, Étudiant)

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
Person#create_membership!(membership_type, ...) # Crée + paiement + numéro
Person#upgrade_membership!(new_type, ...) # Full price du nouveau type
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
- **SubscriptionPlan:** Abonnement (pack10, annual, etc.)
- **MembershipType:** Nouvelle adhésion

#### Logique Métier Person-Based
```ruby
Person#create_membership!(...) # Crée membership + payment + payment_line
Person#upgrade_membership!(...) # Crée payment full price + payment_line
Person#create_subscription!(...) # Crée book_of_entry + payment + payment_line
Person#upgrade_subscription!(...) # Prorata + payment + payment_line
```

#### Payment Lines
- Un paiement peut contenir plusieurs lignes
- Chaque ligne référence un item (Membership, Plan, etc.)
- Traitement séquentiel de toutes les lignes

#### Anonymisation RGPD
```ruby
Payment#anonymize! # Person_id → NULL, garde hash traçabilité
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
  - **User = Account** (accès web optionnel) qui référence une `Person` existante (`belongs_to :person`).
- **Conséquences :**
  - Création front : on `find_or_create_by` Person avant de créer User.
  - Création admin : Person d’abord (`PersonManagement::PersonCreator`), puis User via `UserManagement::UserCreator` si espace web nécessaire.
  - Suppression User : coupe l’accès web (`destroy`), la Person et ses paiements restent.
  - Suppression Person : passe par `UserManagement::UserDeleter` qui archive la Person (`Person#archive!`) seulement si aucune donnée financière (sauf super_admin).
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

## 4. Subscription Plans (Abonnements)

### Zone 1: Comportement Défini

#### Durées Disponibles
```ruby
enum duration: {
  day: 0,           # Jour
  trimester: 1,     # Trimestre
  annual: 2,        # Annuel
  pack10: 3         # Pack de 10 séances
}
```

#### Pack10 (Spécial)
- **BookOfEntry:** Créé automatiquement après paiement
- **Sessions:** Nombre défini (sessions_count)
- **Validity:** Période de validité (validity_days)
- **Expiry:** Pack10 n'expire jamais (`expired_at` nil)

#### Règles Métier
- **Prix:** En centimes (`price_cents`)
- **Versioning:** Plans versionnés
- **Effective from:** Date d'effet

### Zone 2: En Cours de Validation

- [ ] Plans personnalisés
- [ ] Promotions/Code réductions
- [ ] Pause d'abonnement

### Zone 3: Future

- [ ] Abonnements récurrents automatiques
- [ ] Plans famille
- [ ] Offres groupées

---

## 5. Book of Entry (Carnets)

### Zone 1: Comportement Défini

> **NOTE BUSINESS:** Dans l’usage actuel de l’association, *BookOfEntry* ne matérialise **que** les carnets Pack 10 séances. Le modèle conserve des attributs (expiration, illimité, etc.) pour rester compatible avec d’anciens prototypes, mais cette logique n’est plus exploitée. Tout test/implémentation doit partir du principe « BookOfEntry = Pack 10 ».

#### Création
- **Trigger:** Paiement d'un SubscriptionPlan pack10 (unique offre à carnet)
- **Person:** Assigné au propriétaire
- **Sessions:** Nombre initial = sessions_count du plan (par défaut 10)

#### Utilisation
```ruby
BookOfEntry#can_use?
  - Membership circus active?
  - Sessions remaining > 0?
  - Status active?
  
BookOfEntry#use_session!
  - Décrémente sessions_remaining
  - Status = consumed si 0
```

#### Expiration (Pack10 uniquement)
- **Never expires:** Pack10 n'a pas expires_at (les autres durées ne sont plus utilisées)
- **Non-pack (legacy):** Expire selon validité — gardé pour compatibilité mais hors périmètre actuel

#### Suspension & Réactivation
```ruby
BookOfEntry#suspend!(reason:) # Statut suspended (upgrades)
BookOfEntry#reactivate! # Statut active
BookOfEntry.reactivate_suspended_packs_for_person(person) # Auto après expiration Trimestre/Année
```

**RÈGLES UPGRADE Cotisations:**
- Pack10 → Trimestre/Année OK (suspension Pack10, pas de crédit)
- Trimestre → Année OK (crédit prorata temporel)
- Day interdit

### Zone 2: En Cours de Validation

- [ ] Transfert de séances entre carnets
- [ ] Extension de validité

### Zone 3: Future

- [ ] Gifts cards
- [ ] Système de points

---

## 6. Events (Événements)

### Zone 1: Comportement Défini

#### Création Événement
- **Name:** Requis
- **Date:** Requise
- **Category:** Enum (default: circus)

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

#### Book of Entry Integration
- **Auto-decrement:** Décrémente sessions_remaining si book_of_entry lié
- **Can_use check:** Vérifie logique can_use? avant

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
- **Service:** `NewsletterSignupService` (refactoré pour nouvelle table)
- **Provider:** Mailjet
- **Opt-in:** Consentement requis

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
✅ `MembershipManagement::MembershipCreator` - Création adhésions  
✅ `MembershipManagement::MembershipUpgrader` - Upgrades membres  
✅ `Admin::PaymentsService` - Filtrage/query paiements  
✅ `NewsletterSignupService` - Inscriptions newsletter  

## Modèles Zone 1 (Testés)

✅ `Person#create_membership!` - Création adhésion + paiement + numéro  
✅ `Person#upgrade_membership!` - Upgrade plein tarif  
✅ `Person#renew_membership!` - Renouvellement avec nouveau numéro  
✅ `Person#create_subscription!` - Création cotisation + paiement  
✅ `Person#upgrade_subscription!` - Upgrade cotisation avec prorata  
✅ `BookOfEntry#suspend!` / `reactivate!` - Suspension cotisations  
✅ `Payment#anonymize!` - Anonymisation RGPD  

## Services Zone 2 (En Exploration)

⚠️ `UserManagement::UserCreator` - Création utilisateurs  
⚠️ `PersonManagement::PersonCreator` - Création personnes  
⚠️ `EventManagement::*` - Gestion événements  

## Services Zone 3 (Obsolètes/Supprimés)

❌ `Payments::Process` - OBSOLÈTE (remplacé par Person-based logic)  
❌ `Memberships::Upgrade` - OBSOLÈTE (remplacé par MembershipManagement::MembershipUpgrader)  

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

**Person-Based:** User → Person (relation 1-1)  
**Résultat:** Séparation données authentification vs profil

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
**Dernière Mise à Jour:** 2025-11-03

---

## Changelog Récent

### Réécriture Complète Logique Métier (2025-11-03)

**Upgrades d'Adhésions:**
- **Changement:** Upgrade = **plein tarif** du nouveau type (pas de prorata)
- **Impact:** Basic 1€ → Circus Réduit 7€ = payer 7€ (pas 6€)
- **Méthode:** `Person#upgrade_membership!` - Facture new_type.price_cents

**Renouvellements:**
- **Nouveau:** `Person#renew_membership!` - Crée nouvelle adhésion + **nouveau numéro d'adhérent**
- **Impact:** Chaque année, incrémente numéro (25U001 → 25U002 → ...)
- **Historique:** Tous changements tracés dans MemberNumberHistory

**Prorata Cotisations:**
- **Contrôleur:** `Person#upgrade_subscription!`
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
  - Si l’adhésion (`membership`) expire, tous les carnets associés (book_of_entries) sont suspendus jusqu’à renouvellement/adherence active.
  - Réactivation automatique quand une nouvelle adhésion circus redevient active.

**Tarifs Réduits:**
- **Nouveau:** Attributs `reduced_rate_eligible`, `reduced_rate_reason`, `reduced_rate_proof` sur Person
- **UI:** Formulaire Stimulus toggle pour justificatif
- **Affichage:** Carte bleue dans UserInfoComponent si éligible

**Anonymisation RGPD:**
- **Nouveau:** `Payment#anonymize!` - Person_id → NULL, garde hash traçabilité
- **Usage:** Suppression données personnelles tout en gardant compta

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
- `MembershipManagement::*` (4 services)
- `SubscriptionManagement::*` (2 services)
- `PaymentManagement::*` (6 services)
- `AccountClaimManagement::*` (2 services)
- `AttendanceManagement::*` (1 service)
- `AttendanceListManagement::*` (3 services)
- `BlogManagement::*` (3 services)
- `MembershipTypeManagement::*` (2 services)
- `OpeningHoursManagement::*` (1 service)
- `NewsletterManagement::*` (1 service)
- `SubscriptionPlanManagement::*` (2 services)
- `UserManagement::*` (3 services)
- `PersonManagement::*` (3 services)
- `EventManagement::*` (3 services)
- `MemberNumberManagement::*` (2 services)

**Bénéfices:**
- Controllers minimalistes (délégation pure)
- Logique métier extraite et testable
- Instrumentation pour audit (ActiveSupport::Notifications)
- Cohérence et maintenabilité

**Documentation:** Voir `docs/ARCHITECTURE_SERVICES.md` pour détails complets.

### Historique des Refactorings (2025-01-31)

#### Simplification Architecture

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

## 📚 Documentation liée

- **Architecture Services:** `docs/ARCHITECTURE_SERVICES.md` - Pattern Controller → Service → Model (44 services)
- **Concerns:** `docs/CONCERNS_ANALYSIS.md` - Analyse complète des concerns (10 concerns)
- **Audit Controllers:** `docs/CONTROLLERS_AUDIT.md` - État des tests et stratégie TDD
- **Zones Classification:** `docs/ZONES_CLASSIFICATION.md` - Classification Zone 1/2/3
- **TDD Guide:** `docs/TDD_GUIDE.md` - Guide complet TDD
- **Testing Guide:** `docs/TESTING_GUIDE.md` - Guide tests et couverture


