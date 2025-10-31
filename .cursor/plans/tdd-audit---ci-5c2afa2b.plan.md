<!-- 5c2afa2b-20c7-4b51-ab10-13201ef223c2 a0b02774-7e58-4502-9a3e-5ebcad2e4ba2 -->
# Plan: Nettoyage Legacy et Simplification du Modèle

## Contexte

L'application souffre de code legacy (user_id, order_id) et de complexité inutile qui rendent les tests difficiles et l'architecture confuse. Ce plan vise à nettoyer le modèle de données tout en respectant la logique métier existante.

## Phase 1: Suppression Legacy Payments (Priorité 1)

### 1.1 Supprimer colonnes et relations inutilisées

**Fichier: `app/models/payment.rb`**

- Supprimer `belongs_to :user, optional: true` (ligne 12)
- Supprimer `belongs_to :order, optional: true` (ligne 13)
- Supprimer `has_many :product_orders, through: :order` (ligne 14)
- Mettre à jour commentaire ligne 11

**Fichier: `app/models/user.rb`**

- Conserver `has_many :payments, through: :person` (ligne 31) - utile pour queries

**Fichier: `app/queries/payment_query.rb`**

- Méthode `by_user` (lignes 6-9) déjà correcte - utilise person_id via User.person

**Fichier: `app/services/admin/payments_service.rb`**

- Ligne 34-36: Déjà correct - utilise PaymentQuery.by_user qui passe par Person

### 1.2 Migration: Supprimer colonnes legacy

**Nouveau fichier: `db/migrate/YYYYMMDDHHMMSS_remove_legacy_payment_columns.rb`**

```ruby
class RemoveLegacyPaymentColumns < ActiveRecord::Migration[8.0]
  def change
    # Note: Ces colonnes n'existent PAS dans le schema actuel
    # Elles sont seulement dans le modèle Payment comme relations optional
    # On nettoie juste le code Ruby, pas de migration DB nécessaire
    
    # Si jamais ces colonnes existaient en production:
    # remove_column :payments, :user_id, :bigint if column_exists?(:payments, :user_id)
    # remove_column :payments, :order_id, :bigint if column_exists?(:payments, :order_id)
  end
end
```

**Action:** Vérifier le schema - si colonnes absentes, migration vide suffit.

## Phase 2: Simplification MembershipType (Hybride)

### 2.1 État actuel

`MembershipType` a déjà un enum `category` (lignes 20-24):

```ruby
enum :category, { basic: 0, circus_full: 1, circus_reduced: 2 }
```

**Problème:** `circus_full` et `circus_reduced` sont traités comme catégories séparées, alors que c'est la même catégorie "circus" avec tarifs différents.

### 2.2 Simplifier enum category

**Fichier: `app/models/membership_type.rb`**

**Avant (lignes 20-24):**

```ruby
enum :category, {
  basic: 0,
  circus_full: 1,
  circus_reduced: 2
}
```

**Après:**

```ruby
enum :category, {
  basic: 0,
  circus: 1,
  event: 2
}
```

**Mise à jour méthode `circus?` (lignes 27-29):**

```ruby
def circus?
  category == "circus"
end
```

**Supprimer méthodes obsolètes:**

- `circus_full?` (auto-généré par enum, ne sera plus disponible)
- `circus_reduced?` (auto-généré par enum, ne sera plus disponible)

**Mise à jour scope (ligne 70):**

```ruby
scope :circus_types, -> { where(category: :circus) }
```

### 2.3 Migration: Consolidation enum category

**Pas de migration nécessaire** - Aucune donnée en production, on modifie directement l'enum et les seeds.

### 2.4 Mise à jour seeds et méthodes

**Fichier: `app/models/membership_type.rb` (méthode `create_default_types!`, lignes 79-100)**

**Avant:**

```ruby
find_or_create_by(name: "Adhésion Cirque Complète", version: 1) do |mt|
  mt.category = :circus_full
  ...
end

find_or_create_by(name: "Adhésion Cirque Réduite", version: 1) do |mt|
  mt.category = :circus_reduced
  ...
end
```

**Après:**

```ruby
find_or_create_by(name: "Adhésion Cirque Complète", version: 1) do |mt|
  mt.category = :circus
  mt.price_cents = 2500
  mt.description = "Adhésion complète avec accès aux cours de cirque"
  mt.effective_from = Date.current
end

find_or_create_by(name: "Adhésion Cirque Réduite", version: 1) do |mt|
  mt.category = :circus
  mt.price_cents = 2000
  mt.description = "Adhésion cirque à tarif réduit (étudiants, chômeurs, etc.)"
  mt.effective_from = Date.current
end
```

