# Logique Métier - Le Circographe

**Application:** Gestion complète pour association de cirque  
**Date:** 2025-01-31  
**Classification:** Zone 1 (Stable) | Zone 2 (En cours) | Zone 3 (Future)  
**État:** ✅ Architecture simplifiée et nettoyée (2025-01-31)

---

## Classification des Zones

- **Zone 1 (Stable)** - Comportement défini et immuable → Tests immédiats
- **Zone 2 (En cours)** - Logique temporaire/exploration → Tests après stabilisation
- **Zone 3 (Future)** - Non implémenté → Pas de tests

---

# Domaines Métier

## 1. Membership (Adhésions)

### Zone 1: Comportement Défini

#### Durée et Statuts
- **Durée standard:** 1 an depuis date de souscription (`started_at` → `ended_at`)
- **Statuts:** `pending` → `active` → `inactive` → `expired`
- **Activation:** Immédiate après paiement réussi

#### Types d'Adhésions
- **Basic:** Adhésion standard sans accès cirque
- **Circus:** Adhésion avec accès cirque (catégorie unique, tarifs multiples: Full 25€, Reduced 20€)

#### Règles de Référence
```ruby
# Validation: ended_at > started_at
# Validation: Pas d'overlapping active memberships (sauf si skip_overlap_validation)
# Enum status: pending(0), inactive(1), active(2), expired(3)
```

#### Upgrades Possibles
- ✅ Basic → Circus (avec tout tarif: Full, Reduced, Student, etc.)
- ✅ Circus → Circus (changement de tarif uniquement: Full ↔ Reduced)
- ❌ Circus → Basic (interdit)
- ❌ Même type (interdit)

#### Logique Métier
```ruby
Membership#can_upgrade_to?(membership_type)
Membership#upgrade_to!(new_type, started_at)
Membership#basic?
Membership#circus?
```

### Zone 2: En Cours de Validation

- [ ] Renouvellement automatique
- [ ] Prorata sur adhésion annuelle
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

#### Traitement Automatique
```ruby
Payments::Process#call
  - Active pending membership si payée
  - Crée BookOfEntry pour pack10
  - Assigne member_number si absent
```

#### Payment Lines
- Un paiement peut contenir plusieurs lignes
- Chaque ligne référence un item (Membership, Plan, etc.)
- Traitement séquentiel de toutes les lignes

### Zone 2: En Cours de Validation

- [ ] Politique de remboursement (refunds)
- [ ] Paiements en plusieurs fois
- [ ] Prorata sur remboursements

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
- **User → Person:** Relation 1-to-1
- **Délégation:** User délègue attributs à Person
- **Attributs:** name, phone, email, address, birth_date, etc.

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

#### Création
- **Trigger:** Paiement d'un SubscriptionPlan pack10
- **Person:** Assigné au propriétaire
- **Sessions:** Nombre initial = sessions_count du plan

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
- **Never expires:** Pack10 n'a pas expires_at
- **Non-pack:** Expire selon validité

### Zone 2: En Cours de Validation

- [ ] Transfert de séances entre carnets
- [ ] Extension de validité
- [ ] Remboursement partiel

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
- **Pattern:** "25U001" (année + U + séquence)
- **Assignment:** Automatique à l'activation membership
- **Service:** `MemberManagementService#assign_member_number`

#### History
- **Audit:** Tous les changements tracés dans MemberNumberHistory
- **Person:** Un numéro par personne (identifiant unique)

### Zone 2: En Cours de Validation

- [ ] Réassignation de numéros
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
✅ `Payments::Process` - Traitement paiements  
✅ `Memberships::Upgrade` - Upgrades membres  
✅ `Admin::PaymentsService` - Filtrage/query paiements  
✅ `NewsletterSignupService` - Inscriptions newsletter  

## Services Zone 2 (En Exploration)

⚠️ `UserManagement::UserCreator` - Création utilisateurs  
⚠️ `PersonManagement::PersonCreator` - Création personnes  
⚠️ `PaymentManagement::*` - Gestion paiements  
⚠️ `EventManagement::*` - Gestion événements  

## Services Zone 3 (Futurs)

❓ `PaymentManagement::RefundCreator` - Remboursements  
❓ `UserManagement::AccountMerger` - Fusion comptes  

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
**Dernière Mise à Jour:** 2025-01-31

---

## Changelog Récent (2025-01-31)

### Simplification Architecture

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


