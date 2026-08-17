# TODO — Le Circographe

> **Statut** : internal
> **Public cible** : équipe dev
> **Dernière vérification** : 2026-08-17
> **Sources de vérité** : `app/`, historique git.

*Revu le 2026-05-06 — ratissage élargi des 12 derniers commits + scan `rg` ciblé du repo. Complété le 2026-08-10 avec les items relevés lors d'un audit de la doc (voir entrées ajoutées ci-dessous).*

## Now
- [x] **Paiements —** Les écrans admin (`Admin::PaymentsController#destroy`, `Admin::Members::PaymentsController#destroy`) passent déjà par `People::PaymentCanceller` (annulation `status: cancel`, pas de suppression ligne). `Payment#destroy` est désormais verrouillé par défaut ; le hard delete résiduel passe par une intention explicite `Payment#hard_delete!` pour les usages techniques/tests.
- [x] Ajouter les métadonnées de reçu de don : numéro, date d’émission, émetteur. *(`DonationReceipt` + `People::DonationReceiptIssuer` ; numéro séquentiel par année civile, émetteur figé à l'émission via `ENV["ASSOCIATION_RECEIPT_ISSUER"]`, voir `docs/payments.md` §4.4. Couche données uniquement — pas d'action admin ni de PDF, voir item suivant.)*

## Sécurité (2026-08-17)
- [x] Déjà en place *(pour référence, ne pas dupliquer)* : rate limiting login public+admin (`rate_limit` natif Rails 8, `SessionsController`/`Admin::SessionsController`), `force_ssl`+`assume_ssl` (HSTS) en prod, Brakeman + bundler-audit en CI (`.github/workflows/ci-dev.yml`), `master.key`/`credentials.yml.enc` correctement gitignorés/chiffrés.
- [ ] Rate limiting manquant sur `PasswordsController` (reset), `AccountClaimsController` (revendication compte), `RegistrationsController` (inscription) — même pattern `rate_limit to:/within:` que `SessionsController`.
- [ ] Content-Security-Policy jamais activée (`config/initializers/content_security_policy.rb` = stub commenté par défaut). Définir a minima `default_src :self` + autoriser les CDN déjà utilisés (jsdelivr, cloudflare fontawesome/leaflet).
- [ ] Permissions-Policy absente (pas de `config/initializers/permissions_policy.rb`). Ajouter, désactiver caméra/micro/géoloc par défaut.
- [ ] Confirmer que Brakeman/bundler-audit font échouer la CI en cas d'alerte (pas juste un log silencieux).
- [ ] *(lien, déjà trackée en `Later`)* RGPD anonymisation `Person`/`User` — item conformité/sécurité, pas dupliqué ici.

## Backup base de données prod (2026-08-17)
- [ ] Volume Kamal `circographe_storage` (SQLite + Active Storage local, `config/deploy.yml`) commenté "à sauvegarder hors serveur" mais **aucun mécanisme configuré** — zéro backup en cas de perte serveur/volume.
  - [ ] Choisir la stratégie : Litestream (réplication continue SQLite → S3/Backblaze, standard Rails 8) vs snapshot planifié (cron + upload).
  - [ ] Si Litestream : binaire dans l'image Docker + accessory/process Kamal + bucket S3-compatible + clé d'accès en secret Kamal (`.kamal/secrets`).
  - [ ] Définir fréquence/rétention.
  - [ ] Tester une restauration réelle une fois configuré (backup jamais vérifié = pas fiable).
  - [ ] Documenter la procédure de restauration dans `docs/`.