**Impact:** Les deux restent des enregistrements distincts (tarifs différents), mais partagent `category: :circus`.

## Phase 3: Table Newsletter Dédiée

### 3.1 Objectif

Créer une table pour tracker les emails newsletter indépendamment de Person, permettant:

- Inscription newsletter avant création compte
- Merge automatique vers Person lors de création compte
- Audit trail complet

### 3.2 Nouvelle table newsletter_subscribers

**Nouveau fichier: `db/migrate/YYYYMMDDHHMMSS_create_newsletter_subscribers.rb`**

```ruby
class CreateNewsletterSubscribers < ActiveRecord::Migration[8.0]
  def change
    create_table :newsletter_subscribers do |t|
      t.string :email, null: false
      t.boolean :subscribed, default: true, null: false
      t.string :unsubscribe_token
      t.datetime :subscribed_at
      t.datetime :unsubscribed_at
      t.bigint :person_id # Nullable - link si Person existe
      t.string :source # 'web', 'admin', 'import'
      t.text :notes
      
      t.timestamps
      
      t.index :email, unique: true
      t.index :person_id
      t.index [:subscribed, :email]
      t.index :unsubscribe_token, unique: true
    end
    
    add_foreign_key :newsletter_subscribers, :people, column: :person_id, on_delete: :nullify
  end
end
```

### 3.3 Nouveau modèle NewsletterSubscriber

**Nouveau fichier: `app/models/newsletter_subscriber.rb`**

```ruby
class NewsletterSubscriber < ApplicationRecord
  belongs_to :person, optional: true
  
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :unsubscribe_token, uniqueness: true, allow_nil: true
  
  before_validation :normalize_email
  before_create :generate_unsubscribe_token
  before_create :set_subscribed_at
  
  scope :subscribed, -> { where(subscribed: true) }
  scope :unsubscribed, -> { where(subscribed: false) }
  scope :orphaned, -> { where(person_id: nil) }
  scope :linked, -> { where.not(person_id: nil) }
  
  def unsubscribe!
    update!(subscribed: false, unsubscribed_at: Time.current)
  end
  
  def resubscribe!
    update!(subscribed: true, subscribed_at: Time.current, unsubscribed_at: nil)
  end
  
  # Merge vers Person existante
  def link_to_person!(person)
    transaction do
      update!(person_id: person.id)
      person.update!(newsletter_subscribed: true) if subscribed?
    end
  end
  
  private
  
  def normalize_email
    self.email = email&.strip&.downcase
  end
  
  def generate_unsubscribe_token
    self.unsubscribe_token ||= SecureRandom.urlsafe_base64(32)
  end
  
  def set_subscribed_at
    self.subscribed_at ||= Time.current if subscribed?
  end
end
```

### 3.4 Migrer données existantes

**Pas de migration de données nécessaire** - Aucune donnée en production, la table sera créée vide.

### 3.5 Refactorer NewsletterSignupService

**Fichier: `app/services/newsletter_signup_service.rb`**

**Nouvelle logique:**

1. Chercher `NewsletterSubscriber` par email
2. Si existe et subscribed: message "déjà inscrit"
3. Si existe et unsubscribed: resubscribe
4. Si n'existe pas: créer nouveau `NewsletterSubscriber`
5. Si Person ou User avec cet email existe: link automatiquement

**Méthode `call_newsletter` refactorisée:**

```ruby
def call_newsletter
  subscriber = NewsletterSubscriber.find_by(email: @new_email)
  
  if subscriber
    handle_existing_subscriber(subscriber)
  else
    create_new_subscriber
  end
end

private

def handle_existing_subscriber(subscriber)
  if subscriber.subscribed?
    { success: false, message: "Cette adresse email est déjà inscrite à la newsletter." }
  else
    subscriber.resubscribe!
    { success: true, message: "Vous êtes de nouveau inscrit à la newsletter." }
  end
end

def create_new_subscriber
  subscriber = NewsletterSubscriber.new(
    email: @new_email,
    subscribed: true,
    source: @current_user ? 'authenticated' : 'web'
  )
  
  # Link vers Person si existe
  person = Person.find_by(email: @new_email)
  subscriber.person = person if person
  
  if subscriber.save
    # Sync Person.newsletter_subscribed si lié
    person&.update(newsletter_subscribed: true)
    { success: true, message: "Inscription à la newsletter réussie !" }
  else
    { success: false, message: "Une erreur s'est produite. Veuillez réessayer." }
  end
end
```

## Phase 4: Nettoyage Listes de Présence

### 4.1 État actuel

