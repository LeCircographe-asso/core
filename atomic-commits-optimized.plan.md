# Plan de Commits Atomiques Optimisé

## Commits à créer (dans l'ordre logique)

### 1. Configuration et Dépendances
**Commit**: `chore: Update dependencies and core configuration`
- `Gemfile`
- `Gemfile.lock`
- `config/initializers/pagy.rb`
- `config/routes.rb`

### 2. Assets et Styles
**Commit**: `chore: Update asset pipeline and stylesheets`
- `app/assets/stylesheets/application.css`
- `app/assets/stylesheets/application.scss`

### 3. Contrôleurs Core
**Commit**: `refactor: Update core application controllers`
- `app/controllers/application_controller.rb`
- `app/controllers/registrations_controller.rb`

### 4. Contrôleurs Admin - Subscription Plans
**Commit**: `feat: Add subscription plans management`
- `app/controllers/admin/subscription_plans_controller.rb`
- `app/views/admin/subscription_plans/index.html.erb`
- `app/views/admin/subscription_plans/edit.html.erb`
- `app/views/admin/subscription_plans/new.html.erb`

### 5. Contrôleurs Admin - Membership Types
**Commit**: `feat: Add membership types management`
- `app/controllers/admin/membership_types_controller.rb`
- `app/views/admin/membership_types/` (dossier complet)

### 6. Contrôleurs Admin - Memberships
**Commit**: `feat: Add memberships management interface`
- `app/views/admin/memberships/new.html.erb`
- `app/views/admin/memberships/_create_membership.html.erb`

### 7. Helpers et Services Core
**Commit**: `refactor: Update core helpers and services`
- `app/helpers/application_helper.rb`
- `app/helpers/role_helper.rb`
- `app/services/people/register.rb`

### 8. Services Spécialisés
**Commit**: `feat: Add specialized services`
- `app/services/duplicate_detection_service.rb`
- `app/services/payments/cash_register.rb`

### 9. Modèles Business Logic
**Commit**: `refactor: Update core business models`
- `app/models/book_of_entry.rb`
- `app/models/membership_type.rb`
- `app/models/payment.rb`
- `app/models/subscription_plan.rb`
- `app/models/user.rb`

### 10. Interface JavaScript
**Commit**: `feat: Add JavaScript controllers for admin interface`
- `app/javascript/controllers/admin_users_controller.js`
- `app/javascript/controllers/form_toggle_controller.js`
- `app/javascript/controllers/search_controller.js`
- `app/javascript/controllers/tooltip_controller.js`

### 11. Vues Admin - Dashboard et Navigation
**Commit**: `refactor: Update admin dashboard and navigation`
- `app/views/admin/dashboard/_admin_lateral_navbar.html.erb`

### 12. Vues Admin - Users Interface
**Commit**: `refactor: Update admin users interface`
- `app/views/admin/users/edit.html.erb`
- `app/views/admin/users/new.html.erb`
- `app/views/admin/users/show.html.erb`

### 13. Vues Admin - Users Duplicates
**Commit**: `feat: Add duplicate users detection interface`
- `app/views/admin/users/duplicates.html.erb`
- `app/views/admin/users/edit_person.html.erb`
- `app/views/admin/users/new_subscription.html.erb`

### 14. Vues Shared Components
**Commit**: `refactor: Update shared components`
- `app/views/shared/_membershipcard.html.erb`

### 15. Migrations - Core Infrastructure
**Commit**: `feat: Add core database infrastructure`
- `db/migrate/20251018182819_create_core_tables.rb`
- `db/migrate/20251018182853_create_membership_system.rb`
- `db/migrate/20251018182907_create_subscription_system.rb`
- `db/migrate/20251018182922_create_payment_system.rb`

### 16. Migrations - Event and Attendance Systems
**Commit**: `feat: Add event and attendance systems`
- `db/migrate/20251018182934_create_event_system.rb`
- `db/migrate/20251018183005_create_attendance_system.rb`

### 17. Migrations - Blog and Content Systems
**Commit**: `feat: Add blog and content management systems`
- `db/migrate/20251018183020_create_blog_system.rb`
- `db/migrate/20251018184551_create_opening_hours.rb`

### 18. Migrations - Audit and System Features
**Commit**: `feat: Add audit logs and system features`
- `db/migrate/20251018185200_create_audit_logs.rb`
- `db/migrate/20251018185428_create_rails_system.rb`

### 19. Migrations - People and Users Updates
**Commit**: `feat: Add people and users table updates`
- `db/migrate/20251019135100_allow_null_email_in_people.rb`
- `db/migrate/20251019224526_add_is_minor_to_people.rb`
- `db/migrate/20251019234546_allow_null_email_in_users.rb`

### 20. Migrations - Payment Methods and Audit
**Commit**: `feat: Add payment methods and audit versioning`
- `db/migrate/20251019232511_add_offered_to_payment_methods.rb`
- `db/migrate/20251020005815_add_audit_versioning_to_articles.rb`
- `db/migrate/20251020010042_fix_uniqueness_constraints_for_versioning.rb`

### 21. Seeds - Core Data
**Commit**: `refactor: Update core seed data`
- `db/seeds/admin.rb`
- `db/seeds/events.rb`
- `db/seeds/membership_types.rb`
- `db/seeds/subscription_plans.rb`

### 22. Rake Tasks
**Commit**: `feat: Add management rake tasks`
- `lib/tasks/create_subscription_plans.rake`
- `lib/tasks/reset_migrations.rake`
- `lib/tasks/update_prices.rake`

### 23. Nettoyage - Suppression des anciennes migrations
**Commit**: `chore: Remove obsolete migration files`
- Tous les fichiers `db/migrate/202412*` supprimés
- Tous les fichiers `db/migrate/202503*` supprimés
- Tous les fichiers `db/migrate/20251014*` supprimés
- `db/seeds/people.rb` supprimé
- `db/seeds/products.rb` supprimé

## Commandes Git (exemple pour les premiers commits)

```bash
# Commit 1: Configuration
git add Gemfile Gemfile.lock config/initializers/pagy.rb config/routes.rb
git commit -m "chore: Update dependencies and core configuration"

# Commit 2: Assets
git add app/assets/stylesheets/application.css app/assets/stylesheets/application.scss
git commit -m "chore: Update asset pipeline and stylesheets"

# Commit 3: Contrôleurs Core
git add app/controllers/application_controller.rb app/controllers/registrations_controller.rb
git commit -m "refactor: Update core application controllers"

# Commit 4: Subscription Plans
git add app/controllers/admin/subscription_plans_controller.rb app/views/admin/subscription_plans/
git commit -m "feat: Add subscription plans management"

# ... et ainsi de suite
```

## Améliorations par rapport au plan précédent

### 🎯 **Réduction de 35 à 23 commits**
- Groupement logique des fonctionnalités liées
- Moins de commits mais toujours atomiques
- Plus facile à gérer et à suivre

### 📋 **Groupement Amélioré**
- **Configuration** → **Assets** → **Contrôleurs** → **Modèles** → **Vues** → **Migrations** → **Seeds**
- **Fonctionnalités** groupées par domaine (subscription, membership, etc.)
- **Infrastructure** séparée des **fonctionnalités métier**

### 🔄 **Ordre Logique**
- Dépendances avant utilisation
- Infrastructure avant fonctionnalités
- Core avant spécialisé

### 📝 **Messages Plus Clairs**
- Focus sur le type de changement (feat, refactor, chore)
- Description concise mais précise
- Groupement cohérent des fichiers

## Total: 23 commits atomiques optimisés
