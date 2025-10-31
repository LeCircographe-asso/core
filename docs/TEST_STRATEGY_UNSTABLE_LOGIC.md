# Stratégie de Tests avec Logique Métier En Évolution

**Problème:** Comment tester quand la logique métier bouge encore?  
**Solution:** Se concentrer sur les **invariants métier** plutôt que l'implémentation.

---

## Principe Fondamental

### ❌ Ne PAS tester l'implémentation
```ruby
# Mauvais: Teste l'implémentation interne
it "updates status to active using update!" do
  membership.update!(status: :active)
  expect(membership.status).to eq("active")
end
```

### ✅ Tester le comportement métier
```ruby
# Bon: Teste le comportement attendu
it "activates a pending membership when payment succeeds" do
  membership = create(:membership, status: :pending)
  payment = create(:payment, membership: membership, status: :success)
  
  Payments::Process.new(payment).call
  
  expect(membership.reload.status).to eq("active")
end
```

---

## Les 3 Types de Tests à Écrire

### 1. Tests d'Invariants Métier (IMMUABLES)

**Ce sont les règles métier CORE qui ne changeront JAMAIS.**

#### Exemples d'Invariants Métier

```ruby
# Règle: Un membre ne peut pas avoir 2 adhésions actives en même temps
spec/models/membership_spec.rb
it "prevents overlapping active memberships" do
  person = create(:person)
  create(:membership, person: person, status: :active, 
         started_at: Date.current, ended_at: 1.year.from_now)
  
  overlapping = build(:membership, person: person, status: :active,
                      started_at: 6.months.from_now, ended_at: 18.months.from_now)
  
  expect(overlapping).not_to be_valid
end

# Règle: Pack10 ne peut être utilisé QUE si membre Circus actif
spec/models/book_of_entry_spec.rb
it "cannot be used without active Circus membership" do
  book = create(:book_of_entry, :pack10)
  person = book.person
  
  # Person n'a pas d'adhésion Circus
  person.memberships.destroy_all
  
  expect(book.can_use?).to be false
end

# Règle: Prix NE PEUT PAS être négatif ou zéro
spec/models/subscription_plan_spec.rb
it "requires price_cents to be greater than 0" do
  plan = build(:subscription_plan, price_cents: 0)
  expect(plan).not_to be_valid
end
```

**Ces tests sont SACRÉS** - Si tu changes la logique métier ET que ces tests échouent, STOP! Tu as cassé une règle immuable.

---

### 2. Tests de Contrat (Stable Interface)

**Ce sont les APIs exposées qui doivent rester stables.**

#### Service Objects

```ruby
# Contrat: Payments::Process doit TOUJOURS retourner un résultat avec success?/failure?
spec/services/payments/process_spec.rb
describe "Contract: Response format" do
  it "always returns a result object" do
    payment = create(:payment)
    result = Payments::Process.new(payment).call
    
    expect(result).to respond_to(:success?)
    expect(result).to respond_to(:failure?)
    expect(result).to respond_to(:errors)
  end
  
  it "returns success when payment processed" do
    payment = create(:payment, status: :pending)
    result = Payments::Process.new(payment).call
    
    expect(result.success?).to be true
  end
end
```

#### Model Methods publiques

```ruby
# Contrat: can_upgrade_to? doit TOUJOURS retourner boolean
spec/models/membership_spec.rb
describe "Contract: can_upgrade_to?" do
  it "always returns boolean" do
    membership = create(:membership, :basic)
    circus_type = create(:membership_type, :circus_full)
    
    result = membership.can_upgrade_to?(circus_type)
    
    expect(result).to be(true).or be(false)
  end
end
```

---

### 3. Tests de Caractérisation (Documentation du Comportement Actuel)

**Ces tests documentent comment ça marche ACTUELLEMENT.**

```ruby
# Comportement ACTUEL: Pack10 n'expire jamais
spec/models/book_of_entry_spec.rb
it "Pack10 never expires" do
  pack10 = create(:book_of_entry, :pack10, purchased_at: 10.years.ago)
  
  expect(pack10.expired?).to be false
end

# Si dans 6 mois tu changes cette règle métier:
# 1. Le test va échouer
# 2. Tu DECIDES: Est-ce une régression ou une nouvelle feature?
# 3. Si nouvelle feature → Mettre à jour BUSINESS_LOGIC.md + Test
# 4. Si régression → Rejeter le changement
```

---

## Workflow: Quand la Logique Bouge

### Scénario 1: Bug ou Edge Case Trouvé

```
1. Reproduire le bug → Test qui échoue
2. Fixer le bug → Test passe
3. Documenter dans BUSINESS_LOGIC.md
4. Commit avec message clair
```

### Scénario 2: Nouvelle Règle Métier Ajoutée

```
1. Écrire règle dans BUSINESS_LOGIC.md (Zone 1/2/3)
2. Écrire test qui échoue
3. Implémenter la règle
4. Test passe
5. Commit
```

### Scénario 3: Logique Existant Change

