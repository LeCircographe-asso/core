# Migration de Vocabulaire — DDD-light

> **Statut** : stable (transitionnel — disparaît à la fin de phase 4)
> **Public cible** : contributeur
> **Dernière vérification** : 2026-08-10
> **Sources de vérité** : `app/models/`, `app/services/people/`, [`../glossary.md`](../glossary.md).

> Plan progressif d'alignement vocabulaire / code / documentation, sans big-bang. Chaque phase est livrable seule, sans casser la précédente.
> **Vocabulaire cible :** voir [../glossary.md](../glossary.md).
> **Avancement** : phases 0 à 3 terminées côté code. Seule la phase 4 (cleanup legacy) reste ouverte — voir §2 et §3.

---

## 1. Mapping ancien → nouveau

### 1.1 Modèles et tables

| Ancien (legacy) | Nouveau (cible) | Type | Phase |
| --- | --- | --- | --- |
| `SubscriptionPlan` (modèle) | `ContributionFormula` | rename modèle + table | `phase3-model-rename` |
| `subscription_plans` (table) | `contribution_formulas` | rename DB | `phase3-model-rename` |
| `BookOfEntry` (modèle) | `Contribution` | rename modèle + table | `phase3-model-rename` |
| `book_of_entries` (table) | `contributions` | rename DB | `phase3-model-rename` |
| `UserMembership` (modèle) | (supprimé) | supprimé (architecture Person) | déjà archivé |
| `EventAttendee` (modèle legacy) | (supprimé après audit) | suppression conditionnelle | `phase4-legacy-cleanup` |

### 1.2 Colonnes et associations

| Ancien | Nouveau | Localisation | Phase |
| --- | --- | --- | --- |
| `book_of_entry_id` (sur `attendances`) | `contribution_id` | DB + code | `phase3-model-rename` |
| `subscription_plan_id` (sur ex-`book_of_entries`) | `contribution_formula_id` | DB + code | `phase3-model-rename` |
| `payment_lines.item_type = "SubscriptionPlan"` | `"ContributionFormula"` | data migration | `phase3-model-rename` |
| `payment_lines.item_type = "BookOfEntry"` | `"Contribution"` | data migration | `phase3-model-rename` |
| `payment_lines.item_type = "Payment"` (don) | `"Donation"` | data migration | `phase1-donation-fix` |
| `payments.donation` (cents) | (supprimé) | DB + code | `phase1-donation-fix` |

### 1.3 Méthodes et concepts

| Ancien | Nouveau | Localisation | Phase |
| --- | --- | --- | --- |
| `Person#create_subscription!` | `Person#create_contribution!` | `app/models/person.rb` | `phase3-model-rename` |
| `Person#upgrade_subscription!` | `Person#upgrade_contribution!` | `app/models/person.rb` | `phase3-model-rename` |
| `Person#active_subscription?` | `Person#active_contribution?` | `app/models/person.rb` | `phase0-quick-wins` |
| `Person#current_subscription` | `Person#current_contribution` | `app/models/person.rb` | `phase0-quick-wins` |
| `Person#subscriptions` | `Person#contributions` | `app/models/person.rb` | `phase3-model-rename` |
| `User#inferior_rights` | `User#subordinate_roles` | `app/models/user.rb` | `phase0-quick-wins` |
| `bookOfEntryValidation` (callback) | (supprimé — déjà fait) | `app/models/book_of_entry.rb` | déjà fait |
| `People::SubscriptionCreator` | `People::ContributionCreator` | `app/services/people/` | `phase3-model-rename` |
| `People::SubscriptionUpgrader` | `People::ContributionUpgrader` | `app/services/people/` | `phase3-model-rename` |
| `SubscriptionStatusBadgeComponent` | `ContributionStatusBadgeComponent` | `app/components/` | `phase2-component-rename` |

### 1.4 Vocabulaire documentaire

| Ancien | Nouveau | Localisation |
| --- | --- | --- |
| « abonnement » | « cotisation » | doc et UI |
| « plan d'abonnement » | « formule de cotisation » | doc, seeds, UI |
| « subscription » (cirque) | « contribution » | doc, code, comments |
| « subscription » (newsletter) | (conservé) | newsletter uniquement |
| « article d'adhésion » / « article de cotisation » | « type d'adhésion » / « formule de cotisation » | seeds, doc |
| « carnet d'entrées » (sauf Pack 10) | « cotisation » | doc, code |

---

## 2. Phases (ordre canonique)

### ✅ Phase 0 — Quick wins (zéro impact DB) — fait
- ✅ Renommé `User#inferior_rights` → `User#subordinate_roles` (sans alias rétro-compat).
- ✅ Renommé `User#active_subscription?` → `User#active_membership?` (sans alias rétro-compat).
- Supprimer logs de debug oubliés (`Rails.logger.debug` orphelins, `puts`).
- ✅ **Tests à mettre à jour** : remplacé les usages existants.

### ✅ Phase 1 — Donations propres — fait côté code
- ✅ `People::PaymentCreator` : la réécriture `item_type: "Donation" → "Payment"` **n'existe plus** sur le chemin simple.
- ✅ Migration DB appliquée : `remove_column :payments, :donation` (colonne absente de `db/schema.rb`).
- ✅ `PaymentLine::ALLOWED_ITEM_TYPES` n'accepte plus `SubscriptionPlan` / `BookOfEntry`.
- Reste en surveillance continue (pas un chantier de code) : `Admin::HealthReport#legacy_donation_lines` détecte en prod les `PaymentLine` avec `item_type: "Payment"` résiduelles — voir [`internal/todo.md`](../internal/todo.md) « Confirmer en production qu'aucune `PaymentLine` legacy de don ne subsiste ».

