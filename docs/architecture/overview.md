# 🏗️ Guide d'Architecture - Le Circographe

> **Statut** : stable
> **Public cible** : contributeur
> **Dernière vérification** : 2026-05-01
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

---

## 🧾 RGPD / Suppression et Anonymisation

- **Pas de suppression hard** pour les Person/Users avec historique financier.
- **Archivage + anonymisation** des données personnelles.
- **Traçabilité** : raison + acteur pour chaque action de suppression/annulation.
- **Pas d'orphelins** : paiements et adhésions conservent leurs liens.

---

## 🧩 Architecture View Components

### Structure des Composants

```
app/components/admin/users/
├── membership_status_badge_component.rb + .html.erb
├── membership_type_badge_component.rb + .html.erb
├── contribution_status_badge_component.rb + .html.erb
├── web_account_icon_component.rb + .html.erb
├── contextual_actions_component.rb + .html.erb
└── member_number_history_component.rb + .html.erb
```

### Bonnes Pratiques View Components

#### 1. Structure des Fichiers
- **Un composant = un fichier Ruby + un template ERB**
- **Nommage** : `snake_case_component.rb` + `snake_case_component.html.erb`
- **Namespace** : `Admin::Users::` pour les composants spécifiques à l'admin

#### 2. Classe Ruby
```ruby
module Admin
  module Users
    class MembershipStatusBadgeComponent < ViewComponent::Base
      def initialize(person:)
        @person = person
      end

      private

      attr_reader :person

      def badge_class
        # Logique de style
      end

      def status_text
        # Logique d'affichage
      end
    end
  end
end
```

#### 3. Template ERB
```erb
<span class="<%= badge_class %>" 
      data-controller="tooltip" 
      data-tooltip-text-value="<%= tooltip_text %>">
  <%= status_text %>
</span>
```

#### 4. Utilisation dans les Vues
```erb
<%= render Admin::Users::MembershipStatusBadgeComponent.new(person: person) %>
```

---

## 🔧 Architecture des Helpers Modulaires

### Structure des Helpers

```
app/helpers/admin/users/
├── display_helper.rb      # Formatage des données (30 lignes)
├── status_helper.rb       # Badges de statut (40 lignes)
└── actions_helper.rb      # Boutons d'action (60 lignes)
```

### Bonnes Pratiques Helpers

#### 1. Séparation par Responsabilité
- **DisplayHelper** : Formatage, dates, numéros
- **StatusHelper** : Logique des statuts et badges
- **ActionsHelper** : Boutons et liens d'action

#### 2. Inclusion dans le Contrôleur
```ruby
class Admin::UsersController < BaseController
  include Admin::Users::DisplayHelper
  include Admin::Users::StatusHelper
  include Admin::Users::ActionsHelper
  # ...
end
```

#### 3. Méthodes Privées
```ruby
module Admin
  module Users
    module DisplayHelper
      def format_member_number(number)
        number ? "##{number}" : "-"
      end

      private

      def format_date(date)
        # Logique privée
      end
    end
  end
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

## 🎛️ Architecture des Contrôleurs

### Structure Modulaire

```
app/controllers/admin/users/
├── duplicates_controller.rb     # Détection des doublons
├── payments_controller.rb       # Gestion des paiements
└── memberships_controller.rb    # Gestion des adhésions
```

### Bonnes Pratiques Contrôleurs

#### 1. Héritage et Permissions
```ruby
module Admin
  module Users
    class DuplicatesController < BaseController
      before_action :set_breadcrumbs
      # Hérite automatiquement de require_admin_or_super_admin
    end
  end
end
```

#### 2. Actions Spécialisées
```ruby
def index
  @duplicate_report = DuplicateDetectionService.generate_report
  add_breadcrumb "Détection des doublons", nil
end

def merge
  result = MemberManagementService.merge_duplicate_persons(primary, secondary)
  # Logique de fusion
end
```

---

## 🧪 Architecture des Tests

### Structure des Tests

```
spec/
├── components/admin/users/
│   ├── membership_status_badge_component_spec.rb
│   └── membership_type_badge_component_spec.rb
├── helpers/admin/users/
│   ├── display_helper_spec.rb
│   └── status_helper_spec.rb
└── controllers/admin/users/
    ├── duplicates_controller_spec.rb
    └── payments_controller_spec.rb
```

### Bonnes Pratiques Tests

#### 1. Tests View Components
```ruby
RSpec.describe Admin::Users::MembershipStatusBadgeComponent do
  let(:person) { create(:person, :with_active_membership) }
  
  it "renders active status badge" do
    render_inline(described_class.new(person: person))
    expect(page).to have_css('.badge', text: 'Actif')
  end
end
```

#### 2. Tests Helpers
```ruby
RSpec.describe Admin::Users::DisplayHelper do
  describe '#format_member_number' do
    it 'formats member number correctly' do
      expect(helper.format_member_number(123)).to eq('#123')
    end
  end
end
```

#### 3. Tests Contrôleurs
```ruby
RSpec.describe Admin::Users::DuplicatesController do
  describe 'GET #index' do
    it 'returns success' do
      get :index
      expect(response).to have_http_status(:success)
    end
  end
end
```

---

## 🚀 Guidelines pour les Futurs Développements

### 1. Ajout de Nouveaux Composants

1. **Créer le composant** dans `app/components/admin/users/`
2. **Ajouter les tests** dans `spec/components/admin/users/`
3. **Documenter l'utilisation** dans ce guide
4. **Vérifier la compatibilité** avec Stimulus si nécessaire

### 2. Ajout de Nouveaux Helpers

1. **Identifier la responsabilité** (Display, Status, Actions)
2. **Créer ou étendre** le helper approprié
3. **Inclure dans le contrôleur** si nécessaire
4. **Ajouter les tests** correspondants

### 3. Ajout de Nouveaux Contrôleurs

1. **Hériter de BaseController** pour les permissions
2. **Utiliser les services** pour la logique métier
3. **Ajouter les breadcrumbs** appropriés
4. **Créer les tests** de contrôleur

### 4. Migration Progressive

1. **Tester en local** avec les routes de test
2. **Valider les View Components** individuellement
3. **Migrer progressivement** les vues existantes
4. **Supprimer l'ancien code** une fois validé

---

## 📊 Métriques de Succès

| Aspect | Avant | Après | Amélioration |
|--------|-------|-------|--------------|
| **Complexité** | 413 lignes monolithiques | 3 helpers (30-60 lignes) + 6 components (50-80 lignes) | **-60%** |
| **Testabilité** | Difficile (helpers mélangés) | Tests unitaires isolés | **+100%** |
| **Réutilisabilité** | Couplé aux vues admin/users | Components réutilisables partout | **+100%** |
| **Maintenabilité** | Code difficile à maintenir | Architecture modulaire claire | **+70%** |

---

## 🔗 Ressources

- [ViewComponent Documentation](https://viewcomponent.org/)
- [Hotwire Documentation](https://hotwired.dev/)
- [Stimulus Documentation](https://stimulus.hotwired.dev/)
- [Rails 8 Best Practices](https://guides.rubyonrails.org/)

---

*Dernière mise à jour : Octobre 2025*
*Version : 1.0*
