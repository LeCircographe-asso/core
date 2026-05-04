# TODO — Le Circographe

## Now
- [ ] Remplacer le hard delete `Payment#destroy` par une annulation explicite via service.
- [ ] Ajouter les métadonnées de reçu de don : numéro, date d'émission, émetteur.

## Next safe steps
- [ ] Ajouter l'action admin de génération/réenvoi de reçu de don.
- [ ] Documenter `Person#renew_membership!` comme dernier workflow modèle conservé avant éventuelle extraction.
- [ ] Continuer la consolidation DRY des shells/layouts Tailwind sans refonte lourde.
- [ ] Stabiliser le vocabulaire de primitives UI déjà posé (`page-container`, `surface-card`, `admin-page-header`, `admin-metric-card`).

## Later
- [ ] Ajouter les filtres reporting de dons par période et méthode de paiement.
- [ ] Construire le flux RGPD d'anonymisation `Person`/`User` avec raison et acteur.
- [ ] Ajouter un dashboard admin minimal pour les feature flags existants.

## To verify
- [ ] Confirmer en production qu'aucune `PaymentLine` legacy de don (`item_type: "Payment"`) ne subsiste après la migration déjà appliquée.
- [ ] Confirmer si le crédit prorata de `People::ContributionUpgrader` doit rester ou être remplacé par une remise/offre explicite.
- [ ] Confirmer en base de production l'absence de `payments.user_id` et la présence de `payments.recorded_by_id`.
- [ ] Confirmer qu'aucune donnée de production ne dépend encore de `people.newsletter_subscribed`.
- [ ] Confirmer que les scripts inline admin restants sont tous couverts par Stimulus.
- [ ] Confirmer les règles métier de refus de suppression `Person` avec paiements, adhésions ou cotisations.

## UI / DRY
- [ ] Garder le cap: stabiliser la structure visuelle existante sans redesign massif.
- [ ] Réduire les wrappers HTML/CSS répétitifs avant d’ajouter de nouvelles variantes UI.
- [ ] Étendre le DRY seulement sur les vues actives, pas sur les variantes legacy suspectes (`show_old`, `show_mobile`, backups, etc.).
- [ ] Garder une seule autorité de scroll par shell pour éviter les scrollbar parasites et les layouts imbriqués qui se battent entre eux.
- [ ] Éviter de remettre de la logique de hauteur/overflow globale dans les sous-vues une fois qu’un layout ou shell la porte déjà.
- [ ] Viser un niveau de HTML/CSS/Tailwind suffisamment propre pour faire varier les layouts selon les contextes d’appareil sans empiler les exceptions.
- [ ] Garder des primitives assez stables pour accueillir plus tard GSAP 3 comme couche d’animation, sans devoir refaire la structure des pages.
