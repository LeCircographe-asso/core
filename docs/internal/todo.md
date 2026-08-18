# TODO — Le Circographe

> **Statut** : internal
> **Public cible** : équipe dev
> **Dernière vérification** : 2026-08-18 (DRY consolidation A-F + backlog G)
> **Sources de vérité** : `app/`, historique git, `docs/`.

*Audit continu : revu 2026-05-06 (12 commits), complété 2026-08-10 (audit doc), mis à jour 2026-08-18 (DRY pass + backlog). Prochaine passe : items rapides sécurité (rate limiting, CSP).*

## Now
- [x] **Paiements —** Les écrans admin (`Admin::PaymentsController#destroy`, `Admin::Members::PaymentsController#destroy`) passent déjà par `People::PaymentCanceller` (annulation `status: cancel`, pas de suppression ligne). `Payment#destroy` est désormais verrouillé par défaut ; le hard delete résiduel passe par une intention explicite `Payment#hard_delete!` pour les usages techniques/tests.
- [x] Ajouter les métadonnées de reçu de don : numéro, date d’émission, émetteur. *(`DonationReceipt` + `People::DonationReceiptIssuer` ; numéro séquentiel par année civile, émetteur figé à l'émission via `ENV["ASSOCIATION_RECEIPT_ISSUER"]`, voir `docs/payments.md` §4.4. Couche données uniquement — pas d'action admin ni de PDF, voir item suivant.)*

## Sécurité (2026-08-17)
- [ ] **Audit sécurité complet (prod + staging + code)** (2026-08-18) : passe dédiée au-delà des points déjà listés ci-dessous — revue systématique code (Brakeman approfondi, dépendances, gestion des secrets, mass assignment, validations upload ActiveStorage), configuration prod (`config/environments/production.rb`, `config/deploy.yml`, headers de sécurité, TLS/HSTS réel), et staging (`StagingAuth` middleware, `config.hosts.clear` en `staging.rb` mérite un second regard). Sert de filet avant la mise en place de CSP/Permissions-Policy déjà trackées ci-dessous.
- [ ] **Vérifier la conformité des flux sensibles d'authentification** (2026-08-18) : reset password (`PasswordsController`), changement d'email, création de session — contre les pratiques 2026 (expiration de token, protection contre l'énumération d'email, invalidation de session à la modification de mot de passe/email, notification email du changement, normes OWASP ASVS niveau applicable à une asso). Lié à l'item rate limiting déjà présent ci-dessous — à traiter ensemble plutôt qu'en doublon.
- [x] Déjà en place *(pour référence, ne pas dupliquer)* : rate limiting login public+admin (`rate_limit` natif Rails 8, `SessionsController`/`Admin::SessionsController`), `force_ssl`+`assume_ssl` (HSTS) en prod, Brakeman + bundler-audit en CI (`.github/workflows/ci-dev.yml`), `master.key`/`credentials.yml.enc` correctement gitignorés/chiffrés.
- [ ] **Rate limiting** manquant sur `PasswordsController` (reset), `AccountClaimsController` (revendication compte), `RegistrationsController` (inscription). **Quick win**: copier pattern Rails 8.1 `rate_limit to:/within:` de `SessionsController`. Cmd: `grep -A2 "rate_limit" app/controllers/sessions_controller.rb`.
  - [ ] `create` (POST) — évite énumération email + brute force password reset
  - [ ] `RegistrationsController#create` (POST) — limite signup bots
- [ ] **Content-Security-Policy** : stub commenté. **Quick win**: Rails 8.1 DSL `policy.default_src :self` + allow CDN (jsdelivr, cloudflare). Ref: `config/initializers/content_security_policy.rb`.
  - [ ] Décommenter → `default_src :self; script_src :self :unsafe_inline; style_src :self cdn.jsdelivr.net`
  - [ ] Test : DevTools Console → pas de CSP violations