### ✅ Phase 2 — Composant cosmétique — fait
- ✅ Renommé `SubscriptionStatusBadgeComponent` → `ContributionStatusBadgeComponent` (`app/components/contribution_status_badge_component.rb`).
- Pas d'impact DB ni service.

### ✅ Phase 3 — Renommage modèles + DB — fait
- DB : tables `contribution_formulas` et `contributions` en place (`db/schema.rb`), colonnes `book_of_entry_id`/`subscription_plan_id` renommées.
- Code : plus aucune référence à `SubscriptionPlan` / `BookOfEntry` dans `app/` (modèles, services `People::Contribution*`, méthodes `Person#*contribution*`).
- ✅ Validation `PaymentLine` ne pas accepter `SubscriptionPlan` / `BookOfEntry`.

### ⚠️ Phase 4 — Cleanup legacy — à faire
- [ ] Auditer puis supprimer `EventAttendee` si la fonctionnalité est intégrée à `Attendance` (`app/models/event_attendee.rb` existe toujours).
- [ ] Extraire la logique métier de `Person` vers des services dédiés (le modèle est descendu à ~340 lignes, le seuil ">500 lignes" n'est plus le déclencheur ; à réévaluer si le besoin d'extraction persiste).
- [ ] Supprimer définitivement les derniers termes legacy restants (hors « newsletter subscription », qui est un vocabulaire distinct et légitime).
- ✅ Champ `donation` de `payments` déjà supprimé en phase 1.

---

## 3. Statut documentaire (par phase)

| Phase | Code | Doc principale | Glossaire |
| --- | --- | --- | --- |
| Phase 0 | ✅ done | utilise `subordinate_roles`, `active_membership?` | utilise `subordinate_roles` |
| Phase 1 | ✅ done (code) | utilise `Donation` ; surveillance prod des lignes legacy résiduelles via `Admin::HealthReport` | utilise `Donation` |
| Phase 2 | ✅ done | composant `ContributionStatusBadgeComponent` (legacy `SubscriptionStatusBadgeComponent` supprimé) | idem |
| Phase 3 | ✅ done | utilise `ContributionFormula`/`Contribution` (plus de `SubscriptionPlan`/`BookOfEntry` en code) | idem |
| Phase 4 | ⚠️ à faire | `EventAttendee` pas encore audité/supprimé | idem |

> **Convention documentaire** (historique) : tant que le code n'était pas migré, les documents utilisaient la forme
> « Vocabulaire cible : `Contribution` (code actuel : `BookOfEntry`) ». **La phase 3 est fusionnée : cette mention a disparu**, les documents utilisent directement `Contribution` / `ContributionFormula`.

---

## 4. Changements documentaires immédiats (cette PR)

### 4.1 Safe cleanup
- Création des nouvelles documents : `glossary.md`, `domain_model.md`, `payments.md`, `migrations/vocabulary_migration.md`.
- Réécriture du `README.md` (court, lien glossaire, versions à jour).
- Réécriture de `db/seeds.rb`, `db/seeds/subscription_plans.rb`, `db/seeds/membership_types.rb` (logs et bandeaux français).
- Réécriture des sections 4 et 5 de `docs/domain/business_logic.md`.
- MAJ de `docs/architecture/services.md`.
- Alignement de `MODEL_EVALUATION`, `CONCERNS_ANALYSIS`, `ZONES_CLASSIFICATION`, `UX_GUIDE`, `TODO`, `ARCHITECTURE_GUIDE`.

### 4.2 Corrections à faire avec les migrations futures
- Renommage `SubscriptionPlan → ContributionFormula` dans seeds, factories, vues, locales : **lié à la phase 3**.
- Renommage `BookOfEntry → Contribution` : **lié à la phase 3**.
- Suppression `payments.donation` colonne : **lié à la phase 1**.

### 4.3 Documentation legacy temporaire
- `docs/rake_archive/*.rake` reçoit un encadré « LEGACY ARCHIVE » expliquant le statut.
- `docs/legacy/` (ex `docs/knowledge/`) reçoit son propre `README.md` expliquant que l'ensemble est un « Journal historique non normatif » à différencier des sources canoniques.

### 4.4 Vérifications manuelles
- Liens cassés dans 8 modèles vers `domain_model_circographe.md` (inexistant) → remplacés par `docs/domain_model.md`.
- Lien cassé dans `README.md` vers `CONTRIBUTING.md` (inexistant) → soit créer le fichier, soit supprimer la mention. Décision dans cette PR : supprimer le lien (pas de standard CONTRIBUTING aujourd'hui).
- Lien cassé `CHANGELOG.md` (inexistant) → idem, supprimer la mention dans le README.

---

## 5. Outillage de garde-fou (à ajouter)

### 5.1 Règle de nommage
Un fichier `.cursor/rules/naming-rules.md` (ou section dans `AGENTS.md`) explicite les règles :
- Modèles, services, composants : noms anglais alignés sur le glossaire.
- Méthodes / colonnes : `snake_case` du nom anglais cible.
- Termes interdits : voir glossary §1.7.

### 5.2 Specs garde-fou (à ajouter en phase 1)
```ruby
# spec/models/payment_line_spec.rb
it "n'accepte pas item_type = 'Payment'" do
  expect { build(:payment_line, item_type: "Payment").save!(validate: true) }
    .to raise_error(ActiveRecord::RecordInvalid)
end
```

---

## 6. Documents liés

- [../glossary.md](../glossary.md) — vocabulaire canonique.
- [../domain_model.md](../domain_model.md) — modèle de domaine.
- [../payments.md](../payments.md) — paiements et dons.
- [../domain/business_logic.md](../domain/business_logic.md) — règles métier.
- [../architecture/services.md](../architecture/services.md) — services.
