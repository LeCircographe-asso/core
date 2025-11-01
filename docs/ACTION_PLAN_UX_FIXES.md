# Plan d'Action - Corrections UX Critiques

**Date:** 2025-01-31  
**Démarrage:** Immédiat après validation  
**Durée estimée:** 3-4 semaines

---

## 🎯 Objectif

Corriger les 5 problèmes UX/UI critiques identifiés dans `UX_ISSUES_AUDIT.md` pour rendre l'application utilisable par les utilisateurs finaux et les administrateurs.

---

## 📅 Phase 1: Newsletter Legacy (Jours 1-3)

### Sprint 1.1: Déprication Person.newsletter_subscribed

**Fichiers à modifier:**
- `app/models/person.rb`
- `app/services/person_management/person_creator.rb`
- `app/controllers/users_controller.rb`

**Actions:**

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
# app/services/person_management/person_creator.rb
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
  return redirect_to root_path, alert: "Vous devez être connecté" unless @user

  # OLD: @user.person.update(newsletter_subscribed: !@user.person.newsletter_subscribed)
  
  # NEW: Use NewsletterSignupService
  result = NewsletterSignupService.new(@user.email_address, @user).call_newsletter
  message = result[:success] ? "Newsletter mise à jour" : result[:message]
  redirect_to @user, notice: message
end
```

**Tests à ajouter:**
```ruby
# spec/controllers/users_controller_spec.rb
describe "#toggle_newsletter_status" do
  it "uses NewsletterSubscriber instead of Person.newsletter_subscribed"
  it "creates NewsletterSubscriber if not exists"
  it "toggles existing NewsletterSubscriber status"
end
```

**Estimation:** 1 jour

---

### Sprint 1.2: Refactor NewsletterSignupService

**Fichiers à modifier:**
- `app/services/newsletter_signup_service.rb`

**Actions:**

1. **Améliorer source tracking**
```ruby
def initialize(email, current_user = nil, source: nil)
  @current_user = current_user
  @new_email = email.to_s.strip.downcase
  @person = Person.find_by(email: @new_email)
  @user = User.find_by(email_address: @new_email)
  @source = source || determine_source
end

private

def determine_source
  return 'admin' if @current_user&.admin? || @current_user&.super_admin?
  return 'authenticated' if @current_user.present?
  return 'web'
end
```

2. **Améliorer link vers Person**
```ruby
def create_new_subscriber
  subscriber = NewsletterSubscriber.new(
    email: @new_email,
    subscribed: true,
    source: @source
  )
  
  # Link vers Person si existe
  subscriber.person = @person if @person
  
  if subscriber.save
    # NO MORE MANUAL SYNC
    # Person.newsletter_subscribed handled by callback or delegation
    { success: true, message: "Inscription à la newsletter réussie !" }
  else
    { success: false, message: "Erreur: #{subscriber.errors.full_messages.join(', ')}" }
  end
end
```

**Tests à ajouter:**
```ruby
# spec/services/newsletter_signup_service_spec.rb
describe NewsletterSignupService do
  it "tracks source as 'web' for anonymous"
  it "tracks source as 'authenticated' for logged user"
  it "tracks source as 'admin' for admin users"
  it "auto-links to Person if email matches"
  it "handles duplicate gracefully"
end
```

**Estimation:** 1 jour

---

### Sprint 1.3: Sync automatique (si nécessaire)

**Option A: Via Model Callback**

```ruby
# app/models/newsletter_subscriber.rb
class NewsletterSubscriber < ApplicationRecord
  after_save :sync_to_person
  
  private
  
  def sync_to_person
    return unless person
    # Avoid infinite loop with Person#newsletter_subscribed=
    person.update_column(:newsletter_subscribed, subscribed) if person
  end
end
```

**Option B: Delegation Pattern**

```ruby
# app/models/person.rb
def newsletter_subscribed
  return newsletter_subscriber&.subscribed if newsletter_subscriber
  # Legacy fallback
  read_attribute(:newsletter_subscribed)
end

def newsletter_subscribed=(value)
  # Deprecated: use NewsletterSubscriber
  Rails.logger.warn "[DEPRECATED] Person#newsletter_subscribed= called. Use NewsletterSubscriber instead."
  write_attribute(:newsletter_subscribed, value)
