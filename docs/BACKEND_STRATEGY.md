# Stratégie Backend - Logique Métier Immuable

## Tu Veux

1. ✅ Comprendre ta logique métier
2. ✅ La poser (documenter/finaliser)
3. ✅ La rendre immuable (protégée par tests)

---

## Problème Actuel

```
Logique métier encore en mouvement
  ↓
Pas clair ce qui doit être testé
  ↓
Risque de tests sur code instable
```

---

## Solution: 3 Zones

### Zone 1: Logique Définie (Maintenant)
**Ce qui est:**
- ✅ Fonctionnel et stable
- ✅ Comportement validé
- ✅ Ne changera plus fondamentalement

**Action:**
```ruby
# Test de protection immédiate
RSpec.describe Membership do
  it 'calculates expiry correctly' do
    # Comportement défini = test immédiat
  end
end
```

### Zone 2: Logique En Cours (Prototype)
**Ce qui est:**
- ⚠️ Fonctionnel mais pourrait changer
- ⚠️ Logique en exploration
- ⚠️ Besoin de valider l'approche

**Action:**
```ruby
# NO tests maintenant
# Juste un commentaire
class SubscriptionPlan
  # TODO: Logique d'expiration à finaliser
  # Comportement actuel: [description]
  # Comportement attendu: [description]
  def expired?
    # Version temporaire
  end
end
```

### Zone 3: Logique Future (À Définir)
**Ce qui est:**
- ❓ Non implémenté
- ❓ Spécification floue
- ❓ Besoin de clarification

**Action:**
```ruby
# Documentation seulement
# Pas de code, pas de tests
```

---

## Workflow Recommandé

### Étape 1: Documentation de la Logique Métier

**Crée:** `docs/BUSINESS_LOGIC.md` (ou similaire)

Pour chaque domaine:
```
# Membership
## Comportement défini
- Durée: 1 an depuis date de souscription
- Activation: Après paiement réussi
- Expiration: Fin automatique après 1 an

## Comportement en cours de validation
- Renouvellement automatique (à décider)
- Prorata (à discuter)

## Comportement futur
- Loyalty programs (non prioritaire)
```

### Étape 2: Classification du Code

**Pour chaque fichier/feature:**

1. Lire le code existant
2. Identifier dans quelle zone (Définie/En cours/Future)
3. Marquer clairement

**Exemple:**
```ruby
class Payment
  # ZONE 1: Comportement défini et stable
  # Note: Cette logique est immuable
  
  def process
    # Comportement établi
    # TODO: Tests à ajouter
  end
  
  # ZONE 2: En exploration
  # Note: Cette partie pourrait changer
  
  def refund_policy
    # Version temporaire
    # TODO: Valider avec stakeholders
  end
  
  # ZONE 3: Future
  # Note: Pas implémenté, logique à définir
  
  # def installment_payments
  #   # Spécification à clarifier
  # end
end
```

### Étape 3: Protection Progressive

**Zone 1 → Tests immédiats:**
```bash
# Logique définie = tests de protection
bin/test spec/models/membership_spec.rb
bin/test spec/services/payments/process_spec.rb
```

**Zone 2 → Tests après stabilisation:**
```bash
# Quand logique Zone 2 se stabilise
# → Elle devient Zone 1
# → Ajouter tests
```

**Zone 3 → Pas de tests:**
```bash
# Pas encore de code
# Pas besoin de tests
```

---

## Exemple Concret: Membership

### Situation Actuelle

```ruby
# app/models/membership.rb
class Membership < ApplicationRecord
  # ZONE 1: Défini et immuable
  validates :started_at, presence: true
  validates :ended_at, presence: true
  
  def active?
    Date.current.between?(started_at, ended_at)
  end
  
  # ZONE 2: En cours d'exploration
  def can_renew?
    # Logique temporaire
    # TODO: Valider comportement avec business
  end
  
  # ZONE 3: Future
  # def calculate_pro_rated_amount
  #   # Spécification à clarifier
  # end
end
```

### Tests Correspondants

```ruby
# spec/models/membership_spec.rb
RSpec.describe Membership, type: :model do
  # ZONE 1: Tests de protection
  describe 'validations' do
    it { should validate_presence_of(:started_at) }
    it { should validate_presence_of(:ended_at) }
  end
  
  describe '#active?' do
    context 'when current date is between started_at and ended_at' do
      it 'returns true' do
        # Comportement défini = test immédiat
      end
    end
  end
  
  # ZONE 2: Pas de tests pour l'instant
  # describe '#can_renew?' do
  #   # Quand logique stabilisée, décommenter et tester
  # end
  
  # ZONE 3: Pas de tests (pas de code)
end
```

