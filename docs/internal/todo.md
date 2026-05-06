# TODO — Le Circographe

*Revu le 2026-05-04 — aligné avec le code courant.*

## Now
- [x] **Paiements —** Les écrans admin (`Admin::PaymentsController#destroy`, `Admin::Users::PaymentsController#destroy`) passent déjà par `People::PaymentCanceller` (annulation `status: cancel`, pas de suppression ligne). `Payment#destroy` est désormais verrouillé par défaut ; le hard delete résiduel passe par une intention explicite `Payment#hard_delete!` pour les usages techniques/tests.
- [ ] Ajouter les métadonnées de reçu de don : numéro, date d’émission, émetteur (non implémenté côté app / pas de feature « reçu » dans le repo à ce jour).

## Next safe steps
- [ ] Ajouter l’action admin de génération / réenvoi de reçu de don (dépend des métadonnées ci-dessus).
- [x] Documenter explicitement dans la doc d’architecture que `Person#renew_membership!` est le dernier gros workflow conservé sur le modèle avant une extraction éventuelle (mentions déjà présentes : `docs/domain_model.md`, `docs/glossary.md`, `docs/domain/business_logic.md`).
- [ ] Continuer la consolidation DRY des shells / layouts Tailwind sans refonte lourde.
- [ ] Stabiliser le vocabulaire de primitives UI déjà posé (`page-container`, `surface-card`, `admin-page-header`, `admin-metric-card`).

## Later
- [ ] Ajouter les filtres reporting de dons par période et méthode de paiement.
- [ ] Construire le flux RGPD d’anonymisation `Person` / `User` avec raison et acteur.
- [ ] Ajouter un dashboard admin minimal pour les feature flags existants.

## To verify
- [ ] Confirmer en production qu’aucune `PaymentLine` legacy de don (`item_type: "Payment"`) ne subsiste après la migration déjà appliquée.
- [ ] Confirmer si le crédit prorata de `People::ContributionUpgrader` doit rester ou être remplacé par une remise / offre explicite.
- [ ] Confirmer en base de production l’absence de `payments.user_id` et la présence de `payments.recorded_by_id`.
- [ ] Confirmer qu’aucune donnée de production ne dépend encore de `people.newsletter_subscribed`.
- [ ] Confirmer que les scripts inline admin restants sont tous couverts par Stimulus.
- [ ] Confirmer les règles métier de refus de suppression `Person` avec paiements, adhésions ou cotisations.

## UI / DRY
- [ ] Garder le cap : stabiliser la structure visuelle existante sans redesign massif.
- [ ] Réduire les wrappers HTML / CSS répétitifs avant d’ajouter de nouvelles variantes UI.
- [ ] Étendre le DRY seulement sur les vues actives, pas sur les variantes legacy suspectes (`show_old`, `show_mobile`, backups, etc.).
- [ ] Garder une seule autorité de scroll par shell pour éviter les scrollbar parasites et les layouts imbriqués qui se battent entre eux.
- [ ] Éviter de remettre de la logique de hauteur / overflow globale dans les sous-vues une fois qu’un layout ou shell la porte déjà.
- [ ] Viser un niveau de HTML / CSS / Tailwind suffisamment propre pour faire varier les layouts selon les contextes d’appareil sans empiler les exceptions.
- [x] Garder des primitives assez stables pour accueillir plus tard GSAP 3 comme couche d’animation, sans devoir refaire la structure des pages. *(Infra + hero accueil : `home_animations.js` → GSAP / `gsapScoped`, scope `data-home-animations-scope` ; détail `docs/development/assets.md`.)*
