# Refonte métier & base de données — Le Circographe
*Rails 8.0.3 — Checklists d'actions concrètes comme une recette de cuisine*

> **But du document**  
> Checklists d'actions précises pour refondre complètement la logique métier selon le domain_model_circographe.md.  
> Chaque étape est une action concrète à exécuter dans l'ordre.  
> Basé sur l'architecture Person + User + Membership + SubscriptionPlan.

---

## 🎯 **OBJECTIF FINAL**
Refondre complètement l'architecture selon le modèle Person-Based avec :
- **Person** (individus réels) + **User** (comptes numériques optionnels)
- **Membership** (adhésions annuelles) + **MembershipType** (types)
- **SubscriptionPlan** (produits de pratique) + **Payment/PaymentLine**
- **Attendance** (présences) + **Event** (événements)

---

## 🚨 **CHECKLIST 1 : NETTOYAGE ET PRÉPARATION**

### **Backup et sécurité :**
- [ ] Faire un backup complet de la base de données
- [ ] Créer une branche `refacto-complete-architecture` depuis `dev`
- [ ] Documenter l'état actuel avec `rails db:schema:dump`
- [ ] Lister toutes les données importantes à migrer

### **Analyse des migrations incohérentes :**
- [ ] **PROBLÈME IDENTIFIÉ** : Migration `20250319103141_drop_unused_tables.rb` supprime des tables
- [ ] **PROBLÈME IDENTIFIÉ** : Tables recréées après : `user_memberships`, `payments`, etc.
- [ ] Vérifier quelles tables existent vraiment avec `rails db:migrate:status`
- [ ] Analyser les dépendances entre les tables actuelles

### **Préparation de l'environnement :**
- [ ] Vider la base de test : `rails db:reset`
- [ ] Vérifier que tous les tests passent avant refonte
- [ ] Créer un script de migration des données existantes

---

## 🗂️ **CHECKLIST 2 : SUPPRESSION DES TABLES OBSOLÈTES**

### **Supprimer les tables qui ne correspondent pas au nouveau modèle :**
- [ ] Créer migration pour supprimer `subscription_types` (remplacé par `membership_types`)
- [ ] Créer migration pour supprimer `roles` (intégré dans `users`)
- [ ] Créer migration pour supprimer `user_roles` (relation directe)
- [ ] Créer migration pour supprimer `training_attendees` (remplacé par `attendances`)
- [ ] Créer migration pour supprimer `user_membership_subscriptions` (logique dans `memberships`)

### **Vérifier les suppressions :**
- [ ] Exécuter `rails db:migrate`
- [ ] Vérifier avec `rails console` que les tables sont supprimées
- [ ] Tester que l'app ne crash pas (même si certaines fonctionnalités sont cassées)

---

## 👥 **CHECKLIST 3 : CRÉATION DU MODÈLE PERSON**

### **Migration pour la table people :**
- [ ] Créer migration `create_people_table`
- [ ] Ajouter colonnes : `first_name`, `last_name`, `phone`, `email`, `address`, `birth_date`
- [ ] Ajouter colonnes : `emergency_contact_name`, `emergency_contact_phone`
- [ ] Ajouter colonnes : `notes` (text), `created_at`, `updated_at`
- [ ] Ajouter index sur `email` (unique)

### **Migration pour lier users aux people :**
- [ ] Créer migration `add_person_id_to_users`
- [ ] Ajouter colonne `person_id` (foreign key vers `people`)
- [ ] Ajouter index sur `person_id`
- [ ] Ajouter contrainte foreign key

### **Modèle Person :**
- [ ] Créer `app/models/person.rb`
- [ ] Ajouter `has_one :user, dependent: :nullify`
- [ ] Ajouter `has_many :memberships, dependent: :destroy`
- [ ] Ajouter `has_many :payments, dependent: :destroy`
- [ ] Ajouter `has_many :attendances, dependent: :destroy`
- [ ] Ajouter validations : `presence: true` pour `first_name`, `last_name`
- [ ] Ajouter méthode `full_name`

### **Modifier le modèle User :**
- [ ] Ajouter `belongs_to :person, optional: true`
- [ ] Modifier les validations pour rendre `person_id` optionnel
- [ ] Ajouter méthode `person_name` qui retourne `person&.full_name`

