# Plan de Commits Atomiques Détaillés

## Commits à créer (dans l'ordre logique)

### 1. Dependencies et Assets
**Commit**: `chore: Update dependencies and asset configuration`
- `Gemfile`
- `Gemfile.lock`
- `app/assets/stylesheets/application.css`
- `app/assets/stylesheets/application.scss`

### 2. Contrôleurs Admin - Subscription Plans
**Commit**: `feat: Add subscription plans management`
- `app/controllers/admin/subscription_plans_controller.rb`
- `app/views/admin/subscription_plans/index.html.erb`
- `app/views/admin/subscription_plans/edit.html.erb`
- `app/views/admin/subscription_plans/new.html.erb`

### 3. Contrôleurs Admin - Membership Types
**Commit**: `feat: Add membership types management`
- `app/controllers/admin/membership_types_controller.rb`
- `app/views/admin/membership_types/` (dossier complet)

### 4. Contrôleurs Admin - Memberships
**Commit**: `feat: Add memberships management interface`
- `app/views/admin/memberships/new.html.erb`
- `app/views/admin/memberships/_create_membership.html.erb`

### 5. Contrôleurs Core - Application et Registration
**Commit**: `refactor: Update core controllers`
- `app/controllers/application_controller.rb`
- `app/controllers/registrations_controller.rb`

### 6. Helpers - Application et Role
**Commit**: `refactor: Update application and role helpers`
- `app/helpers/application_helper.rb`
- `app/helpers/role_helper.rb`

### 7. Modèles - Core Business Logic
**Commit**: `refactor: Update core business models`
- `app/models/book_of_entry.rb`
- `app/models/membership_type.rb`
- `app/models/payment.rb`
- `app/models/subscription_plan.rb`
- `app/models/user.rb`

### 8. Services - People Registration
**Commit**: `refactor: Update people registration service`
- `app/services/people/register.rb`

### 9. Services - Duplicate Detection
**Commit**: `feat: Add duplicate detection service`
- `app/services/duplicate_detection_service.rb`

### 10. Services - Cash Register
**Commit**: `feat: Add cash register payment service`
- `app/services/payments/cash_register.rb`

### 11. JavaScript Controllers
**Commit**: `feat: Add JavaScript controllers for admin interface`
- `app/javascript/controllers/admin_users_controller.js`
- `app/javascript/controllers/form_toggle_controller.js`
- `app/javascript/controllers/search_controller.js`
- `app/javascript/controllers/tooltip_controller.js`

### 12. Vues Admin - Dashboard et Navigation
**Commit**: `refactor: Update admin dashboard and navigation`
- `app/views/admin/dashboard/_admin_lateral_navbar.html.erb`

### 13. Vues Admin - Users Interface
**Commit**: `refactor: Update admin users interface`
- `app/views/admin/users/edit.html.erb`
- `app/views/admin/users/new.html.erb`
- `app/views/admin/users/show.html.erb`

### 14. Vues Admin - Users Duplicates
**Commit**: `feat: Add duplicate users detection interface`
- `app/views/admin/users/duplicates.html.erb`
- `app/views/admin/users/edit_person.html.erb`
- `app/views/admin/users/new_subscription.html.erb`

### 15. Vues Shared - Membership Card
**Commit**: `refactor: Update shared membership card component`
- `app/views/shared/_membershipcard.html.erb`

### 16. Configuration - Routes
**Commit**: `refactor: Update application routes`
- `config/routes.rb`

### 17. Configuration - Pagy
**Commit**: `feat: Add pagination configuration`
- `config/initializers/pagy.rb`

### 18. Migrations - Core Tables
**Commit**: `feat: Add core database tables migration`
- `db/migrate/20251018182819_create_core_tables.rb`

### 19. Migrations - Membership System
**Commit**: `feat: Add membership system migration`
- `db/migrate/20251018182853_create_membership_system.rb`

