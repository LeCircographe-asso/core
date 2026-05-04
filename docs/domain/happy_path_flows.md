# Flux nominaux (Happy-path flows)

> **Statut** : stable
> **Public cible** : contributeur
> **Dernière vérification** : 2026-05-01
> **Sources de vérité** : `app/services/people/`, `app/controllers/admin/`, `app/services/web/`.

Ce document décrit le flux nominal de chaque opération métier principale — les acteurs, les services impliqués et le résultat attendu en cas de succès. Pour la logique d'erreur et les règles d'intégrité, voir [`data_integrity_rules.md`](data_integrity_rules.md).

---

## 1. Enregistrement d'une personne (Register)

**Acteur :** admin  
**Service :** `People::Register`  
**Contrôleur :** `Admin::UsersController#create` (via `Admin::UserCreationForm`)

### Étapes nominales

1. L'admin remplit le formulaire new user (nom, prénom, email, rôle, adhésion optionnelle).
2. `Admin::UserCreationForm#call` délègue à `People::Register`.
3. `People::PersonCreator` crée ou met à jour la `Person` (email normalisé).
4. Si `create_user_account: true` → `People::UserAccountCreator` crée le `User` lié à la `Person`.
5. Si `create_membership: true` → `People::MembershipCreator` crée l'adhésion + paiement associé.
6. Redirection vers `admin_user_path("person_#{person.id}")` avec notice de succès.

### Invariants

- La `Person` est toujours créée ou retrouvée en premier.
- Aucun `User` ne peut être créé sans `Person` (NOT NULL DB).
- Si une `Person` avec le même email existe déjà, `PersonCreator` la met à jour (pas de doublon).

---

## 2. Inscription web (Web signup)

**Acteur :** visiteur public  
**Service :** `Web::UserRegistration`  
**Contrôleur :** `RegistrationsController#create`

### Étapes nominales

1. Visiteur remplit le formulaire d'inscription (email, mot de passe, CGU).
2. `Web::UserRegistration#call` orchestre la création.
3. Une `Person` minimale est créée (nom déduit de l'email si absent).
4. Le `User` est créé et lié à cette `Person`.
5. Si la `Person` existait déjà sans `User` → l'`User` est rattaché à la fiche existante.
6. Email de bienvenue envoyé (`People::UserAccountCreator`).
7. Session créée et l'utilisateur est connecté.

### Invariants

- Email existant avec `User` existant → message d'erreur « lien mot de passe oublié ».
- `Person` existante sans `User` → invitation à utiliser « Récupérer mon compte ».
- CGU + Privacy Policy obligatoires (skip si `created_by_admin`).

---

## 3. Liaison User ↔ Person (Account linking)

**Acteur :** admin ou system  
**Services :** `People::AttachUserToPerson` (nominal) / `People::AccountLinker` (avec fusion)  
**Contrôleur :** via les services, pas d'action dédiée dans l'UI pour l'instant

### Étapes nominales (attach simple)

1. Admin identifie un `User` sans `Person` complète et une `Person` sans `User`.
2. `People::AttachUserToPerson.new(user:, target_person:).call`.
3. Le `User.person_id` est mis à jour → `Person` cible devient la fiche du compte.
4. Instrumentation `people.user_attached`.

### Étapes nominales (avec merge)

1. Si la `Person` source du `User` (stub minimal) a des données à fusionner.
2. `People::AccountLinker` appelle `AttachUserToPerson` puis `People::AccountMerger`.
3. Les données de la fiche source sont transférées vers la fiche cible.
4. La fiche source est archivée (`Person#archive!`).

### Invariants

- `AttachUserToPerson` refuse si la `Person` cible a déjà un autre `User`.
- Un `User` ne peut pas être rattaché à deux `Person` simultanément.

---

## 4. Achat d'adhésion (Membership purchase)

**Acteur :** admin  
**Service :** `People::MembershipCreator`  
**Contrôleur :** `Admin::MembershipsController#create`

### Étapes nominales

1. Admin sélectionne une personne et un type d'adhésion.
2. `People::MembershipCreator.new(person:, membership_type_id:, payment_method:, recorded_by_id:).call`.
3. `Person#create_membership!` crée la `Membership` et le `Payment` + `PaymentLine` associés.
4. La `Membership` passe au statut `active`.
5. Un numéro d'adhérent est attribué si absent (`MemberNumberManagement::MemberNumberSuggester`).
6. Redirection vers la fiche personne.

### Invariants

- Upgrade Basic → Circus : passer par `People::MembershipUpgrader` (plein tarif du nouveau type).
- Upgrade Circus → Basic : interdit.
- Création de l'adhésion génère toujours un `Payment`.

---

## 5. Achat d'une cotisation (Contribution purchase)

**Acteur :** admin  
**Service :** `People::ContributionCreator`  
**Contrôleur :** `Admin::ContributionFormulasController#create`

### Étapes nominales

1. Admin sélectionne une personne (doit avoir une `Membership` Cirque active) et une formule.
2. `People::ContributionCreator.new(person:, contribution_formula_id:, payment_method:, recorded_by_id:).call`.
3. `Person#create_contribution!` crée la `Contribution` + `Payment` + `PaymentLine`.
4. Pour un pack10 : `sessions_remaining` initialisé à `sessions_count`.
5. Redirection vers la fiche personne.

### Invariants

- La personne doit avoir une `Membership` Cirque active (`can_buy_contribution_formulas?`).
- Un `Payment` est toujours généré.
- Don optionnel (`donation_cents`) ajoute une ligne `PaymentLine` supplémentaire sans affecter la cotisation.

---

## 6. Upgrade de cotisation

**Acteur :** admin  
**Service :** `People::ContributionUpgrader`  
**Contrôleur :** `Admin::ContributionsController#upgrade`

### Étapes nominales (Pack 10 → Trimestre/Annuel)

1. Admin sélectionne la cotisation source (Pack 10) et la formule cible.
2. `People::ContributionUpgrader.new(person:, from_contribution_id:, to_formula_id:, payment_method:).call`.
3. `Person#upgrade_contribution!` suspend le Pack 10 (sessions conservées), crée la nouvelle `Contribution` + `Payment`.
4. Prorata calculé si Trimestre → Annuel (crédit temporel).
5. Notice indiquant le crédit appliqué si > 0.

### Invariants

- Day → autre : interdit.
- Le Pack 10 suspendu est réactivé automatiquement à l'expiration du Trimestre/Annuel.

---

## 7. Don (Donation)

**Acteur :** admin  
**Service :** `People::PaymentCreator` (avec `item_type: "Donation"`)  
**Contrôleur :** `Admin::DonationsController#create`

### Étapes nominales

1. Admin crée un don pour une personne.
2. `People::PaymentCreator.new(person:, ..., item_type: "Donation").call`.
3. Un `Payment` + une `PaymentLine` avec `item_type: "Donation"` sont créés.
4. Redirection vers la fiche personne ou la liste des paiements.

### Invariants

- Le don n'affecte pas le statut d'adhésion.
- `item_type: "Payment"` est obsolète pour les dons — utiliser `"Donation"`.
- `recorded_by_id` toujours requis (audit trail).
