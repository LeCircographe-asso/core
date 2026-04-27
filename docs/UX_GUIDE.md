# Guide UX/UI - Le Circographe

**Date:** 2025-01-31  
**Status:** ⚠️ EN COURS - Problèmes critiques identifiés

---

## 🎯 Résumé Exécutif

**État actuel:** L'application a une architecture backend solide mais souffre de problèmes UX/UI majeurs qui empêchent une utilisation fluide.

**Blocages identifiés (mise à jour):**
1. ⚠️ Procédure d'adhésion complexe et lourde
2. ⚠️ Newsletter: code legacy + service incomplet (public now via People::NewsletterSignup)
3. ⚠️ Gestion compte web: conflit Person.newsletter_subscribed vs NewsletterSubscriber
4. ⚠️ Édition "inline" informations personnelles manquante
5. ⚠️ Workflow validation/erreurs pas clair pour l'utilisateur

**Priorité:** 🔴 **HAUTE** - Bloquant pour l'utilisateur final

---

## 🔴 Problème 1: Procédure d'Adhésion Complexe

### Analyse

**Fichiers concernés (après refacto People):**
- `app/controllers/registrations_controller.rb`
- `app/services/web/user_registration.rb` (→ `People::Register`)
- `app/services/people/register.rb`
- `app/services/people/person_creator.rb`
- `app/services/people/user_account_creator.rb`
- `app/services/people/membership_creator.rb`
- `app/views/registrations/new.html.erb`

### Nouveau workflow (People::Register)

```
Utilisateur → Formulaire inscription
  ↓
Web::UserRegistration.call
  ↓
People::Register.new(
  person_params,
  create_user_account: true,
  create_membership: false,
  newsletter_subscribed: ...
).call
  ↓
People::PersonCreator -> crée/maj Person (newsletter incluse)
People::UserAccountCreator -> crée/maj User
People::MembershipCreator -> (optionnel si achat immédiat)
  ↓
Success/Error (centralisé)
```

### Problèmes identifiés

- ❌ Trop d'étapes pour l'utilisateur
- ❌ Messages d'erreur pas clairs
- ❌ Pas de feedback progressif
- ❌ Conflit entre Person et User

### Plan d'Action (mis à jour)

**Statut actuel :** ✅ Back-end unifié (`People::Register`). UI admin branchée sur `People::Membership*`, `People::Payment*` et `People::Subscription*` (vocabulaire cible : `People::Contribution*` — voir [glossary.md](glossary.md)). Il reste à reprendre l’interface publique.

**Phase UX (à faire)**

1. **Moderniser le formulaire**
   - Maintenir l’unicité back-end (People::Register) tout en allégeant le front.
   - Ajouter feedback progressif + validations client.
2. **Clarifier les messages**
   - Réutiliser les messages de `People::Register` tout en proposant des CTA explicites ("Mot de passe oublié", "Récupérer mon compte").
3. **Journeys visuels**
   - Ajouter un récapitulatif des étapes (nouvelle Person, compte créé, prochaine action).

---

## 🔴 Problème 2: Newsletter Legacy (mis à jour)

### Analyse

**Fichiers concernés:**
- `app/models/newsletter_subscriber.rb` (nouveau)
- `app/services/people/newsletter_signup.rb` (public)
- `app/services/newsletter_management/newsletter_updater.rb` (authentifié)
- `app/controllers/users_controller.rb` (newsletter_signup → People::NewsletterSignup)

### Problème identifié

**Conflit entre:**
- `Person.newsletter_subscribed` (legacy, booléen)
- `NewsletterSubscriber` (nouveau, table dédiée)

**Impact (résolu en partie):**
- Code public unifié via `People::NewsletterSignup`
- Instrumentation: `people.newsletter_signed_up`, `people.newsletter_signup.skipped`, `people.newsletter_signup.failed`
- Reste: workflow authentifié (paramètres newsletter) à finaliser via `NewsletterManagement::NewsletterUpdater`

### Plan d'Action

**Phase 1: Déprication Person.newsletter_subscribed (Jours 1-3)**

1. **Marquer colonne deprecated**
```ruby
# app/models/person.rb
class Person < ApplicationRecord
  # DEPRECATED: Use NewsletterSubscriber instead
  # This column will be removed in next migration
  # TODO: Remove references to newsletter_subscribed
end
```

2. **Supprimer assignation dans PersonCreator**
```ruby
# app/services/people/person_creator.rb
def person_attributes
  {
    # newsletter_subscribed: newsletter_subscribed,  # ← SUPPRIMER
    # ... other attributes
  }
end
```

3. **Refactor UsersController#toggle_newsletter_status**
```ruby
# app/controllers/users_controller.rb
def toggle_newsletter_status
  # Utiliser NewsletterManagement::NewsletterUpdater
  updater = NewsletterManagement::NewsletterUpdater.new(
    person_id: @person.id,
    email: @person.email,
    subscribed: !@person.newsletter_subscribed?,
    source: 'web',
    updated_by_id: Current.user.id
  )
  
  result = updater.call
  # ...
end
```