### 20. Migrations - Subscription System
**Commit**: `feat: Add subscription system migration`
- `db/migrate/20251018182907_create_subscription_system.rb`

### 21. Migrations - Payment System
**Commit**: `feat: Add payment system migration`
- `db/migrate/20251018182922_create_payment_system.rb`

### 22. Migrations - Event System
**Commit**: `feat: Add event system migration`
- `db/migrate/20251018182934_create_event_system.rb`

### 23. Migrations - Attendance System
**Commit**: `feat: Add attendance system migration`
- `db/migrate/20251018183005_create_attendance_system.rb`

### 24. Migrations - Blog System
**Commit**: `feat: Add blog system migration`
- `db/migrate/20251018183020_create_blog_system.rb`

### 25. Migrations - Opening Hours
**Commit**: `feat: Add opening hours migration`
- `db/migrate/20251018184551_create_opening_hours.rb`

### 26. Migrations - Audit Logs
**Commit**: `feat: Add audit logs migration`
- `db/migrate/20251018185200_create_audit_logs.rb`

### 27. Migrations - Rails System
**Commit**: `feat: Add Rails system migration`
- `db/migrate/20251018185428_create_rails_system.rb`

### 28. Migrations - People Updates
**Commit**: `feat: Add people table updates`
- `db/migrate/20251019135100_allow_null_email_in_people.rb`
- `db/migrate/20251019224526_add_is_minor_to_people.rb`

### 29. Migrations - Payment Methods
**Commit**: `feat: Add payment methods updates`
- `db/migrate/20251019232511_add_offered_to_payment_methods.rb`

### 30. Migrations - Users Updates
**Commit**: `feat: Add users table updates`
- `db/migrate/20251019234546_allow_null_email_in_users.rb`

### 31. Migrations - Audit Versioning
**Commit**: `feat: Add audit versioning for articles`
- `db/migrate/20251020005815_add_audit_versioning_to_articles.rb`
- `db/migrate/20251020010042_fix_uniqueness_constraints_for_versioning.rb`

### 32. Seeds - Admin, Events, Membership Types
**Commit**: `refactor: Update admin, events and membership types seeds`
- `db/seeds/admin.rb`
- `db/seeds/events.rb`
- `db/seeds/membership_types.rb`

### 33. Seeds - Subscription Plans
**Commit**: `refactor: Update subscription plans seeds`
- `db/seeds/subscription_plans.rb`

### 34. Rake Tasks
**Commit**: `feat: Add management rake tasks`
- `lib/tasks/create_subscription_plans.rake`
- `lib/tasks/reset_migrations.rake`
- `lib/tasks/update_prices.rake`

### 35. Nettoyage - Suppression des anciennes migrations
**Commit**: `chore: Remove obsolete migration files`
- Tous les fichiers `db/migrate/202412*` supprimés
- Tous les fichiers `db/migrate/202503*` supprimés
- Tous les fichiers `db/migrate/20251014*` supprimés
- `db/seeds/people.rb` supprimé
- `db/seeds/products.rb` supprimé

## Commandes Git (exemple pour les premiers commits)

```bash
# Commit 1: Dependencies
git add Gemfile Gemfile.lock app/assets/stylesheets/application.css app/assets/stylesheets/application.scss
git commit -m "chore: Update dependencies and asset configuration"

# Commit 2: Subscription Plans
git add app/controllers/admin/subscription_plans_controller.rb app/views/admin/subscription_plans/
git commit -m "feat: Add subscription plans management"

# Commit 3: Membership Types
git add app/controllers/admin/membership_types_controller.rb app/views/admin/membership_types/
git commit -m "feat: Add membership types management"

# ... et ainsi de suite pour chaque groupe
```

## Notes importantes

- Chaque commit est atomique et représente une fonctionnalité ou un refactoring spécifique
- Les commits suivent l'ordre logique des dépendances
- Les messages utilisent la convention Conventional Commits
- Chaque commit peut être testé et déployé indépendamment
- Total: 35 commits atomiques pour une granularité maximale
