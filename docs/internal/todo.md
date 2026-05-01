# TODO — Le Circographe

## Now
- [ ] Retirer les derniers wrappers historiques de `Person` devenus façade vers `People::*`, en commençant par `create_membership!` et `create_contribution!` hors renouvellement.
- [ ] Ajouter une spec service pour `People::MembershipUpgrader` couvrant la ligne de don optionnelle et le paiement `offered`.
- [ ] Ajouter une spec request admin de création cotisation avec vérification des `PaymentLine` catalogue + don.
- [ ] Ajouter une spec de régression sur `People::ContributionUpgrader` pour figer le comportement actuel du crédit prorata.

## Next safe steps
- [ ] Remplacer le hard delete `Payment#destroy` par une annulation explicite via service.
- [ ] Ajouter les métadonnées de reçu de don : numéro, date d'émission, émetteur.
- [ ] Ajouter l'action admin de génération/réenvoi de reçu de don.

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