---

## 🏛️ **CHECKLIST 4 : REFONTE DU SYSTÈME D'ADHÉSIONS**

### **Migration pour membership_types :**
- [ ] Créer migration `create_membership_types_table`
- [ ] Ajouter colonnes : `name`, `category` (enum), `price_cents`, `description`
- [ ] Ajouter colonnes : `created_at`, `updated_at`
- [ ] Ajouter enum `category: { basic: 0, circus_full: 1, circus_reduced: 2 }`

### **Migration pour refondre memberships :**
- [ ] Créer migration `refactor_memberships_table`
- [ ] Supprimer colonne `type_name` (remplacé par `membership_type_id`)
- [ ] Ajouter colonne `person_id` (foreign key vers `people`)
- [ ] Ajouter colonne `membership_type_id` (foreign key vers `membership_types`)
- [ ] Ajouter colonnes : `started_at`, `ended_at`, `status` (enum)
- [ ] Ajouter colonne `first_joined_at` (pour préserver l'historique)
- [ ] Ajouter index sur `[person_id, status]`
- [ ] Ajouter enum `status: { inactive: 0, active: 1, expired: 2 }`

### **Modèle MembershipType :**
- [ ] Créer `app/models/membership_type.rb`
- [ ] Ajouter `has_many :memberships, dependent: :restrict_with_error`
- [ ] Ajouter `has_many :subscription_plans, dependent: :destroy`
- [ ] Ajouter validations pour `name`, `category`, `price_cents`
- [ ] Ajouter scopes : `basic`, `circus_full`, `circus_reduced`

### **Modèle Membership :**
- [ ] Refactorer `app/models/membership.rb`
- [ ] Remplacer `belongs_to :user` par `belongs_to :person`
- [ ] Ajouter `belongs_to :membership_type`
- [ ] Ajouter validations pour `started_at`, `ended_at`
- [ ] Ajouter scopes : `active`, `expired`, `current`
- [ ] Ajouter méthode `expired?`
- [ ] Ajouter méthode `can_upgrade_to?(membership_type)`

---

## 🎫 **CHECKLIST 5 : SYSTÈME DE PLANS D'ABONNEMENT**

### **Migration pour subscription_plans :**
- [ ] Créer migration `create_subscription_plans_table`
- [ ] Ajouter colonnes : `name`, `duration` (enum), `price_cents`, `description`
- [ ] Ajouter colonnes : `membership_type_id` (foreign key), `created_at`, `updated_at`
- [ ] Ajouter colonnes : `sessions_count` (pour pack10), `validity_days`
- [ ] Ajouter enum `duration: { day: 0, trimester: 1, annual: 2, pack10: 3 }`
- [ ] Ajouter index sur `membership_type_id`

### **Modèle SubscriptionPlan :**
- [ ] Créer `app/models/subscription_plan.rb`
- [ ] Ajouter `belongs_to :membership_type`
- [ ] Ajouter validations pour `name`, `duration`, `price_cents`
- [ ] Ajouter scopes : `day`, `trimester`, `annual`, `pack10`
- [ ] Ajouter méthode `for_circus_members?` (vérifie membership_type)
- [ ] Ajouter méthode `is_pack?` (retourne true si duration == pack10)

---

## 💰 **CHECKLIST 6 : REFONTE DU SYSTÈME DE PAIEMENT**

### **Migration pour refondre payments :**
- [ ] Créer migration `refactor_payments_table`
- [ ] Remplacer `user_id` par `person_id` (foreign key vers `people`)
- [ ] Ajouter colonne `recorded_by_id` (foreign key vers `users`)
- [ ] Ajouter colonne `total_cents` (remplacer `payment_amount`)
- [ ] Ajouter colonne `payment_method` (enum)
- [ ] Ajouter colonnes : `notes`, `created_at`, `updated_at`
- [ ] Ajouter enum `payment_method: { cash: 0, sumup: 1, cheque: 2, transfer: 3 }`

### **Migration pour payment_lines :**
- [ ] Créer migration `create_payment_lines_table`
- [ ] Ajouter colonnes : `payment_id` (foreign key), `item_type`, `item_id` (polymorphic)
- [ ] Ajouter colonne `amount_cents`, `description`, `created_at`, `updated_at`
- [ ] Ajouter index sur `[item_type, item_id]`
- [ ] Ajouter index sur `payment_id`

### **Modèle Payment :**
- [ ] Refactorer `app/models/payment.rb`
- [ ] Remplacer `belongs_to :user` par `belongs_to :person`
- [ ] Ajouter `belongs_to :recorded_by, class_name: 'User'`
- [ ] Ajouter `has_many :payment_lines, dependent: :destroy`
- [ ] Supprimer les callbacks complexes `after_update`
- [ ] Ajouter méthode `membership_related?` (vérifie si contient des adhésions)
- [ ] Ajouter méthode `carnet_related?` (vérifie si contient des pack10)

### **Modèle PaymentLine :**
- [ ] Créer `app/models/payment_line.rb`
- [ ] Ajouter `belongs_to :payment`
- [ ] Ajouter `belongs_to :item, polymorphic: true`
- [ ] Ajouter validations pour `amount_cents`
- [ ] Ajouter méthode `item_description`

---

## 📚 **CHECKLIST 7 : SYSTÈME DE CARNETS (BOOK OF ENTRY)**

### **Migration pour refondre book_of_entries :**
- [ ] Créer migration `refactor_book_of_entries_table`
- [ ] Remplacer `user_id` par `person_id` (foreign key vers `people`)
- [ ] Ajouter colonne `subscription_plan_id` (foreign key vers `subscription_plans`)
- [ ] Ajouter colonnes : `sessions_remaining`, `status` (enum)
- [ ] Ajouter colonnes : `purchased_at`, `expires_at`
- [ ] Ajouter enum `status: { inactive: 0, active: 1, expired: 2, consumed: 3 }`

### **Modèle BookOfEntry :**
- [ ] Refactorer `app/models/book_of_entry.rb`
- [ ] Remplacer `belongs_to :user` par `belongs_to :person`
- [ ] Ajouter `belongs_to :subscription_plan`
- [ ] Ajouter validations pour `sessions_remaining`, `status`
- [ ] Ajouter scopes : `active`, `expired`, `consumed`
- [ ] Ajouter méthode `can_use?` (vérifie status active et sessions > 0)
- [ ] Ajouter méthode `use_session!` (décrémente et met à jour status)
- [ ] Ajouter méthode `expire!` (change status vers expired)

---

## 📅 **CHECKLIST 8 : SYSTÈME DE PRÉSENCE**

### **Migration pour refondre attendances :**
- [ ] Créer migration `refactor_attendances_table`
- [ ] Remplacer `user_id` par `person_id` (foreign key vers `people`)
- [ ] Ajouter colonne `event_id` (foreign key vers `events`, optionnel)
- [ ] Ajouter colonnes : `date`, `created_at`, `updated_at`
- [ ] Ajouter index sur `[person_id, date]` (unique)

### **Migration pour refondre events :**
- [ ] Créer migration `refactor_events_table`
- [ ] Remplacer `title` par `name`
- [ ] Ajouter colonne `category` (enum)
- [ ] Ajouter colonne `description` (remplacer les 3 descriptions)
- [ ] Ajouter enum `category: { show: 0, workshop: 1, volunteering: 2, other: 3 }`
- [ ] Supprimer colonnes obsolètes : `upper_description`, `middle_description`, `bottom_description`

### **Modèle Attendance :**
- [ ] Refactorer `app/models/attendance.rb`
- [ ] Remplacer `belongs_to :user` par `belongs_to :person`
- [ ] Ajouter `belongs_to :event, optional: true`
- [ ] Ajouter validations : `presence: true` pour `person`, `date`
- [ ] Ajouter validation : `uniqueness: { scope: :person_id }` pour `date`
- [ ] Ajouter scopes : `today`, `this_week`, `this_month`

### **Modèle Event :**
- [ ] Refactorer `app/models/event.rb`
- [ ] Remplacer `title` par `name`
- [ ] Remplacer les 3 descriptions par `description`
- [ ] Ajouter `has_many :attendances, dependent: :destroy`
- [ ] Ajouter validations pour `name`, `date`, `category`
- [ ] Ajouter scopes : `show`, `workshop`, `volunteering`, `other`

---

## 🔧 **CHECKLIST 9 : SERVICES MÉTIER**

### **Service Payments::Process :**
- [ ] Créer `app/services/payments/process.rb`
- [ ] Ajouter méthode `call(payment)` pour traiter un paiement
- [ ] Extraire logique de création d'adhésions depuis `Payment`
- [ ] Extraire logique de création de carnets depuis `Payment`
- [ ] Ajouter gestion d'erreurs avec des exceptions personnalisées
- [ ] Ajouter logging des actions importantes

### **Service Attendances::CheckIn :**
- [ ] Créer `app/services/attendances/check_in.rb`
- [ ] Ajouter méthode `call(person, event = nil)` pour pointer
- [ ] Vérifier qu'une personne n'a pas déjà pointé aujourd'hui
- [ ] Créer enregistrement `Attendance`
- [ ] Décrémenter les carnets actifs de type pack10
- [ ] Gérer l'erreur `AlreadyCheckedInError`

### **Service Memberships::Create :**
- [ ] Créer `app/services/memberships/create.rb`
- [ ] Ajouter méthode `call(person, membership_type, started_at = Date.current)`
- [ ] Vérifier qu'une personne n'a pas d'adhésion active
- [ ] Créer l'adhésion avec les bonnes dates
- [ ] Gérer l'upgrade Basic → Circus (préserver `first_joined_at`)

---

## 🎮 **CHECKLIST 10 : CONTRÔLEURS ET VUES**

### **Refactorer PaymentsController :**
- [ ] Modifier `create` pour utiliser `Payments::Process`
- [ ] Modifier `update` pour traiter les changements de statut
- [ ] Ajouter action `new` (formulaire manquant)
- [ ] Ajouter filtres par `person_id`, `payment_method`, `status`
- [ ] Garder toutes les autres actions existantes

### **Créer AttendancesController :**
- [ ] Créer `app/controllers/admin/attendances_controller.rb`
- [ ] Ajouter action `index` (liste des pointages avec filtres)
- [ ] Ajouter action `check_in` (pointage d'une personne)
- [ ] Ajouter action `destroy` (annuler un pointage)
- [ ] Ajouter autorisation admin uniquement

### **Vues manquantes :**
- [ ] Créer `app/views/admin/payments/new.html.erb`
- [ ] Créer `app/views/admin/attendances/index.html.erb`
- [ ] Créer `app/views/admin/attendances/_check_in_form.html.erb`
- [ ] Ajouter liens dans la navigation admin

### **Routes :**
- [ ] Ajouter `resources :attendances` dans `admin`
- [ ] Ajouter `get 'new', on: :collection` pour `payments`
- [ ] Vérifier que toutes les routes fonctionnent

---

## 🧪 **CHECKLIST 11 : TESTS ET VALIDATION**

### **Tests des modèles :**
- [ ] Créer `spec/models/person_spec.rb`
- [ ] Créer `spec/models/membership_spec.rb`
- [ ] Créer `spec/models/membership_type_spec.rb`
- [ ] Créer `spec/models/subscription_plan_spec.rb`
- [ ] Créer `spec/models/payment_spec.rb`
- [ ] Créer `spec/models/payment_line_spec.rb`
- [ ] Créer `spec/models/book_of_entry_spec.rb`
- [ ] Créer `spec/models/attendance_spec.rb`
- [ ] Créer `spec/models/event_spec.rb`

### **Tests des services :**
- [ ] Créer `spec/services/payments/process_spec.rb`
- [ ] Créer `spec/services/attendances/check_in_spec.rb`
- [ ] Créer `spec/services/memberships/create_spec.rb`
- [ ] Tester tous les cas d'erreur et de succès

### **Tests des contrôleurs :**
- [ ] Refactorer `spec/controllers/admin/payments_controller_spec.rb`
- [ ] Créer `spec/controllers/admin/attendances_controller_spec.rb`
- [ ] Tester toutes les actions et autorisations

### **Tests d'intégration :**
- [ ] Créer `spec/system/payment_flow_spec.rb`
- [ ] Créer `spec/system/attendance_flow_spec.rb`
- [ ] Créer `spec/system/membership_flow_spec.rb`

---

## 🚀 **CHECKLIST 12 : MIGRATION DES DONNÉES ET DÉPLOIEMENT**

### **Script de migration des données :**
- [ ] Créer `lib/tasks/migrate_to_person_architecture.rake`
- [ ] Migrer les `users` vers `people` (données personnelles)
- [ ] Migrer les `user_memberships` vers `memberships`
- [ ] Migrer les `payments` vers la nouvelle structure
- [ ] Migrer les `book_of_entries` vers la nouvelle structure
- [ ] Migrer les `attendances` vers la nouvelle structure
- [ ] Créer les `membership_types` et `subscription_plans` par défaut

### **Validation en local :**
- [ ] Exécuter toutes les migrations dans l'ordre
- [ ] Exécuter le script de migration des données
- [ ] Vérifier que toutes les données sont migrées correctement
- [ ] Lancer tous les tests et corriger les erreurs
- [ ] Tester l'interface admin complète

### **Déploiement :**
- [ ] Backup de production
- [ ] Exécuter les migrations en production
- [ ] Exécuter le script de migration des données
- [ ] Vérifier que l'application fonctionne
- [ ] Former les utilisateurs aux nouvelles fonctionnalités

---

## 📊 **CHECKLIST 13 : DONNÉES DE TEST ET SEEDS**

### **Seeds pour membership_types :**
- [ ] Créer `db/seeds/membership_types.rb`
- [ ] Ajouter Basic (15€), Circus Full (25€), Circus Reduced (20€)
- [ ] Ajouter descriptions et catégories

### **Seeds pour subscription_plans :**
- [ ] Créer `db/seeds/subscription_plans.rb`
- [ ] Ajouter plans : Journée (8€), Trimestre (60€), Annuel (200€), Pack10 (70€)
- [ ] Lier les plans aux membership_types circus

### **Seeds pour events :**
- [ ] Créer `db/seeds/events.rb`
- [ ] Ajouter événements de test : spectacles, ateliers, bénévolat
- [ ] Ajouter événements avec différentes catégories

### **Seeds pour people et membres :**
- [ ] Créer `db/seeds/people.rb`
- [ ] Ajouter des personnes de test avec différents profils
- [ ] Ajouter des adhésions de test (actives et expirées)
- [ ] Ajouter des carnets de test (actifs et expirés)

---

## 🎯 **ORDRE D'EXÉCUTION OBLIGATOIRE**

1. **CHECKLIST 1** - Nettoyage et préparation (1 jour)
2. **CHECKLIST 2** - Suppression tables obsolètes (0.5 jour)
3. **CHECKLIST 3** - Modèle Person (1 jour)
4. **CHECKLIST 4** - Système d'adhésions (1.5 jours)
5. **CHECKLIST 5** - Plans d'abonnement (1 jour)
6. **CHECKLIST 6** - Système de paiement (1.5 jours)
7. **CHECKLIST 7** - Système de carnets (1 jour)
8. **CHECKLIST 8** - Système de présence (1 jour)
9. **CHECKLIST 9** - Services métier (2 jours)
10. **CHECKLIST 10** - Contrôleurs et vues (1.5 jours)
11. **CHECKLIST 11** - Tests (2 jours)
12. **CHECKLIST 12** - Migration et déploiement (1 jour)
13. **CHECKLIST 13** - Seeds (0.5 jour)

**Total estimé : 15 jours de développement**

---

## 🚨 **POINTS D'ATTENTION CRITIQUES**

- ⚠️ **MIGRATION INCOHÉRENTE** : Tables supprimées puis recréées - analyser d'abord
- ⚠️ **BACKUP OBLIGATOIRE** avant toute modification
- ⚠️ **TESTS À CHAQUE ÉTAPE** - ne pas avancer si tests cassés
- ⚠️ **ORDRE STRICT** - respecter l'ordre des checklists
- ⚠️ **VALIDATION DONNÉES** - vérifier que rien n'est perdu
- ⚠️ **FORMATION UTILISATEURS** - interface complètement changée

---

*Document de refonte complète - Le Circographe* 🎪