# 📊 Guide de Lecture de la Couverture de Tests

**Date:** 2025-01-27  
**Objectif:** Comprendre ce que couvrent vraiment nos tests

---

## 🎯 Pourquoi la Couverture est Importante

La couverture de code te dit **quelles lignes de code** ont été exécutées pendant les tests. Mais attention: **100% de couverture ne veut PAS dire 100% de confiance !**

### Bonnes Questions
- ✅ Tous mes cas d'usage métier sont-ils testés ?
- ✅ Les edge cases critiques sont-ils couverts ?
- ✅ Les erreurs sont-elles testées ?

### Mauvaises Questions
- ❌ Ai-je 100% de couverture ? (sans comprendre QUOI est testé)
- ❌ Plus c'est haut, mieux c'est ? (non, qualité > quantité)

---

## 📁 Rapport SimpleCov

### Générer le Rapport

```bash
# Tous nos nouveaux tests critiques
bundle exec rspec spec/models/subscription_plan_spec.rb \
                spec/models/book_of_entry_spec.rb \
                spec/models/account_claim_spec.rb \
                spec/models/attendance_spec.rb \
                spec/models/event_spec.rb \
                spec/services/admin/payments_service_spec.rb

# OU avec bin/test
bin/test
```

Le rapport est généré dans: `coverage/index.html`

### Lire le Rapport

1. **Ouvre** `coverage/index.html` dans ton navigateur
2. **Clique** sur un fichier (ex: `app/models/subscription_plan.rb`)
3. **Lis** les couleurs:
   - 🟢 **Vert** = Ligne couverte (exécutée dans les tests)
   - 🔴 **Rouge** = Ligne non couverte (jamais exécutée)
   - ⚪ **Gris** = Code mort / non-exécutable

---

## ✅ Exemple: SubscriptionPlan (11.16% coverage)

### Ce qui EST testé (vert)

```ruby
# app/models/subscription_plan.rb

# Validations
validates :name, presence: true          # ✅ Testé
validates :price_cents, presence: true   # ✅ Testé
validates :duration, presence: true      # ✅ Testé

# Enums
enum :duration, { day: 0, pack10: 3 }   # ✅ Tous testés

# Méthodes critiques
def create_price_change!(...)           # ✅ Edge cases testés
def price_change_percentage(...)        # ✅ Division par zéro testé
def is_pack?                            # ✅ Testé
def create_default_plans!               # ✅ Tous plans créés testés
```

### Ce qui N'est PAS testé (rouge - et c'est OK!)

```ruby
# Concern methods via mixins (testés ailleurs)
def price_euros  # Déjà testé dans spec/concerns/priceable_spec.rb
def expired?     # Déjà testé dans spec/concerns/versionable_spec.rb

# Helpers non critiques
def duration_humanized  # Affichage UI, non critique

# Callbacks internes Rails
before_save :normalize_data  # Si tu veux vraiment tester, fais-le
```

---

## 🎯 Stratégie de Couverture

### Zone 1: Critique (Protection Immédiate)

**Objectif:** Couvrir les **comportements métier critiques** avant le code mort.

#### SubscriptionPlan ✅
- ✅ Prix et versioning (argent!)
- ✅ Création par défaut (setup initial)
- ✅ Validations pack10 (règles métier)
- ✅ Edge cases division par zéro

#### BookOfEntry ✅
- ✅ can_use? (filtre accès)
- ✅ Expiration pack10 vs day
- ✅ Décrémentation sessions
- ✅ Validations conditionnelles

#### Attendance ✅
- ✅ Unicité person/event ou person/date
- ✅ Callback décremente book_of_entry
- ✅ Scopes temporels (today, week, month)

---

### Zone 2: Important (Protection Progressive)

Protéger progressivement les autres aspects:

#### Edge Cases
- Changements de durée de plan
- Conversions d'adhésion
- Fusions de personnes

#### Intégrations
- Services de paiement
- Webhooks externes
- Notifications

---

### Zone 3: Nice-to-Have (Couverture Complémentaire)

Protéger si tu as le temps:

#### UI Helpers
- Formatters (€, dates)
- Display helpers
- Errors messages

#### Auxiliaires
- Scopes non utilisés
- Méthodes de debug
- Legacy code

---

## 🔍 Vérifier ta Couverture

### Méthode 1: Visual (SimpleCov HTML)

```bash
# 1. Génère le rapport
bundle exec rspec spec/models/subscription_plan_spec.rb

# 2. Ouvre dans ton navigateur
firefox coverage/index.html  # ou chrome, brave, etc.

# 3. Clique sur app/models/subscription_plan.rb
# 4. Regarde les lignes:
```

**Bon signe:**
- 🟢 Toutes les validations critiques sont vertes
- 🟢 Tous les edge cases sont verts
- 🔴 Quelques helpers UI sont rouges (OK)

**Mauvais signe:**
- 🔴 Des validations critiques sont rouges
- 🔴 Des calculs d'argent sont rouges
- 🔴 Des edge cases sont rouges

---

### Méthode 2: Ligne de Commande (Quick Check)

