# TODO — Le Circographe

> **Statut** : internal
> **Public cible** : équipe dev
> **Dernière vérification** : 2026-08-10
> **Sources de vérité** : `app/`, historique git.

*Revu le 2026-05-06 — ratissage élargi des 12 derniers commits + scan `rg` ciblé du repo. Complété le 2026-08-10 avec les items relevés lors d'un audit de la doc (voir entrées ajoutées ci-dessous).*

## Now
- [x] **Paiements —** Les écrans admin (`Admin::PaymentsController#destroy`, `Admin::Members::PaymentsController#destroy`) passent déjà par `People::PaymentCanceller` (annulation `status: cancel`, pas de suppression ligne). `Payment#destroy` est désormais verrouillé par défaut ; le hard delete résiduel passe par une intention explicite `Payment#hard_delete!` pour les usages techniques/tests.
- [ ] Ajouter les métadonnées de reçu de don : numéro, date d’émission, émetteur (non implémenté côté app / pas de feature « reçu » dans le repo à ce jour).

## Next safe steps
- [ ] Ajouter l’action admin de génération / réenvoi de reçu de don (dépend des métadonnées ci-dessus).
- [x] Documenter explicitement dans la doc d’architecture que `Person#renew_membership!` est le dernier gros workflow conservé sur le modèle avant une extraction éventuelle (mentions déjà présentes : `docs/domain_model.md`, `docs/glossary.md`, `docs/domain/business_logic.md`).
- [ ] Continuer la consolidation DRY des shells / layouts Tailwind sans refonte lourde.
- [x] Corriger les offenses WCAG critiques/majeures/mineures sur les pages publiques. *(skip-link, main#main-content, label newsletter, autocomplete, table horaires caption+scope, SVG aria-hidden, line-height body, contact form required+autocomplete, liens externes SR, Leaflet focus-visible, h2 accordion→div, adresse postale→address)*
- [x] Stabiliser le vocabulaire de primitives UI déjà posé (`page-container`, `surface-card`, `admin-page-header`, `admin-metric-card`). *(Étendu : `section-eyebrow`, `hero-title`, `section-title`, `subsection-title`, `body-text`, `body-text-lg` ajoutés dans `layout.css` ; couleur hardcodée `#1F5C55` remplacée par `text-brand-primary/70` dans 5 fichiers. Migration des vues existantes : opportuniste.)*
- [x] Repenser l’affichage des horaires partagés (`shared/_opening_hours`) pour un rendu plus lisible et compact sur les pages publiques. *(badge semaine, caption/scope, mise en avant “Aujourd’hui”, variantes `bare` / `compact`)*
- [x] Ajouter une navigation par onglets sur la FAQ publique via Stimulus. *(`faq_tabs_controller`, boutons d’onglets dédiés, contenu dynamique par section)*
- [x] Consolider les shells des pages publiques actives autour des primitives `public-hero-shell`, `hero-panel`, `public-surface`, avec ancres `scroll-mt-*` et variantes réutilisables sur `association`, `become_member`, `contact_us`, `faq`, `gallery`, `news`, `about`. *(progression opportuniste, pas une extraction totale en composants)*
- [x] Ajuster la home pour le mobile sans casser desktop. *(wrapper plein écran pour `home#index`, fond mobile zoomé, titre forcé sur deux lignes ≤ `640px`, CTA re-positionnés plus bas, nettoyage `swiper_overrides`)* 

## Later
- [ ] **Billetterie événements payants via HelloAsso** — feature à cadrer, contrainte structurelle identifiée (2026-08-10) : l'API publique HelloAsso ne permet **pas** de créer un formulaire/événement par API (aucun endpoint `POST forms` documenté, confirmé par recherche doc + forum dev.helloasso.com sans réponse officielle). Conséquence : double saisie manuelle obligatoire — créer l'`Event` chez nous **et** le formulaire de billetterie dans le back-office HelloAsso — puis les lier à la main (garder le slug/ID du formulaire HelloAsso sur notre `Event`).
  - Paiement : `POST /v5/organizations/{slug}/checkout-intents` avec `metadata` (`event_id` + `person_id`) → redirection vers page HelloAsso → webhook `Payment` (signature HMAC-SHA256, retries jusqu'à ~16 tentatives donc prévoir l'idempotence) pour marquer le paiement reçu.
  - `EventAttendee` (`belongs_to :payment, optional: true`) actuellement mort dans le code est le point d'ancrage naturel pour stocker la référence du paiement HelloAsso — à réactiver plutôt qu'à supprimer (voir note phase 4 dans `../migrations/vocabulary_migration.md`).
  - Zones d'incertitude à lever avant de s'engager : (1) places restantes non exposées par l'endpoint public `forms/{type}/{slug}/public` (signalé sans réponse officielle sur leur forum) ; (2) paiement en invité vs création de compte HelloAsso obligatoire pour le payeur — non confirmé dans leur doc technique, à tester en sandbox (`helloasso-sandbox.com`).
  - Pas de SDK Ruby officiel — prévoir un client HTTP maison (Faraday) plutôt qu'un gem communautaire non audité.
- [ ] Décider de la marche à suivre pour la détection/fusion de doublons `Person` (route `admin/duplicates` déclarée dans `config/routes.rb` sans `Admin::DuplicatesController` — en attente d'une décision liée à un futur import de membres par Excel).
- [ ] Ajouter les filtres reporting de dons par période et méthode de paiement.
- [ ] Construire le flux RGPD d’anonymisation `Person` / `User` avec raison et acteur.
- [ ] Ajouter un dashboard admin minimal pour les feature flags existants.
- [ ] Ouvrir une branche d’amorçage OAuth : cadrer le premier provider, le flux de rattachement `User`/`Person`, et les points d’entrée login / revendication de compte avant toute implémentation UI.

## To verify
- [ ] Confirmer en production qu’aucune `PaymentLine` legacy de don (`item_type: "Payment"`) ne subsiste après la migration déjà appliquée.
- [ ] Confirmer si le crédit prorata de `People::ContributionUpgrader` doit rester ou être remplacé par une remise / offre explicite.
- [ ] Confirmer en base de production l’absence de `payments.user_id` et la présence de `payments.recorded_by_id`.
- [ ] Confirmer qu’aucune donnée de production ne dépend encore de `people.newsletter_subscribed`.
- [ ] Confirmer que les scripts inline admin restants sont tous couverts par Stimulus.
- [ ] Confirmer les règles métier de refus de suppression `Person` avec paiements, adhésions ou cotisations.
- [ ] Confirmer que les exemptions d’auth récentes (`BlogsController#index/show`, `UsersController#unsubscribe_by_token`) sont bien intentionnelles, documentées et couvertes par tests.
- [ ] Vérifier le comportement clavier / focus / hash navigation de la FAQ à onglets sur mobile et desktop.
- [ ] Vérifier le rendu réel des horaires compacts sur toutes les vues publiques qui embarquent `shared/_opening_hours` (home, adhésion, autres shells publics).
- [ ] Vérifier que la fraîcheur des horaires (`OpeningHour.latest_update_entry.updated_at`, DB) est affichée de façon cohérente partout où elle compte : présente sur `become_member`, absente de `shared/_opening_hours` (utilisé aussi par `home`, `contact_us`).

## Mobile first
- [x] Navigation : meilleur feedback tactile / actif dans le menu mobile. *(toggles + liens avec état pressé/actif plus lisible)*
- [x] Ratio : stabiliser les médias de carrousel sur petit écran avant desktop polish. *(frame `public-carousel-media` sur sliders image publics)*
- [ ] Feedback : vérifier sur vrai device la lisibilité du menu mobile ouvert/fermé et la hiérarchie des états actifs.
- [ ] Ratio : vérifier au cas par cas les sliders `about` / `news` / galleries pour décider lesquels méritent un ratio dédié plutôt qu’un frame partagé.

## UI / DRY
- [x] Stabiliser la base visuelle existante sans refonte. *(heroes publics harmonisés pour mobile + desktop via primitives de texte et panel réutilisables)*
- [ ] Garder des shells / layouts assez propres pour faire varier les contextes d’appareil sans empiler les exceptions. *(réduire les wrappers répétitifs, une seule autorité de scroll par shell, pas de logique hauteur / overflow dupliquée dans les sous-vues, DRY limité aux vues actives)*
- [x] Poser un premier socle de primitives publiques réutilisables pour réorienter les vues actives. *(`public-section-shell`, `public-card-shell`, `public-soft-section`, `public-anchor-section`, `public-hero-panel-centered` ; migration légère sur `association`, `news`, `faq`, `gallery`, `contact_us`, `become_member`, `shared/_faq_section`)*
- [x] Garder des primitives assez stables pour accueillir plus tard GSAP 3 comme couche d’animation, sans devoir refaire la structure des pages. *(Infra + hero accueil : `home_animations.js` → GSAP / `gsapScoped`, scope `data-home-animations-scope` ; détail `docs/development/assets.md`.)*
