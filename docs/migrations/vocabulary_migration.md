# Migration de Vocabulaire — DDD-light

> **Statut** : phase 0–3 terminées. Phase 4 (cleanup) ouverte.
> **Vocabulaire cible** : [`../glossary.md`](../glossary.md).

---

## Phases (ordre canonique)

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
- [ ] Auditer puis supprimer `EventAttendee` si intégré à `Attendance`.
- [ ] Supprimer les derniers termes legacy restants (hors « newsletter subscription »).
- ✅ Champ `donation` de `payments` déjà supprimé.

---

## 6. Documents liés

- [../glossary.md](../glossary.md) — vocabulaire canonique.
- [../domain_model.md](../domain_model.md) — modèle de domaine.
- [../payments.md](../payments.md) — paiements et dons.
- [../domain/business_logic.md](../domain/business_logic.md) — règles métier.
- [../architecture/services.md](../architecture/services.md) — services.