**Phase 2: Migration Données (Jours 4-5)**

1. **Script de migration**
   - Migrer Person.newsletter_subscribed → NewsletterSubscriber
   - Vérifier doublons
   - Supprimer colonne après migration

2. **Tests**
   - Tests de migration
   - Tests de non-régression

**Phase 3: Nettoyage (Jour 6)**

1. **Supprimer colonne newsletter_subscribed**
   - Migration
   - Supprimer références dans code
   - Tests

---

## 🔴 Problème 3: Gestion Compte Web

### Analyse

**Fichiers concernés:**
- `app/controllers/users_controller.rb`
- `app/views/users/edit.html.erb`
- `app/services/user_management/user_updater.rb`

### Problèmes identifiés

- ❌ Pas d'édition inline
- ❌ Formulaire lourd
- ❌ Pas de feedback en temps réel
- ❌ Erreurs pas claires

### Plan d'Action

**Phase 1: Édition Inline (Jours 7-10)**

1. **Stimulus Controller pour édition inline**
```javascript
// app/javascript/controllers/inline_edit_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["field", "form", "display"]
  
  edit() {
    this.displayTarget.classList.add("hidden")
    this.formTarget.classList.remove("hidden")
  }
  
  cancel() {
    this.displayTarget.classList.remove("hidden")
    this.formTarget.classList.add("hidden")
  }
  
  async save(event) {
    event.preventDefault()
    // Turbo Stream update
  }
}
```

2. **Vue avec édition inline**
```erb
<!-- app/views/users/_person_info.html.erb -->
<div data-controller="inline-edit">
  <div data-inline-edit-target="display">
    <p><%= person.full_name %></p>
    <button data-action="click->inline-edit#edit">Modifier</button>
  </div>
  
  <div data-inline-edit-target="form" class="hidden">
    <%= form_with model: person, url: user_path, method: :patch, 
                  data: { turbo_stream: true } do |f| %>
      <%= f.text_field :first_name %>
      <%= f.text_field :last_name %>
      <%= f.submit "Sauvegarder" %>
      <button data-action="click->inline-edit#cancel">Annuler</button>
    <% end %>
  </div>
</div>
```

3. **Controller avec Turbo Stream**
```ruby
# app/controllers/users_controller.rb
def update
  updater = UserManagement::UserUpdater.new(...)
  result = updater.call
  
  if result.success?
    respond_to do |format|
      format.html { redirect_to user_path }
      format.turbo_stream { 
        render turbo_stream: turbo_stream.replace("person_info", partial: "person_info")
      }
    end
  else
    # Gestion erreurs
  end
end
```

**Phase 2: Validation Temps Réel (Jours 11-12)**

1. **Stimulus Controller pour validation**
2. **Messages d'erreur clairs**
3. **Feedback visuel**

---

## 🔴 Problème 4: Workflow Validation/Erreurs

### Analyse

**Problèmes identifiés:**
- ❌ Messages d'erreur génériques
- ❌ Pas de feedback visuel
- ❌ Erreurs pas contextuelles

### Plan d'Action

**Phase 1: Messages d'Erreur Améliorés (Jours 13-14)**

1. **Messages spécifiques par erreur**
```ruby
# app/services/user_management/user_updater.rb
def validate_email
  unless email.match?(URI::MailTo::EMAIL_REGEXP)
    errors.add(:email, "Veuillez entrer une adresse email valide")
  end
  
  if User.exists?(email_address: email)
    errors.add(:email, "Cette adresse email est déjà utilisée. 
              <a href='/passwords/new'>Mot de passe oublié?</a>")
  end
end
```

2. **Feedback visuel**
- Bordure rouge pour champs invalides
- Icônes d'erreur
- Messages sous les champs

3. **Messages contextuels**
- Suggestions d'actions
- Liens vers solutions
- Exemples de valeurs valides

---

## 📋 Plan d'Action Global

### Phase 1: Newsletter Legacy (Jours 1-6)
- ✅ Déprication Person.newsletter_subscribed
- ✅ Migration données
- ✅ Nettoyage

### Phase 2: Édition Inline (Jours 7-12)
- ✅ Stimulus Controller
- ✅ Turbo Stream updates
- ✅ Validation temps réel

### Phase 3: Messages d'Erreur (Jours 13-14)
- ✅ Messages spécifiques
- ✅ Feedback visuel
- ✅ Suggestions

### Phase 4: Procédure Adhésion (Jours 15-18)
- ✅ Simplification formulaire
- ✅ Amélioration messages
- ✅ Service unifié

---

## 📚 Documentation liée

- **Architecture Services:** `docs/architecture/services.md` - Services utilisés
- **Logique Métier:** `docs/domain/business_logic.md` - Règles business
- **Guide tests:** `docs/development/testing.md` - Tests et qualité