- [ ] **Permissions-Policy** : créer `config/initializers/permissions_policy.rb` (Rails 8.1 standard). **Quick win**: 5 lignes, désactiver par défaut. Ref: `Rails::Application.config.permissions_policy`.
  - [ ] Template: `policy.camera :none; microphone :none; geolocation :none; payment :self`
- [ ] **Session timeout par inactivité** (idée 2026-08-18) : contexte multi-utilisateur physique (PC partagé asso). Forcer re-authentification (pas déconnexion silencieuse) après inactivité — admin/super_admin 15min, volunteer 30min, web_visitor sans limite. Middleware check `Session.updated_at`, redirect vers form re-auth pré-rempli, redirection vers page d'avant après succès. Complexité modérée (2-3h), dépiloter après structuration accounts + emails par rôle.
- [ ] **Mise à jour dépendances sécurité (bundler-audit)** (2026-08-18) : 4 vulnérabilités HIGH trouvées.
  - [ ] concurrent-ruby 1.3.6 → 1.3.7 (CVE-2026-54904 AtomicReference livelock)
  - [ ] faraday 2.14.1 → 2.14.3 (CVE-2026-54297 DoS via nested params)
  - [ ] view_component 4.8.0 → 4.12.0 (CVE-2026-54498 HTML-Safety bypass)
  - [ ] websocket-driver 0.8.0 → 0.8.2 (CVE-2026-61666 DoS via malformed Host)
  - [ ] 9 gems Medium/Low priority aussi (crass, loofah, net-imap, sqlite3, etc.)
  - [ ] Cmd: `bundle update concurrent-ruby faraday view_component websocket-driver` + test suite
- [ ] Confirmer que Brakeman/bundler-audit font échouer la CI en cas d'alerte (pas juste un log silencieux).
- [ ] *(lien, déjà trackée en `Later`)* RGPD anonymisation `Person`/`User` — item conformité/sécurité, pas dupliqué ici.

## Backup base de données prod (2026-08-17)
- [ ] **Volume Kamal** `circographe_storage` (SQLite + Active Storage) — **aucun mécanisme configuré**. Choisir : **Litestream** (Rails 8 standard, continu → S3/Backblaze) ou snapshot planifié (cron).
  - **Recommandé : Litestream** — ref Rails 8.1 `rails new --database=sqlite3 --skip-sqlite-backup` (Litestream opt-in). `config/deploy.yml` : ajouter accessory + `DATABASE_URL` env.
  - [ ] Binaire Litestream dans Dockerfile (`apt-get install litestream`)
  - [ ] Kamal secret : S3 endpoint + credentials
  - [ ] Test restauration : `litestream restore -o /tmp/test.db s3://bucket/path` (prod jamais testé = cassé)
  - [ ] Doc: `docs/backup-restore.md`

## Mailer transactionnel (2026-08-18)
- [ ] **Brancher un mailer transactionnel en prod (Jetmail)** : `smtp_settings` commenté en prod, aucun envoi réel configuré (voir constat ci-dessus). Prévoir clés API/SMTP Jetmail en secret Kamal (`.kamal/secrets`) + `credentials.yml.enc`, jamais en clair. Vérifier aussi la config staging (`delivery_method: :smtp` sans `smtp_settings` visible).

## Performance (2026-08-18)
- [ ] **Passe de performance** — Rails 8.1 stack (SolidCache, Propshaft, SQLite). Priorités:
  - [ ] **N+1 queries**: `gem "bullet", :require => false` en dev. Cmd: `grep -r "include_" spec/requests/ | wc -l` (benchmark current eager-loading usage).
  - [ ] **SolidCache**: `config.cache_store` actuellement ? Vérifier prod config. Ref: `Rails.cache.write/read` dans services.
  - [ ] **DB indexes**: `attendances`, `attendance_lists` (recherche nom/date). Cmd: `rails db:show_indexes`.
  - [ ] **Assets**: Propshaft + Tailwind → `app/assets/builds/` size. DevTools → Network → CSS/JS bytes.
  - [ ] **Public pages latency**: `/home`, `/become_member` → benchmark baseline (New Relic ou simple `curl -w @timer.txt`).
  - **Next**: profile en prod avec `rack-mini-profiler` (require opt-in).

