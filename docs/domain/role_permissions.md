# Rôles et permissions

> **Statut** : stable
> **Public cible** : contributeur
> **Dernière vérification** : 2026-08-10
> **Sources de vérité** : `app/models/user.rb` (enum `system_role`), `app/controllers/admin/base_controller.rb`, `app/controllers/admin/members_controller.rb`.

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

**`has_privileges?`** → `true` pour `super_admin`, `admin`, `volunteer` — donne l'accès à la zone admin.  
**`admin?`** → `true` pour `super_admin` et `admin` uniquement.

---

## Accès zone admin

La zone `/admin/` requiert `has_privileges?` via `Admin::BaseController#require_admin_zone_access`.  
Les `web_visitor` sont redirigés vers `/` avec une alerte.

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

---

## Feature flags (complémentaire aux rôles)

Les rôles contrôlent *qui* peut faire quoi quand une fonctionnalité est ouverte.  
Les feature flags contrôlent *si* la fonctionnalité est disponible dans l'app.

| Flag | Variable d'env | Défaut |
|------|----------------|--------|
| Inscriptions publiques | `PUBLIC_REGISTRATION_ENABLED` | `true` |

> Les feature flags sont gérés par des constantes / variables d'env pour l'instant. Une évolution vers un dashboard admin est envisagée (voir [`../internal/todo.md`](../internal/todo.md) §1).