## Next safe steps
- [x] **Présence directe depuis la fiche membre** *(fait 2026-08-10)* : action « Marquer présent aujourd'hui » sur `Admin::Members::MemberActionsComponent` (visible si adhésion Cirque active), ouvrant `Admin::Members::AttendancesController#new/create` dans un turbo frame sur la fiche membre. Réutilise le service `AttendanceManagement::CheckInService`, déjà écrit et testé mais jamais branché nulle part (même trouvaille que les partials orphelins ci-dessous) — complété d'un garde-fou de prêt plutôt que d'un nouveau service. Remplace les partials orphelins jamais reliés à une route : `_attendance_contribution_confirmation`, `_attendance_direct_confirmation`, `_attendance_contribution_options`, `_attendance_success` (supprimés). Cas « prêt de carnet » couvert : un Pack10 actif avec séances restantes peut couvrir la présence d'une autre personne si **cette personne** (pas le prêteur) a une adhésion Cirque active (`Contribution#lendable_to?`, distinct de `#can_use?` qui teste le propriétaire) ; recherche inline du prêteur par nom. Traçabilité : badge « Carnet de X » sur `admin/attendance_lists` quand `contribution.person != attendance.person`. Bonus : le flag `record_attendance` de `People::ContributionCreator` (déclaré mais jamais utilisé) est maintenant câblé — achat de cotisation + présence en une seule action, case à cocher sur `admin/contributions/new`.
- [ ] Ajouter l’action admin de génération / réenvoi de reçu de don (dépend des métadonnées ci-dessus).
- [x] Documenter explicitement dans la doc d’architecture que `Person#renew_membership!` est le dernier gros workflow conservé sur le modèle avant une extraction éventuelle (mentions déjà présentes : `docs/domain_model.md`, `docs/glossary.md`, `docs/domain/business_logic.md`).
- [ ] Continuer la consolidation DRY des shells / layouts Tailwind sans refonte lourde.
- [x] Rendre dynamiques les prix affichés sur `become_member` (page publique adhésion/tarifs), auparavant codés en dur en HTML alors que le catalogue existe déjà en base. *(2026-08-10 : `PagesController#show` charge `MembershipType.current_versions` / `ContributionFormula.current_versions`, la vue affiche via `number_to_currency`. `Adhésion événement` reste statique — pas de `MembershipType` catégorie `event` en base, cf. item billetterie HelloAsso.)*
- [x] Corriger les offenses WCAG critiques/majeures/mineures sur les pages publiques. *(skip-link, main#main-content, label newsletter, autocomplete, table horaires caption+scope, SVG aria-hidden, line-height body, contact form required+autocomplete, liens externes SR, Leaflet focus-visible, h2 accordion→div, adresse postale→address)*
- [x] Stabiliser le vocabulaire de primitives UI déjà posé (`page-container`, `surface-card`, `admin-page-header`, `admin-metric-card`). *(Étendu : `section-eyebrow`, `hero-title`, `section-title`, `subsection-title`, `body-text`, `body-text-lg` ajoutés dans `layout.css` ; couleur hardcodée `#1F5C55` remplacée par `text-brand-primary/70` dans 5 fichiers. Migration des vues existantes : opportuniste.)*
- [x] Repenser l’affichage des horaires partagés (`shared/_opening_hours`) pour un rendu plus lisible et compact sur les pages publiques. *(badge semaine, caption/scope, mise en avant “Aujourd’hui”, variantes `bare` / `compact`)*
- [x] Ajouter une navigation par onglets sur la FAQ publique via Stimulus. *(`faq_tabs_controller`, boutons d’onglets dédiés, contenu dynamique par section)*
- [x] Consolider les shells des pages publiques actives autour des primitives `public-hero-shell`, `hero-panel`, `public-surface`, avec ancres `scroll-mt-*` et variantes réutilisables sur `association`, `become_member`, `contact_us`, `faq`, `gallery`, `news`, `about`. *(progression opportuniste, pas une extraction totale en composants)*
- [x] Ajuster la home pour le mobile sans casser desktop. *(wrapper plein écran pour `home#index`, fond mobile zoomé, titre forcé sur deux lignes ≤ `640px`, CTA re-positionnés plus bas, nettoyage `swiper_overrides`)* 

## Later
- [ ] **Parcours d'accueil nouveau membre (mobile-first)** *(idée 2026-08-10)* : enchaîner création `Person` → adhésion → cotisation en un seul flux Turbo Frame (« suivant » entre étapes) plutôt que 3 navigations séparées via des menus différents. Pensé pour tablette/téléphone à l'accueil. À ne lancer qu'après avoir observé l'usage réel de la présence directe (item ci-dessus en Next safe steps) — chantier plus lourd (orchestration multi-modèles, gestion des abandons en cours de flux, responsive dédié). Piste « écran de recherche rapide façon front-desk » écartée en discussion : redondante avec la fiche membre/liste existantes, pas de valeur ajoutée claire identifiée.
- [ ] **Galerie photo — suite (Phase 2/3)** : Phase 1 faite le 2026-08-10 (`GalleryPhoto`, upload admin, lightbox Stimulus). Reste à faire quand utile : réordonnancement (`position`), modération/nudité (photos de profil membres — pas la galerie admin, risque plus faible car uploadeurs de confiance).
- [x] **`board_members`/`partners` en BDD** *(2026-08-10, remplace l'item ci-dessus sur la réutilisation `has_one_attached`)* : modèles `BoardMember`/`Partner` + migrations, `Admin::BoardMembersController`/`Admin::PartnersController` (CRUD + `reorder` façon `Faq`, avatar/logo via `has_one_attached`, concern partagé `AttachedImageValidatable` extrait de `GalleryPhoto`). `PagesController#show` (page `about`) et `load_yaml_content` (supprimé, plus utilisé) remplacés par `BoardMember.ordered`/`Partner.ordered`. Bonus découvert en cours de route : un **deuxième système "partenaires" mort** (`PartnersCatalog` + `PartnersController` + `shared/_partners.html.erb`, données fictives jamais affichées nulle part) a été unifié sur le même modèle `Partner` plutôt que laissé en doublon. Seeds : `db/seeds/board_members.rb`, `db/seeds/partners.rb` (ajoutés au pipeline `db/seeds.rb`) reprenant le contenu des anciens `config/content/*.yml` (supprimés). Nécessite `bin/rails db:seed` pour peupler le dev (⚠️ reset toutes les tables comme le fait déjà le seed existant).
- [ ] **Billetterie événements payants via HelloAsso** — feature à cadrer, contrainte structurelle identifiée (2026-08-10) : l'API publique HelloAsso ne permet **pas** de créer un formulaire/événement par API (aucun endpoint `POST forms` documenté, confirmé par recherche doc + forum dev.helloasso.com sans réponse officielle). Conséquence : double saisie manuelle obligatoire — créer l'`Event` chez nous **et** le formulaire de billetterie dans le back-office HelloAsso — puis les lier à la main (garder le slug/ID du formulaire HelloAsso sur notre `Event`).
  - Paiement : `POST /v5/organizations/{slug}/checkout-intents` avec `metadata` (`event_id` + `person_id`) → redirection vers page HelloAsso → webhook `Payment` (signature HMAC-SHA256, retries jusqu'à ~16 tentatives donc prévoir l'idempotence) pour marquer le paiement reçu.
  - `EventAttendee` (`belongs_to :payment, optional: true`) actuellement mort dans le code est le point d'ancrage naturel pour stocker la référence du paiement HelloAsso — à réactiver plutôt qu'à supprimer (voir note phase 4 dans `../migrations/vocabulary_migration.md`).
  - Zones d'incertitude à lever avant de s'engager : (1) places restantes non exposées par l'endpoint public `forms/{type}/{slug}/public` (signalé sans réponse officielle sur leur forum) ; (2) paiement en invité vs création de compte HelloAsso obligatoire pour le payeur — non confirmé dans leur doc technique, à tester en sandbox (`helloasso-sandbox.com`).
  - Pas de SDK Ruby officiel — prévoir un client HTTP maison (Faraday) plutôt qu'un gem communautaire non audité.
- [x] Détection/fusion de doublons `Person` *(fait, périmé — `Admin::DuplicatesController` existe : détection via `Admin::HealthReport`, fusion via `People::AccountMerger`, explicitement pensé comme préalable à l'import Sheet, voir section Import ci-dessous)*.
- [ ] Ajouter les filtres reporting de dons par période et méthode de paiement.
- [ ] Construire le flux RGPD d’anonymisation `Person` / `User` avec raison et acteur.
- [ ] Ajouter un dashboard admin minimal pour les feature flags existants.
- [ ] Ouvrir une branche d’amorçage OAuth : cadrer le premier provider, le flux de rattachement `User`/`Person`, et les points d’entrée login / revendication de compte avant toute implémentation UI.
- [ ] **Autocomplete adresse** *(idée 2026-08-17)* : brancher l'API Adresse gouvernementale (BAN, `api-adresse.data.gouv.fr`, gratuite, sans clé) en Stimulus sur les champs `address`/`zip_code`/`town` de `Person`. À faire en même temps que l'item de fusion des formulaires adresse dupliqués ci-dessous (UI / DRY) plutôt qu'avant — éviter de coder l'autocomplete 3 fois.

## Import membres & historique — Google Sheet (2026-08-17)
- [ ] **Prérequis technique (à faire en premier — l'import ne peut pas fonctionner sans)** :
  - [ ] Dates personnalisables à la création : `People::ContributionCreator` fixe `purchased_at: Time.current` en dur (pas de paramètre date) ; `Admin::MembershipsController#create` idem pour `started_at`. Ajouter un champ date optionnel (défaut aujourd'hui) — nécessaire pour tout import ET pour le cas manuel ("j'ajoute un membre, il a payé il y a 2 mois").
  - [ ] CRUD `Contribution` manquant : `config/routes.rb` n'expose que `new`/`create` (pas d'`edit`/`update`), contrairement à `Membership`/`Payment` qui les ont déjà. Ajouter, mêmes garde-fous que `Admin::MembershipsController#update`.
- [ ] Import `Person` + adhésion Cirque :
  - [ ] Écran admin upload CSV (export natif Google Sheets) + mapping colonnes → champs `Person`/`Membership`.
  - [ ] Détection doublons avant création : réutiliser `Admin::HealthReport` + `People::AccountMerger` (déjà en place, déjà pensés pour ce cas — voir `Admin::DuplicatesController`), ne pas réécrire.
  - [ ] Rapport d'import (créés / doublons ignorés / erreurs) — pas d'import silencieux.
- [ ] Import séances antérieures + présences :
  - [ ] Mapping vers `AttendanceList`/`Attendance` en écriture directe (pas via `CheckInService` — c'est un fait passé, pas un check-in temps réel).
  - [ ] À trancher avant de coder : ces présences historiques décrémentent-elles un Pack10 rétroactivement, ou tracent-elles juste un fait sans toucher aux compteurs actuels ?
- [ ] Import/ajout rétroactif de cotisations et paiements :
  - [ ] Une fois les dates personnalisables (prérequis ci-dessus), réutiliser `People::ContributionCreator`/`People::PaymentRecorder` — le cas "un admin ajoute une adhésion passée à la main" doit passer par le même chemin que l'import en masse, pas un outil séparé.

## Export de données (2026-08-17)
- [ ] Existant : `Admin::ExportsController`, 2 exports CSV étroits (newsletter, `Person` basique). Rien sur paiements/cotisations/présences.
- [ ] Étendre à : historique paiements, cotisations, présences — utile compta, sauvegarde, filet de sécurité avant un import.
- [ ] Colonnes cohérentes avec l'import ci-dessus pour permettre un cycle export → correction → réimport.

## Harmonisation backoffice — CMS vs CRM (2026-08-17)
- [ ] Constat *(lié à l'item d'harmonisation UI/DRY)* : la sidebar mélange sans distinction contenu public (Blog, Galerie, CA, Partenaires, Horaires, FAQ = CMS) et gestion adhérents/argent (Membres, Paiements, Cotisations, Présence = CRM).
- [ ] Séparer visuellement les deux dans la nav (sections nommées ou zones distinctes) pour réduire la charge de navigation.
- [ ] Classer `duplicates` et le futur import côté CRM à cette occasion.

## Audit UX/UI admin (2026-08-17)
Audit navigateur réel (Puppeteer headless, session admin, captures desktop 1440px + mobile 390px) sur les ~27 écrans de l'admin. Verdict : desktop cohérent (recherche/filtres/pagination sur les grosses listes, dashboard avec KPIs, bons états vides) ; mobile cassé sur 100% des écrans testés (cause unique, corrigée ci-dessous). Détail des 6 constats et suivi :
- [x] Contenu admin qui ne se réélargit jamais quand la sidebar est repliée sur mobile (~80px de large utilisable au lieu de ~266px). Cause : `data-controller="sidebar"` n'englobait pas la cible `content` (sibling hors scope Stimulus). Déplacé sur `.admin-layout`. *(commit `ddef87ac`)*
- [x] Noms non cliquables dans les registres de présence (`/admin/attendances`, `/admin/attendance_lists/:id`), y compris le prêteur d'un carnet Pack10. Ajouté `link_to admin_member_path`. *(commit `f280d9b8`)*
- [ ] `/admin/payments/new`, `/admin/payments/:id`, `/admin/memberships/new` sans `person_id` redirigent avec un toast plutôt que d'afficher un formulaire — ressemble à un bug plutôt qu'à une dépréciation assumée vers les flux cotisation/don. À nettoyer ou rediriger proprement.
- [ ] Pas de recherche/filtre sur `/admin/attendances` (922 lignes, 47 pages) ni `/admin/attendance_lists`, alors que membres/paiements en ont déjà.
- [ ] `/admin/exports` hors charte visuelle du reste de l'admin (pas de header/cartes partagés) + faute d'accord dans le texte affiché.
- [ ] Accents manquants en dur sur `/admin/health_reports` ; `<label>` manquants sur `/admin/events/new` (placeholder seul, disparaît à la saisie).

## To verify
- [ ] Confirmer en production qu’aucune `PaymentLine` legacy de don (`item_type: "Payment"`) ne subsiste après la migration déjà appliquée.
- [ ] Confirmer si le crédit prorata de `People::ContributionUpgrader` doit rester ou être remplacé par une remise / offre explicite.
- [ ] Confirmer en base de production l’absence de `payments.user_id` et la présence de `payments.recorded_by_id`.
- [ ] Confirmer qu’aucune donnée de production ne dépend encore de `people.newsletter_subscribed`. *(Côté code déjà migré 2026-08-10 : plus de colonne `people.newsletter_subscribed` en base — `Person#newsletter_subscribed?` délègue à `NewsletterSubscriber` via `PersonPaymentReporting`, writer no-op de compat legacy. Reste à vérifier : uniquement un éventuel usage résiduel côté données/exports en production.)*
- [x] Confirmer que les scripts inline admin restants sont tous couverts par Stimulus. *(Confirmé 2026-08-10 : `grep -rl "<script" app/views/admin` ne remonte plus aucun fichier.)*
- [x] Confirmer les règles métier de refus de suppression `Person` avec paiements, adhésions ou cotisations. *(Confirmé 2026-08-10, nuance vs. l'intitulé : `destroy` dur est bloqué par `has_one :user` / `has_many :account_claims, :memberships, :payments` (`dependent: :restrict_with_error`) — `contributions` est en `dependent: :destroy`, donc ne bloque pas. L'archivage doux (`Person#archive!` / `SoftDeletable`) est bloqué par `has_financial_data?` = `payments.exists? || memberships.exists?(status: :active)`, qui ne teste pas directement les cotisations. Voir `app/models/person.rb:17-24,186-194`.)*
- [x] Confirmer que les exemptions d’auth récentes (`BlogsController#index/show`, `UsersController#unsubscribe_by_token`) sont bien intentionnelles, documentées et couvertes par tests. *(Intentionnelles : blog public + désinscription newsletter par lien email, forcément hors session. Couverture ajoutée 2026-08-10 : `spec/requests/blogs_spec.rb`, `spec/requests/users_unsubscribe_spec.rb`.)*
- [ ] Vérifier le comportement clavier / focus / hash navigation de la FAQ à onglets sur mobile et desktop.
- [ ] Vérifier le rendu réel des horaires compacts sur toutes les vues publiques qui embarquent `shared/_opening_hours` (home, adhésion, autres shells publics).
- [x] Vérifier que la fraîcheur des horaires (`OpeningHour.latest_update_entry.updated_at`, DB) est affichée de façon cohérente partout où elle compte. *(Confirmé 2026-08-10, incohérence réelle : `latest_update_entry` n'est utilisé que dans `become_member.html.erb`, absent de `shared/_opening_hours` donc absent de `home` et `contact_us` qui l'embarquent. Pas corrigé — à traiter comme item séparé si jugé utile.)*

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
- [ ] **Continuer à harmoniser côté admin** *(2026-08-17, suite de l'audit UX/UI ci-dessus)* : côté public, l'harmonisation des primitives visuelles est déjà bien avancée (heroes, shells, cartes) — l'admin est en retard. Constats concrets à traiter :
  - 4 patterns CRUD différents pour la même intention « gérer une petite liste de référence » : types d'adhésion/formules de cotisation (boutons outline), événements (liens texte colorés), conseil d'administration/partenaires (drag-to-reorder sans action visible). À unifier sur un seul composant.
  - Formulaires `address`/`zip_code`/`town` de `Person` dupliqués tels quels dans `admin/members/new`, `edit`, `edit_person` (aucun partagé). À fusionner — occasion naturelle pour brancher l'autocomplete adresse (voir item Later).
  - Breadcrumbs incohérents d'un écran à l'autre (parfois juste 🏠, parfois un crumb « Administration » en plus).