- `Attendance`: Présence d'une Person à un Event ou date libre
- `AttendanceList`: Liste d'émargement pour entraînement libre
- Logique: Adhésion + Cotisation valide requis

**Validation:** Structure actuelle OK, PaymentLine polymorphique peut référencer Attendance si besoin.

**Action:** Aucune modification nécessaire - logique métier respectée.

## Phase 5: Tests et Validation

### 5.1 Mise à jour tests models

**Fichiers à mettre à jour:**

- `spec/models/payment_spec.rb`: Retirer tests `belongs_to :user` et `:order`
- `spec/models/membership_type_spec.rb`: Mettre à jour tests enum (circus_full/circus_reduced → circus)
- **Nouveau:** `spec/models/newsletter_subscriber_spec.rb`

### 5.2 Mise à jour factories

**Fichier: `spec/factories/membership_types.rb`**

- Trait `circus_full` → `circus` (category)
- Trait `circus_reduced` → `circus` (category, price différent)

**Nouveau fichier: `spec/factories/newsletter_subscribers.rb`**

```ruby
FactoryBot.define do
  factory :newsletter_subscriber do
    sequence(:email) { |n| "subscriber#{n}@example.com" }
    subscribed { true }
    source { 'web' }
    
    trait :subscribed do
      subscribed { true }
      subscribed_at { Time.current }
    end
    
    trait :unsubscribed do
      subscribed { false }
      unsubscribed_at { Time.current }
    end
    
    trait :with_person do
      association :person
    end
    
    trait :orphaned do
      person { nil }
    end
  end
end
```

### 5.3 Mise à jour service specs

**Fichier: `spec/services/newsletter_signup_service_spec.rb`**

- Refactorer pour tester nouvelle logique avec `NewsletterSubscriber`

## Phase 6: Documentation

### 6.1 Mise à jour docs

**Fichier: `docs/MODEL_EVALUATION.md`**

- Mettre à jour score: 7/10 → 9/10
- Marquer Priorité 1 comme complète

**Fichier: `docs/BUSINESS_LOGIC.md`**

- Section Membership: Clarifier que circus_full/circus_reduced sont des tarifs, pas catégories
- Section Newsletter: Documenter nouvelle table `newsletter_subscribers`

**Nouveau fichier: `docs/REFACTORING_LEGACY_CLEANUP.md`**

- Changelog détaillé des modifications
- Raisons du choix hybride MembershipType
- Guide migration newsletter

## Ordre d'exécution

1. Phase 1 (Legacy Payments) - Impact minimal, tests faciles
2. Phase 2 (MembershipType) - Breaking change enum, migration DB
3. Phase 3 (Newsletter) - Nouvelle feature, migration de données
4. Phase 4 (Validation Attendance) - Aucune modif
5. Phase 5 (Tests) - Après toutes les modifications
6. Phase 6 (Documentation) - Finalisation

## Risques et Mitigations

### Risque 1: Breaking change enum MembershipType

**Mitigation:** Migration teste en dev, puis staging. Rollback possible via seeds.

### Risque 2: Perte données newsletter lors migration

**Mitigation:** Migration réversible (down method), backup DB avant.

### Risque 3: Code dépendant de circus_full/circus_reduced

**Mitigation:** Grep complet du codebase avant modifications.

## Validation finale

Après toutes modifications:

1. Lancer suite tests complète: `bin/test`
2. Vérifier coverage maintenu (>10%)
3. Tester manuellement workflow newsletter
4. Tester création adhésion Circus (tous tarifs)
5. Vérifier dashboards admin (queries via MembershipType.circus)

### To-dos

- [ ] Écrire tests validations basiques (presence, numericality, uniqueness scoped)
- [ ] Écrire tests associations (belongs_to membership_type, has_many book_of_entries)
- [ ] Écrire tests enum duration (day, trimester, annual, pack10)
- [ ] Écrire tests scopes (for_circus_members, duration scopes, versioning scopes)
- [ ] Tests CRITIQUES: Validations conditionnelles pack10 (sessions_count, validity_days)
- [ ] Tests CRITIQUES: create_price_change! edge cases (même jour, dates passées, cohérence)
- [ ] Tests EDGE CASE: duration_days retourne nil pour pack10 (protection calculs)
- [ ] Tests EDGE CASE: price_change_percentage avec old_price = 0 (division protection)
- [ ] Tests Priceable concern (price_euros, formatted_price, name_with_price)
- [ ] Tests Versionable concern (current_version?, expired_version?, future_version?)
- [ ] Exécuter bin/test et vérifier 100% coverage SubscriptionPlan