end
```

**Recommandation:** **Option B** - Plus flexible pour migration

**Estimation:** 0.5 jour

---

### Sprint 1.4: Tests et documentation

**Tests à créer:**
- `spec/services/newsletter_signup_service_spec.rb` (complet)
- `spec/models/newsletter_subscriber_spec.rb` (compléter)
- `spec/integration/newsletter_workflow_spec.rb` (nouveau)

**Documentation:**
- Update `docs/BUSINESS_LOGIC.md` avec workflow newsletter
- Ajouter FAQ "Comment s'abonner à la newsletter"

**Estimation:** 0.5 jour

**Total Phase 1:** 3 jours

---

## 📅 Phase 2: Simplification Registration (Jours 4-7)

### Sprint 2.1: Analyse et conception

**Objectif:** Définir nouveau workflow registration

**Livrables:**
- User journey map registration
- Wireframes 2-step process
- Specs technique

**Choix:** **Option A (2-step)**
```
Step 1: Email + Password + CGU/Privacy
Step 2: Profil complet (optionnel, peut être complété plus tard)
```

**Estimation:** 0.5 jour

---

### Sprint 2.2: Refactor Web::UserRegistration

**Fichiers à modifier:**
- `app/services/web/user_registration.rb`
- `app/controllers/registrations_controller.rb`

**Nouveau flow simplifié:**

```ruby
# app/services/web/user_registration.rb
def call
  return failure("Invalid data: #{errors.full_messages.join(', ')}") unless valid?

  ActiveRecord::Base.transaction do
    # 1. Check if email already used
    if User.exists?(email_address: user_email)
      return failure("Cette adresse email est déjà utilisée. Utilisez 'Mot de passe oublié'.")
    end
    
    if Person.exists?(email: user_email) && Person.find_by(email: user_email).user.present?
      return failure("Cette adresse email est déjà utilisée. Utilisez 'Mot de passe oublié'.")
    end
    
    # 2. Create Person if not exists
    person = find_or_create_person
    
    # 3. Create User
    user = create_user_account(person)
    return failure("Erreur création compte: #{user.errors.full_messages.join(', ')}") unless user.persisted?
    
    success(person, user)
  end
end

private

def find_or_create_person
  Person.find_by(email: user_email) || Person.create!(
    first_name: first_name.presence || "Utilisateur",
    last_name: last_name.presence || "Anonyme",
    email: user_email
  )
end
```

**Estimation:** 1.5 jours

---

### Sprint 2.3: Refactor RegistrationsController

**Actions:**

1. **Simplifier create action**
```ruby
def create
  result = Web::UserRegistration.new(
    first_name: user_params[:first_name],
    last_name: user_params[:last_name],
    email: user_params[:email_address],
    user_email: user_params[:email_address],
    user_password: user_params[:password],
    cgu: user_params[:cgu],
    privacy_policy: user_params[:privacy_policy]
  ).call

  if result.success?
    UserMailer.welcome_email(result.user).deliver_later
    start_new_session_for result.user
    redirect_to root_path, notice: "Inscription réussie ! Bienvenue !"
  else
    @user = User.new(email_address: user_params[:email_address])
    flash.now[:alert] = result.message
    render :new, status: :unprocessable_entity
  end
end
```

2. **Améliorer messages d'erreur**
- Créer `app/helpers/registrations_helper.rb` pour messages clairs
- Inline validations dans form

**Estimation:** 1 jour

---

### Sprint 2.4: Tests et UX testing

**Tests à créer:**
```ruby
# spec/requests/registrations_spec.rb
describe "POST /registrations" do
  it "creates User and Person in one transaction"
  it "handles duplicate email gracefully"
  it "sends welcome email"
  it "starts session for new user"
  
  context "invalid data" do
    it "shows clear error for missing password"
    it "shows clear error for missing CGU"
    it "shows clear error for duplicate email"
  end
end
```

**UX Testing:**
- Tester workflow 2-step avec utilisateur réel
- Mesurer taux de succès

**Estimation:** 1 jour

**Total Phase 2:** 4 jours

---

## 📅 Phase 3: Inline Editing (Jours 8-10)

### Sprint 3.1: Setup Turbo Frames

**Fichier:** `app/views/admin/users/show.html.erb`

**Structure:**

```erb
<%= turbo_frame_tag "person_#{@person.id}_info", class: "space-y-4" do %>
  <div class="flex justify-between items-center">
    <h2 class="text-xl font-bold">Informations personnelles</h2>
    <%= link_to "Modifier",
        edit_inline_admin_user_path(id: "person_#{@person.id}"),
        data: { turbo_frame: "person_#{@person.id}_info" },
        class: "btn-secondary" %>
  </div>
  
  <dl class="grid grid-cols-2 gap-4">
    <dt>Prénom:</dt>
    <dd><%= @person.first_name %></dd>
    
    <dt>Nom:</dt>
    <dd><%= @person.last_name %></dd>
    
    <!-- ... -->
  </dl>