```
1. Test existant échoue
2. Question: INVMARIANT OU COMPORTEMENT?
   
   Si INVARIANT cassé:
   - Stop! Regarder le test
   - Est-ce vraiment la bonne règle métier?
   - Si oui → Rejeter le changement
   - Si non → Mettre à jour BUSINESS_LOGIC.md + Test
   
   Si COMPORTEMENT temporaire:
   - Mettre à jour le test
   - Documenter pourquoi dans BUSINESS_LOGIC.md
   - Continuer
```

---

## Structure des Tests par Zone

### Zone 1: Tests Stricts (Invariants)

```ruby
RSpec.describe Membership, type: :model do
  describe "invariants - IMMUTABLES" do
    # Ces tests ne DEVRAIENT JAMAIS échouer
    it "cannot have overlapping active memberships"
    it "must have end_date after start_date"
    it "cannot downgrade from Circus to Basic"
  end
  
  describe "business rules - STABLE" do
    # Ces tests échouent si logique change MAIS on valide intention
    it "can upgrade from Basic to Circus"
    it "becomes inactive when upgraded"
  end
end
```

### Zone 2: Tests Souples (Exploration)

```ruby
RSpec.describe "Exploratory Feature X" do
  describe "current behavior" do
    # Documente ce que ça fait MAINTENANT
    it "works like this for now"
  end
  
  # Pas de tests stricts tant que logique fluctue
end
```

### Zone 3: Pas de Tests

```ruby
# Rien! Code n'existe pas encore
```

---

## Les Règles Anti-Fragilité

### 1. Ne teste PAS les détails d'implémentation

```ruby
❌ it "calls update! with status active"
❌ it "uses a transaction"
❌ it "generates a UUID with SecureRandom"

✅ it "activates membership when valid"
✅ it "prevents overlapping memberships"
✅ it "creates a unique identifier"
```

### 2. Utilise des abstractions stables

```ruby
❌ it "sets membership.status to :active"

✅ it "activates the membership" do
  expect(membership.active?).to be true
end
```

### 3. Teste les transitions d'état, pas les états isolés

```ruby
❌ it "has status active"
✅ it "transitions from pending to active when payment succeeds"
```

### 4. Utilise des factories, pas de mocks complexes

```ruby
❌ allow_any_instance_of(Membership).to receive(:save!)

✅ membership = create(:membership, status: :pending)
   membership.activate!
   expect(membership.active?).to be true
```

---

## Comment Organiser tes Tests

### Structure Recommandée

```
spec/
├── models/
│   ├── subscription_plan_spec.rb
│   │   ├── describe "invariants - IMMUTABLES"
│   │   ├── describe "validations"
│   │   ├── describe "associations"
│   │   ├── describe "business rules"
│   │   └── describe "current behavior" (Zone 2)
│   ├── membership_spec.rb
│   └── book_of_entry_spec.rb
├── services/
│   ├── payments/
│   │   └── process_spec.rb
│   │       ├── describe "contract - MUST ALWAYS"
│   │       ├── describe "business rules"
│   │       └── describe "current behavior"
│   └── memberships/
│       └── upgrade_spec.rb
└── shared_examples/
    ├── priceable.rb (concern contract)
    └── versionable.rb (concern contract)
```

---

## Exemple Concret: SubscriptionPlan

### Ce qu'on a testé (Stable)

```ruby
# Invariants
- price_cents MUST be > 0
- name MUST be unique scoped by version
- pack10 MUST have sessions_count and validity_days

# Business Rules
- duration_days returns correct values
- create_price_change! creates new version properly
- for_circus_members? delegates to membership_type.circus?

# Contracts
- responds to Priceable concern methods
- responds to Versionable concern methods
```

### Ce qu'on N'A PAS testé (Implémentation)

```ruby
# Détails d'implémentation
- how version is incremented (fait dans scope)
- which SQL query is generated
- how dup works internally
```

**Résultat:** Si tu changes comment `create_price_change!` fonctionne EN INTERNE, les tests continuent de passer tant que le comportement reste le même.

---

## Action Items

### Immédiat

1. ✅ Créer ce document
2. ⏳ Identifier 5 invariants métier CORE dans ton app
3. ⏳ Ajouter section "invariants" dans chaque spec important

### Court Terme

1. ⏳ Créer shared_examples pour contrats concerns
2. ⏳ Documenter dans BUSINESS_LOGIC.md les règles invariantes
3. ⏳ Formatter tests pour distinguer invariants vs comportement

### Long Terme

1. ⏳ Appliquer cette stratégie à tous les tests Zone 1
2. ⏳ Réviser tests existants pour être plus résilients
3. ⏳ Ajouter documentation "WHAT vs HOW" dans chaque test

---

## Résumé

**Teste le QUOI, pas le COMMENT**

- ✅ Invariants métier
- ✅ Contrats d'interface
- ✅ Comportements attendus
- ❌ Détails d'implémentation
- ❌ Code interne

Si tu suis cette approche, tes tests survivront à 90% des refactorings car ils testent l'intention, pas la réalisation.