## Next safe steps
- [x] **Présence directe depuis la fiche membre** *(fait 2026-08-10)* : action « Marquer présent aujourd'hui » sur `Admin::Members::MemberActionsComponent` (visible si adhésion Cirque active), ouvrant `Admin::Members::AttendancesController#new/create` dans un turbo frame sur la fiche membre. Réutilise le service `AttendanceManagement::CheckInService`, déjà écrit et testé mais jamais branché nulle part (même trouvaille que les partials orphelins ci-dessous) — complété d'un garde-fou de prêt plutôt que d'un nouveau service. Remplace les partials orphelins jamais reliés à une route : `_attendance_contribution_confirmation`, `_attendance_direct_confirmation`, `_attendance_contribution_options`, `_attendance_success` (supprimés). Cas « prêt de carnet » couvert : un Pack10 actif avec séances restantes peut couvrir la présence d'une autre personne si **cette personne** (pas le prêteur) a une adhésion Cirque active (`Contribution#lendable_to?`, distinct de `#can_use?` qui teste le propriétaire) ; recherche inline du prêteur par nom. Traçabilité : badge « Carnet de X » sur `admin/attendance_lists` quand `contribution.person != attendance.person`. Bonus : le flag `record_attendance` de `People::ContributionCreator` (déclaré mais jamais utilisé) est maintenant câblé — achat de cotisation + présence en une seule action, case à cocher sur `admin/contributions/new`.
- [ ] **Ajouter action admin génération/réenvoi reçu de don** — dépend `DonationReceipt` (fait 2026-08-10). **Quick win**: 
  - [ ] View: `/admin/donations/:id/receipt` (lien bouton "Éditer reçu" + "Renvoyer par email")
  - [ ] Service: `People::DonationReceiptGenerator` (render template → PDF ou HTML)
  - [ ] Mailer: `DonationMailer#receipt_email` (dépend Jetmail, voir section Mailer)
  - Ref: `Payment#hard_delete!` pattern pour intention explicite.
