# TODO — Le Circographe

## Now
- [ ] Remplacer le hard delete `Payment#destroy` par une annulation explicite via service.
- [ ] Ajouter les métadonnées de reçu de don : numéro, date d'émission, émetteur.

## Next safe steps
- [ ] Ajouter l'action admin de génération/réenvoi de reçu de don.
- [ ] Documenter `Person#renew_membership!` comme dernier workflow modèle conservé avant éventuelle extraction.

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
