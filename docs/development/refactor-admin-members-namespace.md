# Refactor : admin/users → admin/members

> **Statut** : legacy (migration terminée — conservé comme trace de décision)
> **Public cible** : contributeur
> **Dernière vérification** : 2026-08-10
> **Sources de vérité** : `app/controllers/admin/members_controller.rb`, `config/routes.rb`, `app/components/admin/members/`.

> ✅ **Cette migration est terminée en code** (routes, controller, vues, composants, helpers, forms, hacks `ViewUserAdapter`/`person_route_key` supprimés). Le plan ci-dessous est conservé tel qu'écrit à l'origine (cases non cochées) comme trace de la décision et de son découpage ; ne pas le relire comme un TODO actif. Vérification : `grep -r "admin_user\b|Admin::Users\b|admin/users\b|UserCreationForm|ViewUserAdapter|PersonRouteKey" app/ config/` ne retourne plus rien côté `app/`/`config/` (hors faux positifs `let(:admin_user)` dans les specs).

## Pourquoi

`admin/users` gère des `Person` (adhérents CRM), pas des `User` (comptes web).
Cette confusion génère un hack `person_route_key` ("person_28"), un `ViewUserAdapter`
(fake User pour les Person sans compte), et des noms de composants trompeurs.

## Ce qui change, ce qui ne change pas

**Ne change pas** : models, services (`People::*`), logique métier, DB.  
**Change** : routes, controller, vues, composants, helpers, I18n keys — noms seulement.

---

## Phase 1 — Nettoyage (petit, sans risque)

### Supprimer le code mort
- [ ] `app/views/admin/users/check_attendance_eligibility.turbo_stream.erb`  
      → action controller supprimée, fichier orphelin
- [ ] Route `get :duplicates, on: :collection` dans `resources :users`  
      → déclarée, jamais implémentée
- [ ] `app/helpers/admin/users/display_helper.rb`  
      → doublon de `app/helpers/admin/users_helper.rb`, fusionner et supprimer

---

## Phase 2 — Migration namespace (mécanique)

### 2a. Routes
```ruby
# Avant
namespace :admin do
  resources :users do ...

# Après
namespace :admin do
  resources :members, controller: 'members' do ...
```

Route helpers générés :
| Avant | Après |
|---|---|
| `admin_users_path` | `admin_members_path` |
| `admin_user_path(@person)` | `admin_member_path(@person)` |
| `new_admin_user_path` | `new_admin_member_path` |
| `edit_admin_user_path` | `edit_admin_member_path` |
| `create_web_account_admin_user_path` | `create_web_account_admin_member_path` |
| `edit_person_admin_user_path` | `edit_person_admin_member_path` |
| `restore_admin_user_path` | `restore_admin_member_path` |

### 2b. Controller principal
```
app/controllers/admin/users_controller.rb
→ app/controllers/admin/members_controller.rb

class Admin::UsersController
→ class Admin::MembersController
```

Supprimer `person_identifier?` / `person_route_key` / `extracted_person_id`  
→ `@person = Person.find(params[:id])` directement (l'ID est toujours celui d'une Person)

Supprimer `ViewUserAdapter` usage  
→ passer `person:` directement aux composants, sans fake User

### 2c. Controller payments (nested)
```
app/controllers/admin/users/payments_controller.rb
→ app/controllers/admin/members/payments_controller.rb

class Admin::Users::PaymentsController
→ class Admin::Members::PaymentsController
```

### 2d. Concerns
```
app/controllers/concerns/admin/users/parameter_handling.rb
→ app/controllers/concerns/admin/members/parameter_handling.rb

app/controllers/concerns/admin/users/update_handling.rb
→ app/controllers/concerns/admin/members/update_handling.rb
```

Renommer les constantes internes :
- `PERSON_FORM_KEYS` → inchangé (nom correct)
- `USER_CONTROL_KEYS` → inchangé (parle de User, c'est juste)

### 2e. Vues
```
app/views/admin/users/
→ app/views/admin/members/
```
17 fichiers à déplacer, contenu inchangé sauf les route helpers.

### 2f. Composants ViewComponent
```
app/components/admin/users/
→ app/components/admin/members/

Admin::Users::UserHeaderComponent    → Admin::Members::MemberHeaderComponent
Admin::Users::UserInfoComponent      → Admin::Members::MemberInfoComponent
Admin::Users::UserTabsComponent      → Admin::Members::MemberTabsComponent
Admin::Users::UserActionsComponent   → Admin::Members::MemberActionsComponent
Admin::Users::UserDisplayComponent   → Admin::Members::MemberDisplayComponent
Admin::Users::MembershipDisplayComponent → Admin::Members::MembershipDisplayComponent (inchangé)
Admin::Users::MemberNumberHistoryComponent → inchangé
Admin::Users::EditableMemberNumberComponent → inchangé
Admin::Users::MemberNumberChangeComponent → inchangé
```

### 2g. Services admin
```
app/services/admin/users/person_route_key.rb  → SUPPRIMER
app/services/admin/users/view_user_adapter.rb → SUPPRIMER
app/services/admin/users/index_query.rb       → app/services/admin/members/index_query.rb
```

### 2h. Forms & Queries
```
app/forms/admin/user_creation_form.rb
→ app/forms/admin/member_creation_form.rb
class Admin::UserCreationForm → class Admin::MemberCreationForm
```

### 2i. Helpers
```
app/helpers/admin/users_helper.rb (après fusion phase 1)
→ app/helpers/admin/members_helper.rb
module Admin::UsersHelper → module Admin::MembersHelper
```

### 2j. I18n
```yaml
# Avant
fr:
  admin:
    users:
      create: ...
      show: ...
      update: ...

# Après
fr:
  admin:
    members:
      create: ...
      show: ...
      update: ...
```

---

## Références à mettre à jour (~100 occurrences)

Fichiers avec le plus d'occurrences :
- `app/controllers/admin/users_controller.rb` (principal)
- `app/components/admin/users/user_actions_component.rb` (6 route helpers)
- `app/views/admin/health_reports/index.html.erb` (8 occurrences)
- `app/controllers/concerns/admin/users/update_handling.rb`
- Tous les controllers qui redirigent vers `admin_users_path`

Commande de vérification post-migration :
```bash
grep -r "admin_user\b\|Admin::Users\|admin/users\|UserCreationForm\|ViewUserAdapter\|PersonRouteKey" \
  app/ config/ spec/ --include="*.rb" --include="*.erb" --include="*.yml" -l
```
Ce grep doit retourner 0 fichier quand la migration est complète.

---

## Ordre d'exécution Phase 2

1. Routes (génère les nouveaux helpers)
2. Controller principal (renommer + simplifier)
3. Vues (déplacer le dossier)
4. Composants (renommer classes + déplacer)
5. Concerns (renommer + déplacer)
6. Services admin (supprimer les 2 hacks, déplacer index_query)
7. Forms (renommer)
8. Helpers (renommer)
9. I18n (renommer clés)
10. Mettre à jour toutes les références
11. `bundle exec rspec` — doit être vert

---

## Phase 3 — Turbo Frames hub (branche séparée)

Hors scope de ce refactor. Voir issue dédiée.
Le hub `/admin/members/:id` devient le cockpit avec sections inline.