- [x] Documenter explicitement dans la doc d’architecture que `Person#renew_membership!` est le dernier gros workflow conservé sur le modèle avant une extraction éventuelle (mentions déjà présentes : `docs/domain_model.md`, `docs/glossary.md`, `docs/domain/business_logic.md`).
- [ ] **Consolidation DRY des shells / layouts Tailwind (chantier continu)** — effort de maintenabilité/SOLID réconduit à chaque intervention future sur l'admin ou les pages publiques.
  - [x] (2026-08-18) **A** : Legal page wrapper (`terms`, `privacy_policy`) → `shared/_legal_page_shell.html.erb`
  - [x] (2026-08-18) **B** : Scroll anchor offsets (`news`, `contact_us`) → unified `public-anchor-section`
  - [x] (2026-08-18) **C** : Reorderable lists (3× duplication `faqs`, `board_members`, `partners`) → `_sortable_list`, `_sortable_row`, breadcrumbs rendering
  - [x] (2026-08-18) **D** : Breadcrumb consistency (4 views + 2 controllers) → uniform "Administration" prefix, remove legacy exceptions
  - [x] (2026-08-18) **E** : Row action buttons (3 styles) → unified `_row_actions.html.erb` thin-border style
  - [x] (2026-08-18) **F** : Address form duplication (`edit`/`edit_person` members) → `_address_fields.html.erb`, fixes A11y regression
  - [ ] *(À déterminer)* **G+** : Autres patterns identifiés futurs (screens non encore auditées, opportuniste)
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
- [ ] **Hub d'événements admin en temps réel** *(idée 2026-08-18)* : le dashboard admin devrait recevoir en direct les événements métier (nouvel adhérent, nouveau paiement, nouvel événement créé, nouvelle cotisation payée, etc.) plutôt qu'un rechargement manuel. Pistes de stack déjà en place : Turbo Streams + `ActiveSupport::Notifications` (déjà le pattern d'instrumentation des services) ou SolidCable. À cadrer avant implémentation : quels événements exactement, où ils s'affichent (dashboard seul ou notification globale), rétention.
- [ ] **Système de visualisation de logs pour super admin** *(idée 2026-08-18)* : écran admin listant les actions sensibles — qui a fait quoi, modifications inline compta, accès refusés/tentatives, erreurs métier. `PaymentAuditLog` (voir constat ci-dessus) est une base partielle à généraliser plutôt qu'à dupliquer : étendre le pattern à d'autres modèles sensibles (`Membership`, `Contribution`, changements de rôle `User`) + écran de consultation/filtre réservé super_admin (`require_super_admin` déjà dans `Admin::BaseController`).
- [ ] **PWA — Investigations fonctionnalités avancées** *(idée 2026-08-18)* : cadrer et implémenter progressivement les capacités PWA pour améliorer l'expérience mobile et desktop. Points d'investigation : (1) notifications natives (téléphone + desktop) via Web Push API + Service Worker ; (2) mode hors-ligne (cache Strategy, sync en arrière-plan via Background Sync API) ; (3) installation native (manifest.json amélioré, splashscreen, icônes multiples, theme colors) ; (4) partage natif (Web Share API) ; (5) actions de notification cliquables (action buttons, badges compteurs). Stack actuelle : `app/javascript/service_worker.js` existe mais est minimal. Pistes : `importmap` actuels (pas de Node → choix de libs avec soin), Service Worker Workbox vs. homemade, Firebase Cloud Messaging vs. VAPID keys custom Rails + Solid stack (SolidCable podrait servir de base pour push temps réel). À cadrer avant implémentation : priorités utilisateur, support navigateur cible, coûts d'infrastructure (APNS/FCM vs. custom), impact perf Service Worker.

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
- [x] `/admin/payments/new`, `/admin/payments/:id`, `/admin/memberships/new` sans `person_id` redirigent avec un toast plutôt que d'afficher un formulaire — ressemble à un bug plutôt qu'à une dépréciation assumée vers les flux cotisation/don. À nettoyer ou rediriger proprement. *(Nuance post-audit : `new` et `create` paiements sont déjà désactivés côté UI (bouton grisé + raison affichée), route `new` était dead code — supprimée. `show` paiements redirige maintenant vers l'index filtré sur la personne du paiement, avec ancrage sur la ligne. `memberships/new` comportement défensif correct, pas de changement.)*
- [x] Pas de recherche/filtre sur `/admin/attendances` (922 lignes, 47 pages) ni `/admin/attendance_lists`, alors que membres/paiements en ont déjà. *(Attendances : ajout recherche par nom/email personne, event, date. AttendanceLists : 4 tuiles cliquables par type (Tous / Entraînement / Événement / Réunion), recherche par nom, filtre mois/tri date/statut, pagination 20 items.)*
- [x] `/admin/exports` hors charte visuelle du reste de l'admin (pas de header/cartes partagés) + faute d'accord dans le texte affiché. *(Réécriture sur gabarit `admin-page-header` + grille de cartes (newsletter subscribers + tous utilisateurs). Textes via i18n.)*
- [x] Accents manquants en dur sur `/admin/health_reports` ; `<label>` manquants sur `/admin/events/new` (placeholder seul, disparaît à la saisie). *(Health_reports : titre/sous-titre via i18n existante, accents corrigés in-place (intégrité, vérifications, détecté, données, téléphone, incohérent, limité à). Events/new : labels `form.label` ajoutés avant chaque champ.)*

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
