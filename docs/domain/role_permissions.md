# Rôles et permissions

> **Statut** : stable
> **Public cible** : contributeur
> **Dernière vérification** : 2026-10-03
> **Sources de vérité** : `app/models/user.rb` (enum `system_role`, `assignable_roles`, `can_change_role_of?`), `app/models/concerns/roleable.rb`, `app/controllers/admin/base_controller.rb`, `app/controllers/admin/members_controller.rb`, `app/services/user_management/role_changer.rb`.

---

## Rôles système

```ruby
enum :system_role, { super_admin: 0, admin: 1, volunteer: 2, web_visitor: 3 }
```

| Rôle | Valeur | Description |
|------|--------|-------------|
| `super_admin` | 0 | Accès total, y compris suppression et modification des formules |
| `admin` | 1 | Gestion complète membres, paiements, cotisations (sauf actions super_admin) |
| `volunteer` | 2 | Accès zone admin en lecture + enregistrement présences |
| `web_visitor` | 3 | Accès public uniquement (son propre profil) |

### Convention de nommage (depuis 2026-08-10)

Deux familles de méthodes, jamais mélangées :

- **Rôle exact** (`super_admin?`, `admin?`, `volunteer?`, `web_visitor?`) — générés nativement par l'enum Rails, jamais redéfinis à la main (un override silencieux de `admin?` a existé par le passé et causait un vrai bug de permission — voir historique git de `app/models/user.rb`). `admin?` est `true` **uniquement** pour `admin`, pas pour `super_admin`.
- **Capacité** (nommée par l'action, cumulative sur plusieurs rôles) — `User#can_access_admin_zone?` (super_admin/admin/volunteer), `Roleable#can_administer?` (super_admin/admin), `Roleable#can_manage_payments?`, `can_manage_events?`, etc. **Toujours privilégier ces méthodes** dans les contrôleurs/vues plutôt qu'un test de rôle brut (`system_role == 'admin'`) ou une combinaison `super_admin? || admin?` recopiée en dur.

**`can_access_admin_zone?`** → `true` pour `super_admin`, `admin`, `volunteer` — donne l'accès à la zone admin.  
**`can_administer?`** → `true` pour `super_admin` et `admin` uniquement.

---

## Accès zone admin

La zone `/admin/` requiert `can_access_admin_zone?` via `Admin::BaseController#require_admin_zone_access`.  
Les `web_visitor` sont redirigés vers `/` avec une alerte.

## Assignation de rôle

`User#assignable_roles` est la source unique pour « quels rôles cet utilisateur a-t-il le droit d'attribuer à un autre compte » — `super_admin` peut tout distribuer sauf `super_admin` ; `admin` peut distribuer `volunteer`/`web_visitor` uniquement. Utilisée à la fois pour peupler les `<select>` de rôle (formulaires membre) **et** revalidée côté serveur dans `UserManagement::UserUpdater` et `Admin::MemberCreationForm` (`User#can_assign_role?(role)`) — avant le 2026-08-10, la règle n'existait qu'en vue, ce qui permettait à un `admin` de s'auto-promouvoir `super_admin` en forgeant la requête.

---

## Matrice des permissions par action

### Gestion des membres (Admin::MembersController)

| Action | super_admin | admin | volunteer |
|--------|-------------|-------|-----------|
| Lister les membres | ✅ | ✅ | ✅ |
| Voir la fiche d'un membre | ✅ | ✅ | ✅ |
| Créer un membre | ✅ | ✅ | ❌ |
| Modifier un membre | ✅ | ✅ | ❌ |
| Supprimer/archiver un membre | ✅ (si rôle inférieur) | ✅ (si rôle inférieur) | ❌ |
| Restaurer un compte archivé | ✅ | ❌ | ❌ |

> Un admin ne peut pas supprimer un user avec un rôle ≥ au sien (`has_higher_permissions?`).

### Adhésions (Admin::MembershipsController)

| Action | super_admin | admin | volunteer |
|--------|-------------|-------|-----------|
| Voir les adhésions | ✅ | ✅ | ✅ |
| Créer / upgrader une adhésion | ✅ | ✅ | ❌ |
| Modifier une adhésion | ✅ | ✅ | ❌ |
| Désactiver une adhésion | ✅ | ✅ | ❌ |

### Cotisations (Admin::ContributionFormulasController)

| Action | super_admin | admin | volunteer |
|--------|-------------|-------|-----------|
| Voir les formules | ✅ | ✅ | ✅ |
| Acheter une cotisation pour un membre | ✅ | ✅ | ❌ |
| Créer / modifier / supprimer une formule | ✅ | ❌ | ❌ |

### Paiements (Admin::PaymentsController)

| Action | super_admin | admin | volunteer |
|--------|-------------|-------|-----------|
| Voir les paiements | ✅ | ✅ | ✅ |
| Créer un paiement | ✅ | ✅ | ❌ |
| Modifier un paiement | ✅ | ✅ | ❌ |
| Annuler un paiement | ✅ | ✅ | ❌ |
| Restaurer un paiement annulé | ✅ | ✅ | ❌ |
| Créer un paiement "offert" | ✅ | ✅ | ❌ |

> Paiement offert (`payment_method: "offered"`) requiert un `offer_reason` obligatoire.

### Présences (Admin::AttendancesController)

| Action | super_admin | admin | volunteer |
|--------|-------------|-------|-----------|
| Voir les présences | ✅ | ✅ | ✅ |
| Enregistrer une présence | ✅ | ✅ | ✅ |
| Supprimer une présence | ✅ | ✅ | ✅ |

### Exports (Admin::ExportsController)

| Action | super_admin | admin | volunteer |
|--------|-------------|-------|-----------|
| Export newsletter | ✅ | ✅ | ❌ |
| Export tous utilisateurs | ✅ | ✅ | ❌ |

---

## Attribution des rôles

| Qui peut assigner | Rôles assignables |
|-------------------|-------------------|
| `super_admin` | Tous sauf `super_admin` |
| `admin` | `volunteer`, `web_visitor` |
| `volunteer` / `web_visitor` | Aucun |

Deux conditions cumulatives pour changer le rôle d'un compte existant (`UserManagement::RoleChanger`, et `UserManagement::UserUpdater` pour un changement de rôle) :

1. **Le compte visé** : `User#can_change_role_of?(other)`. Il faut être de rang strictement supérieur au rôle actuel du compte (`has_higher_permissions?`), et ce n'est jamais possible sur son propre compte. Un admin ne touche donc ni aux autres admins ni aux super_admins, et un super_admin n'est jamais rétrogradable depuis l'interface (ce qui protège aussi contre la perte du dernier super_admin).
2. **Le nouveau rôle** : `User#can_assign_role?(role)` (tableau ci-dessus).

Nommer un `super_admin` reste hors interface (console / `People::BootstrapSuperAdmin`).

### Où changer un rôle

- **Fiche membre** (`/admin/members/:id`, carte « Informations de base ») : liste déroulante + bouton « Changer », visible si `can_change_role_of?`, simple libellé sinon. Seulement si la personne a un compte web.
- **Page Rôles** (`/admin/roles`, menu Gestion, admin/super_admin) : liste des comptes `super_admin`/`admin`/`volunteer`, et recherche d'un compte `web_visitor` à promouvoir.

Les deux passent par `PATCH /admin/members/:member_id/role` (`Admin::Members::RolesController`, garde `require_admin_rights`). Retirer un rôle = repasser le compte en `web_visitor`. Chaque changement émet `user.role_changed` (`ActiveSupport::Notifications`, payload `user_id`, `person_id`, `changed_by_id`, `from`, `to`).

---

## Feature flags (complémentaire aux rôles)

Les rôles contrôlent *qui* peut faire quoi quand une fonctionnalité est ouverte.  
Les feature flags contrôlent *si* la fonctionnalité est disponible dans l'app.

| Flag | Variable d'env | Défaut |
|------|----------------|--------|
| Inscriptions publiques | `PUBLIC_REGISTRATION_ENABLED` | `true` |

> Les feature flags sont gérés par des constantes / variables d'env pour l'instant. Une évolution vers un dashboard admin est envisagée (voir [`../internal/todo.md`](../internal/todo.md) §1).
