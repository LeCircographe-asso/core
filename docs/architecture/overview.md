# 🏗️ Guide d'Architecture - Le Circographe

> **Statut** : stable
> **Public cible** : contributeur
> **Dernière vérification** : 2026-08-10
> **Sources de vérité** : `app/models/person.rb`, `app/models/user.rb`, `app/components/`, `app/services/people/`.

> **Vocabulaire** : le composant `contribution_status_badge_component` et les services `People::Contribution*` sont la référence canonique. Voir [`../glossary.md`](../glossary.md).

## 📋 Vue d'Ensemble

Ce document consolide les bonnes pratiques et l'architecture mise en place lors du refactoring du système de gestion des utilisateurs du Circographe.

## 🎯 Objectifs de l'Architecture

- **Modularité** : Séparation claire des responsabilités
- **Réutilisabilité** : Composants réutilisables dans toute l'application
- **Maintenabilité** : Code facile à maintenir et étendre
- **Testabilité** : Tests unitaires isolés et efficaces
- **Performance** : Optimisation des requêtes et du rendu

---

## 👤 Person / User - Règles de Cycle de Vie

- **Person = source de vérité** pour l'identité et la finance.
- **User = compte web** (authentification + permissions). **Données : chaque User a une Person** (`person_id` NOT NULL) ; le compte web reste **optionnel au niveau métier** pour une Person donnée (CRM sans login).
- **Cas supportés** :
  - Person sans User (inscription IRL d'abord).
  - Inscription web : création d’un **couple User + Person** (personne minimale puis enrichissement / rattachement à une fiche existante).
- **Lien / rattachement explicite** : `People::AttachUserToPerson` (nominal), `People::AccountLinker` (orchestration), jamais d’assign direct dans un controller.
- **Pas de reliaison implicite** si une Person a déjà un User lié (garde-fous dans `AttachUserToPerson`).
- **Pas d'orphelins financiers** : paiements et adhésions restent rattachés à la Person.

---

## 🧭 Service Entry Points (Flux Unifiés)

- **Création Person / User / Membership** : `People::Register`
- **Rattachement User ↔ Person** : `People::AttachUserToPerson` ; **orchestration** : `People::AccountLinker`
- **Achat adhésion** : `People::MembershipCreator`
- **Achat cotisation** : `People::ContributionCreator`
- **Mise à jour User + Person** : `UserManagement::UserUpdater`
- **Paiement** : `People::PaymentCreator`, `People::PaymentUpdater`, `People::PaymentCanceller`

> Les contrôleurs doivent rester minces : valider les params, appeler un service, render/redirect.
>
> Exception notable encore présente côté modèle : `Person#renew_membership!`. C'est le dernier gros workflow métier conservé sur `Person` avant extraction éventuelle vers un service dédié.

---

## 🧾 RGPD / Suppression et Anonymisation

- **Pas de suppression hard** pour les Person/Users avec historique financier.
- **Archivage + anonymisation** des données personnelles.
- **Traçabilité** : raison + acteur pour chaque action de suppression/annulation.
- **Pas d'orphelins** : paiements et adhésions conservent leurs liens.

---

## 🧩 View Components

### Structure réelle

```
app/components/
├── membership_status_badge_component.rb + .html.erb   (top-level)
├── contribution_status_badge_component.rb + .html.erb (top-level)
├── web_account_icon_component.rb + .html.erb          (top-level)
├── contextual_actions_component.rb + .html.erb        (top-level)
├── ui/                                                 (composants UI génériques)
├── admin/members/                                      (9 composants spécifiques fiche membre)
└── admin/payments/                                      (payment_display, payment_summary, payment_actions)
```

Les badges et actions génériques sont **top-level**, pas namespacés — réutilisables aussi bien en admin qu'en public. Seuls les composants propres à une vue admin précise (fiche membre, paiements) sont namespacés sous `Admin::Members::` / `Admin::Payments::`.

> **Hygiène** : `app/components/` a accumulé des composants créés puis jamais branchés (ex. anciens `MemberNumberHistoryComponent`, `AttendanceStatusComponent`, `MembershipTypeBadgeComponent`, supprimés du schéma ci-dessus le 2026-08-10 faute d'usage réel). Avant de considérer un composant comme référence, vérifier qu'il est bien rendu quelque part : `grep -rn "NomDuComponent" app/views app/components app/controllers` doit remonter autre chose que sa propre définition.

### Partial vs Component — comment choisir

Les deux coexistent volontairement dans ce projet, pour deux besoins différents — ce n'est pas une hésitation entre deux approches, chacun a son rôle :

- **Partial** (`_xxx.html.erb`) : fragment de HTML réutilisable, sans classe Ruby dédiée, sans contrat explicite sur ses `locals`. À réserver à l'assemblage pur (aucune décision/logique), ou comme **point d'adressage pour Turbo Streams** — `turbo_stream.replace("cible", partial: "...", locals: {...})` a besoin d'un nom de fichier, pas d'une classe Ruby.
- **Component** (`ViewComponent::Base`) : dès qu'il y a la moindre logique (formatage, `render?` conditionnel, statut calculé). Contrat explicite via `initialize(...)`, logique testable en isolation (`render_inline` en spec), sans polluer un helper global.

**Pattern « pont Turbo » légitime** — ex. `admin/payments/_payment_summary.html.erb` → `Admin::Payments::PaymentSummaryComponent` : la partial ne contient qu'un `render Admin::Payments::PaymentSummaryComponent.new(...)`, rien d'autre. C'est voulu : elle sert uniquement de nom adressable pour `turbo_stream.replace`, tout le contenu réel vit dans le component. Même chose pour `_payment_actions.html.erb` → `PaymentActionsComponent`. Ne pas « simplifier » ces paires, c'est le pont qui permet d'avoir à la fois un component testable et une cible Turbo Stream.

**Signal d'alerte (doublon mort, pas un pont voulu)** : une partial et un component au nom proche qui contiennent CHACUN leur propre HTML indépendant, au lieu que l'un délègue à l'autre. Dans ce cas l'un des deux ne sert plus à rien — vérifier avec le grep ci-dessus avant d'en garder deux, et supprimer celui qui n'a aucun usage réel plutôt que de le laisser trainer.

### Bonnes Pratiques View Components

- **Un composant = un fichier Ruby + un template ERB**
- **Nommage** : `snake_case_component.rb` + `snake_case_component.html.erb`
- **Namespace** uniquement si le composant est spécifique à une zone (`Admin::Members::`, `Admin::Payments::`) ; sinon top-level

```ruby
class MembershipStatusBadgeComponent < ViewComponent::Base
  def initialize(person:)
    @person = person
  end

  private

  attr_reader :person
end
```

```erb
<%= render MembershipStatusBadgeComponent.new(person: person) %>
```

---

## 🔧 Helpers Admin

### Structure réelle

```
app/helpers/admin/
├── members_helper.rb
├── memberships_helper.rb
└── payments_helper.rb
```

Un helper par ressource admin (pas de split Display/Status/Actions en sous-modules), inclus directement dans le contrôleur correspondant.

```ruby
class Admin::MembersController < BaseController
  include Admin::MembersHelper
  # ...
end
```

---

## 🎮 Architecture Hotwire/Stimulus

### Bonnes Pratiques Hotwire

#### 1. Turbo Frames
```erb
<%= turbo_frame_tag "user_#{user.id}" do %>
  <!-- Contenu mis à jour via Turbo -->
<% end %>
```

#### 2. Turbo Streams
```ruby
def update
  if @user.update(user_params)
    render turbo_stream: turbo_stream.replace("user_#{@user.id}", 
                                             partial: "user", 
                                             locals: { user: @user })
  end
end
```

### Bonnes Pratiques Stimulus

#### 1. Controllers Stimulus
```javascript
// app/javascript/controllers/tooltip_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content"]
  static values = { text: String }

  connect() {
    this.showTooltip()
  }

  showTooltip() {
    // Logique du tooltip
  }
}
```

#### 2. Data Attributes
```erb
<div data-controller="tooltip" 
     data-tooltip-text-value="<%= tooltip_text %>">
  <!-- Contenu -->
</div>
```

#### 3. Compatibilité avec View Components
- Les View Components peuvent utiliser des data attributes Stimulus
- Éviter les conflits de noms entre composants
- Utiliser des namespaces pour les controllers Stimulus

---

## 🎛️ Contrôleurs Admin

### Structure réelle

```
app/controllers/admin/
├── members_controller.rb           # CRUD membres (Person/User)
├── members/payments_controller.rb  # Paiements imbriqués sous un membre (seule exception au flat)
├── payments_controller.rb          # Paiements admin, vue globale
├── memberships_controller.rb
├── contribution_formulas_controller.rb
├── contributions_controller.rb
├── events_controller.rb
├── base_controller.rb              # Permissions communes
└── ... (un contrôleur plat par ressource, CRUD inline)
```

Les contrôleurs admin sont **plats** (un fichier par ressource, pas de sous-namespace), à une exception près : `Admin::Members::PaymentsController`, imbriqué car les paiements y sont toujours scopés à un membre.

```ruby
module Admin
  class MembersController < BaseController
    # Hérite de BaseController pour les permissions (require_admin_zone_access)
  end
end
```

> Note : la route `resources :duplicates` (`config/routes.rb`) est déclarée sans contrôleur `Admin::DuplicatesController` correspondant — fonctionnalité de détection/fusion de doublons en réflexion (import Excel de membres à venir), pas encore décidée. Voir [`internal/todo.md`](../internal/todo.md).

---

## 🧪 Tests

Rails 8 / RSpec : **request specs**, pas de controller specs classiques.

```
spec/
├── requests/admin/
│   ├── members_spec.rb
│   ├── member_payments_spec.rb
│   └── ... (un spec par ressource)
├── components/
│   ├── admin/payments/  (payment_display, payment_summary)
│   └── ui/               (disabled_button)
└── helpers/
    ├── application_helper_spec.rb
    └── membership_card_helper_spec.rb
```

Les component specs pour les badges top-level (`MembershipStatusBadgeComponent`, etc.) ne sont pas encore écrits — voir [`development/testing.md`](../development/testing.md) pour la philosophie de test complète et les gaps de couverture.

---

## 🔗 Ressources

- [ViewComponent Documentation](https://viewcomponent.org/)
- [Hotwire Documentation](https://hotwired.dev/)
- [Stimulus Documentation](https://stimulus.hotwired.dev/)
- [Rails 8 Best Practices](https://guides.rubyonrails.org/)