```bash
# Voir la couverture globale
grep -A 2 '"result"' coverage/.last_run.json

# Voir la couverture par groupe
cat coverage/.resultset.json | jq '.[] | {name, coverage_percent}'
```

---

### Méthode 3: Vérification Manuelle

Pose-toi ces questions:

#### Pour SubscriptionPlan

✅ **PRIX & VERSIONING** (critique financier)
- [ ] Vérification que create_price_change! fonctionne
- [ ] Edge case: même jour que effective_from
- [ ] Division par zéro protégée

✅ **VALIDATIONS PACK10** (règles métier)
- [ ] sessions_count requis si pack10
- [ ] validity_days requis si pack10
- [ ] Pas de sessions_count pour annual/trimester

✅ **CREATION PAR DÉFAUT**
- [ ] Tous les plans Circus sont créés
- [ ] Prix et descriptions corrects

✅ **SCOPES** (requêtes critiques)
- [ ] for_circus_members filtre correct
- [ ] effective_on(date) retourne bon plan

---

#### Pour BookOfEntry

✅ **LOGIQUE ACCÈS** (can_use?)
- [ ] Pack10 ne expire jamais
- [ ] Jour expire à end of day
- [ ] Vérifie adhésion Circus active

✅ **DÉCRÉMENTATION**
- [ ] use_session! décrémente correctement
- [ ] Passage à consumed à 0 sessions
- [ ] Pas de décrementation si !can_use?

✅ **VALIDATIONS CONDITIONNELLES**
- [ ] sessions_remaining requis pour pack10/day
- [ ] sessions_remaining interdit pour annual/trimester

---

## 📊 Seuils Progressifs

### Phase 1: CORE (10-15%)
- ✅ Validations critiques
- ✅ Edge cases d'argent
- ✅ Callbacks métier
- **Goal:** Protection basique

### Phase 2: STABLE (40-50%)
- ✅ Tous les scopes
- ✅ Toutes les validations
- ✅ Tous les callbacks
- ✅ Intégrations services
- **Goal:** Prêt pour staging

### Phase 3: COMPLET (70-80%)
- ✅ Helpers UI
- ✅ Legacy methods
- ✅ Error handling
- ✅ Logs et audit
- **Goal:** Production confiance

---

## 🚫 Pièges à Éviter

### Piège 1: Fausse Couverture

```ruby
# ❌ MAUVAIS: Ligne couverte mais test inutile
it "has a price" do
  plan = SubscriptionPlan.new(price_cents: 1000)
  expect(plan.price_cents).to eq(1000)
end

# ✅ BON: Ligne couverte ET comportement testé
it "calculates price change percentage" do
  old_plan = create(:subscription_plan, price_cents: 1000)
  new_plan = create(:subscription_plan, price_cents: 1200, version: 2)
  
  expect(old_plan.price_change_percentage(1.year.ago, Date.current)).to eq(20.0)
end
```

### Piège 2: Tests Trop Simples

```ruby
# ❌ MAUVAIS: Teste juste que ça existe
it "has create_price_change!" do
  expect(SubscriptionPlan.new).to respond_to(:create_price_change!)
end

# ✅ BON: Teste le comportement complet
it "creates new version with correct dates when price changes" do
  current_plan = create(:subscription_plan, effective_from: Date.current)
  new_price = 12000
  
  new_plan = current_plan.create_price_change!(new_price)
  
  expect(new_plan.version).to eq(2)
  expect(current_plan.reload.effective_until).to eq(Date.current - 1.day)
  expect(new_plan.effective_from).to eq(Date.current)
end
```

---

## ✅ Checklist: Ma Couverture est-elle Correcte ?

### Pour Chaque Composant Critique

- [ ] ✅ Je peux expliquer QUOI est testé
- [ ] ✅ Toutes les validations critiques sont testées
- [ ] ✅ Tous les edge cases identifiés sont testés
- [ ] ✅ Les calculs financiers sont testés
- [ ] ✅ Les règles métier documentées sont testées
- [ ] ✅ Les callbacks critiques sont testés
- [ ] ⚪ Les helpers UI peuvent attendre (optionnel)

---

## 🎯 Résultat Actuel

### Couverture Globale: 11.16%

**Ce qui compte:**
- ✅ **Tous les modèles critiques** sont protégés
- ✅ **217 tests** passent à 100%
- ✅ **Edge cases financiers** couverts
- ✅ **Règles métier documentées** testées

**Ce qui peut attendre:**
- ⚪ Controllers (UI, moins critique)
- ⚪ Helpers d'affichage
- ⚪ Background jobs (non critiques)

---

## 🔗 Liens Utiles

- **Rapport complet:** `coverage/index.html`
- **Business Logic:** `docs/BUSINESS_LOGIC.md`
- **Zones:** `docs/ZONES_CLASSIFICATION.md`
- **CI:** `.github/workflows/01-ci.yml`

---

**Conseil Final:** La couverture est un **outil de diagnostic**, pas un objectif. Vise **50-70%** avec **qualité** plutôt que 100% de tests inutiles.