---

## Plan d'Action Immédiat

### Semaine 1: Documentation & Audit

**Objectif:** Comprendre et classifier

```
Jour 1-2: Documentation logique métier
  → Créer docs/BUSINESS_LOGIC.md
  → Lister tous les domaines
  → Documenter comportement de chaque feature

Jour 3-4: Classification du code
  → Parcourir app/models
  → Parcourir app/services
  → Marquer Zone 1/2/3

Jour 5: Audit des tests existants
  → Vérifier si couvrent Zone 1
  → Identifier gaps critiques
```

### Semaine 2-3: Protection Zone 1

**Objectif:** Tests pour logique définie

```
Priorité 1: Models Zone 1
  → SubscriptionPlan (si défini)
  → Payment, Membership, User
  → Tests de validations, associations, méthodes critiques

Priorité 2: Services Zone 1
  → Payments::Process
  → Memberships::Upgrade
  → Tests de comportement

Priorité 3: Controllers Zone 1
  → Endpoints critiques utilisés
  → Tests de régression
```

### Semaine 4+: TDD Nouvelles Features

**Objectif:** TDD pour features stabilisées Zone 1

```
Nouvelle feature claire → TDD pur
  → Spécification définie
  → Comportement clair
  → Tests d'abord puis implémentation
```

---

## Stratégie par Domaine

### Domaines Probablement Définis (Zone 1)

**Membership & Payment:**
- Logique: Durée, statuts, activation
- Tests: Urgents (business critique)
- Coverage: 80%+

**User Authentication:**
- Logique: Login, signup, sessions
- Tests: Importants (sécurité)
- Coverage: 70%+

**Basic CRUD:**
- Logique: Événements, Blogs
- Tests: Régressions
- Coverage: 60%+

### Domaines En Exploration (Zone 2)

**Feature X (à identifier):**
- Logique: Version temporaire
- Tests: Attendre stabilisation
- Coverage: Documentation uniquement

### Domaines Futures (Zone 3)

**Feature Y (à identifier):**
- Logique: Non implémentée
- Tests: N/A
- Coverage: Spécification seulement

---

## Garde-Fou

### Ne Pas Tester Maintenant

❌ Logique qui bouge encore
❌ Code "en fait ça marche mais..."
❌ Comportements non validés
❌ Features expérimentales

### Tester Immédiatement

✅ Logique métier définie et validée
✅ Comportement immuable
✅ Code critique (payments, membership)
✅ Bugs connus (tests de régression)

---

## Process de Stabilisation

### Quand Zone 2 → Zone 1

```
1. Logique stabilisée avec stakeholders
2. Code nettoyé et finalisé
3. Documentation dans BUSINESS_LOGIC.md
4. Marquage Zone 1 dans code
5. Ajout tests de protection
```

### Quand Zone 3 → Zone 2

```
1. Spécification clarifiée
2. Prototype commencé
3. Marquage Zone 2
4. Exploration sans tests
```

---

## Fichiers à Créer

### docs/BUSINESS_LOGIC.md
```
# Logique Métier Immutables

## Membership
### Défini (Zone 1)
- [X] Durée standard: 1 an
- [X] Activation après paiement

### En cours (Zone 2)
- [ ] Renouvellement automatique

### Future (Zone 3)
- [ ] Pro-rata

## Payment
### Défini (Zone 1)
- [X] Stripe integration
- [X] Status workflow

### En cours (Zone 2)
- [ ] Refund policy

...
```

### TODO dans Code

```ruby
# app/models/membership.rb
# == BUSINESS LOGIC STATUS ==
# Zone 1 (Stable): validations, active?, expires_at
# Zone 2 (En cours): can_renew? (à valider)
# Zone 3 (Future): pro_rated_amount (spéc à définir)
# ==========================
```

---

## Résumé

**Ce que tu veux:**
1. Comprendre logique → Documentation
2. Poser logique → Classification Zone 1/2/3
3. Immuabilité → Tests Zone 1 seulement

**Action immédiate:**
1. Créer `docs/BUSINESS_LOGIC.md`
2. Classifier ton code existant
3. Tester uniquement Zone 1
4. Laisser Zone 2/3 sans tests pour l'instant

**Résultat:**
- Protection là où c'est critique
- Pas de tests inutiles
- Logique documentée
- CI/CD comme filet de sécurité

---

## Prochaine Étape

**Veux-tu que je:**
1. Crée un template `BUSINESS_LOGIC.md` pour ton app?
2. Fasse un audit de tes models/services pour classifier Zone 1/2/3?
3. Génère un plan de tests pour Zone 1 uniquement?

**Commence par ce qui te bloque le plus.** 🎯