<% end %>
```

**Estimation:** 1 jour

---

### Sprint 3.2: Edit form Turbo Frame

**Nouveau partial:** `app/views/admin/users/_edit_info.html.erb`

```erb
<%= turbo_frame_tag "person_#{person.id}_info" do %>
  <%= form_with model: person, 
      url: admin_user_path("person_#{person.id}"),
      method: :patch,
      data: { turbo_frame: "person_#{person.id}_info" } do |form| %>
    
    <div class="grid grid-cols-2 gap-4">
      <%= form.label :first_name, "Prénom" %>
      <%= form.text_field :first_name, class: "form-input" %>
      
      <%= form.label :last_name, "Nom" %>
      <%= form.text_field :last_name, class: "form-input" %>
      
      <!-- ... -->
    </div>
    
    <div class="flex justify-end space-x-2 mt-4">
      <%= button_tag "Annuler", 
          type: "button",
          data: { 
            turbo_action: "advance",
            turbo_frame: "person_#{person.id}_info"
          },
          class: "btn-secondary" %>
      <%= form.submit "Enregistrer", class: "btn-primary" %>
    </div>
  <% end %>
<% end %>
```

**Estimation:** 1 jour

---

### Sprint 3.3: Controller actions

**Ajouter à:** `app/controllers/admin/users_controller.rb`

```ruby
def edit_inline
  render partial: "edit_info", locals: { person: @person }
end

def update
  if @person.update(person_params)
    flash[:notice] = "Informations mises à jour"
    render partial: "info", locals: { person: @person }
  else
    flash.now[:alert] = "Erreur: #{@person.errors.full_messages.join(', ')}"
    render partial: "edit_info", locals: { person: @person }, status: :unprocessable_entity
  end
end
```

**Estimation:** 1 jour

**Total Phase 3:** 3 jours

---

## 📅 Phase 4: Email Sync & Account Claiming (Jours 11-12)

### Sprint 4.1: Auto-sync email

**Ajouter à:** `app/models/user.rb`

```ruby
after_save :sync_email_to_person, if: :saved_change_to_email_address?

private

def sync_email_to_person
  person&.update(email: email_address)
end
```

**Tests:**
```ruby
# spec/models/user_spec.rb
describe "email sync" do
  it "syncs email_address to person.email on save"
  it "does not sync if person is nil"
  it "does not sync if email not changed"
end
```

**Estimation:** 0.5 jour

---

### Sprint 4.2: Account claiming workflow

**Fichier:** `app/controllers/account_claims_controller.rb`

**Vérifier:** Le workflow existe-t-il déjà?

**Actions si existe:**
- Tests complets
- Améliorer UX

**Actions si n'existe pas:**
- Créer workflow de base
- Documentation

**Estimation:** 1.5 jours

**Total Phase 4:** 2 jours

---

## 📅 Phase 5: Tests & Documentation (Jours 13-14)

### Sprint 5.1: Tests d'intégration

**À créer:**
- `spec/integration/newsletter_workflow_spec.rb`
- `spec/integration/registration_workflow_spec.rb`
- `spec/requests/inline_editing_spec.rb`

**Couverture visée:** 60% sur workflows UX

**Estimation:** 1 jour

---

### Sprint 5.2: Documentation utilisateur

**À créer:**
- `docs/USER_GUIDE_REGISTRATION.md`
- `docs/ADMIN_GUIDE_NEWSLETTER.md`
- `docs/FAQ_COMMON_ISSUES.md`

**Mise à jour:**
- `README.md` avec liens docs
- `docs/BUSINESS_LOGIC.md` avec workflows finaux

**Estimation:** 1 jour

**Total Phase 5:** 2 jours

---

## 📊 Récapitulatif

| Phase | Durée | Priorité | Dépendances |
|-------|-------|----------|-------------|
| Phase 1: Newsletter | 3 jours | 🔴 Haute | Aucune |
| Phase 2: Registration | 4 jours | 🔴 Haute | Phase 1 |
| Phase 3: Inline Editing | 3 jours | 🟡 Moyenne | Phase 2 |
| Phase 4: Email Sync | 2 jours | 🟡 Moyenne | Phase 2 |
| Phase 5: Tests & Docs | 2 jours | 🟢 Basse | Toutes phases |

**Total:** 14 jours (2.5-3 semaines)

---

## 🎯 Critères de Succès

**Avant:**
- ❌ Registration fail rate > 20%
- ❌ Newsletter duplicates fréquents
- ❌ UX admin frustrante
- ❌ Tests coverage 0% sur workflows UX

**Après:**
- ✅ Registration fail rate < 5%
- ✅ Zero newsletter duplicates
- ✅ Inline editing fonctionnel
- ✅ Tests coverage 60%+ workflows UX
- ✅ Temps édition fiche -50%
- ✅ User satisfaction > 8/10

---

## 🚀 Démarrage

**Prochaine action immédiate:**

1. Lire `docs/UX_ISSUES_AUDIT.md`
2. Valider approche avec user
3. Commencer Phase 1 - Sprint 1.1
4. Update todos avec tâches détaillées

