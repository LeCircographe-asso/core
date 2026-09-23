# Plan de réconciliation `main` ← arbre validé en staging

> **Statut** : révisé | **Rédigé le** : 2026-09-03 | **Révisé le** : 2026-09-23 | **Cible** : aligner `main` (prod) sur l'arbre validé en staging, en gardant la prod en maintenance jusqu'à l'ouverture
> **Pré-requis de lecture** : [docs/operations/deployment.md](../operations/deployment.md), [docs/operations/cold_start.md](../operations/cold_start.md)

## 0. Corrections et mises à jour (à lire en premier)

Les versions précédentes de ce plan contenaient des affirmations fausses ou devenues obsolètes. Elles sont résumées ici pour qu'un relecteur ne s'y fie plus.

### 0.1 — Mise à jour du 2026-09-23

| Point | Situation au 2026-09-23 | Traité en |
| --- | --- | --- |
| Ce plan lui-même | Il n'avait **jamais été commité** : il est resté non suivi, puis rangé dans un stash le 22/09. Il est versionné depuis le 23/09 dans la PR #540 (`chore/cold-start-safe-seeds`). | — |
| Correctifs du cold start « faits » | Ils sont **uniquement sur `chore/cold-start-safe-seeds`** (PR #540, *draft*, CI verte, mergeable). `dev` et `staging` ont toujours le `database.yml` **plat** : réconcilier `main` aujourd'hui produirait une prod qui ne démarre pas. **Premier blocage.** | §6.0 étape 1 |
| `dev` a 6 commits jamais validés en staging | Résolu : les promotions des 21 et 22/09 ont amené la PR #536 (bug reports) et sa migration en staging. `staging` = `dev` moins `fecf389f` (régénération de `db/schema.rb`) + 4 commits de promotion (02/09 → 22/09). | §1 |
| `staging` : `db/schema.rb` | Le fichier de `staging` annonce encore la version `2026_08_26_092957` alors que la migration `20260903140500` y est présente : schéma périmé, corrigé sur `dev` par `fecf389f`. Disparaît à la prochaine promotion. | §6.0 étape 2 |
| Promotion `staging → main` automatisée | `deploy-promote-main.yml` pousse directement sur `main` avec le `GITHUB_TOKEN`. Or le push sur `main` est **restreint à l'équipe Maintainers** (aucune app autorisée) : le push du bot sera probablement refusé. Et sans réconciliation préalable, son `merge --no-ff origin/staging` produirait des centaines de conflits. | §6.0 étape 5 |
| Modes de merge des PR | Au niveau du dépôt, seul « Create a merge commit » est autorisé (squash et rebase désactivés) : la PR de réconciliation ne peut pas être aplatie par erreur. | §6.1 |
| Environnements GitHub | `production` et `staging` : toujours **0 règle de protection**. | §11.3 |
| Garde-fou staging → prod | `deploy-production` se déclenchait sur tout push vers `main` : le promote `staging → main` était contournable, et le merge de réconciliation aurait déployé la prod aussitôt. PR #544 : la prod ne se déploie plus que via `deploy-promote-to-main` (ou un dispatch manuel volontaire). Par ailleurs, *Required reviewers* sur l'environnement `production` n'aurait eu **aucun effet** : aucun job ne déclare `environment: production`. | §6.0, §11.3 |
| Stockage des sauvegardes Litestream | Décision du 23/09 : **Scaleway Object Storage** (`fr-par`) au lieu d'IONOS Object Storage. Le VPS reste chez IONOS. Aucun changement de code : Litestream parle S3, seuls les credentials changent (endpoint `https://s3.fr-par.scw.cloud`). | §5.0 |
| Simulation du flux complet | Rejouée le 23/09 dans un worktree jetable, sans rien pousser : PR #540 → `dev` → `staging` → réconciliation de `main` → cycle de promotion suivant. Arbres identiques à chaque étape, merge à 2 parents, promotion suivante **sans conflit**. | §6.0 |

### 0.2 — Corrections du 2026-09-19

| Affirmation d'origine | Réalité vérifiée le 2026-09-19 | Traité en |
| --- | --- | --- |
| `database.yml` plat = « standard Rails 8, ✅ tourne sur staging » | En `RAILS_ENV=production` seule la base `primary` existait : `production.rb` exige `queue`, `cache.yml` exige `cache`. **L'app ne démarrait pas en prod.** Staging ne le voyait pas : il tournait en `AsyncAdapter` + `MemoryStore`, sans Solid* (`shared.rb` ne définit plus rien). | R7, §4 — corrigé sur `chore/cold-start-safe-seeds` (**pas encore mergé**, voir 0.1) |
| « Chaque correctif d'octobre 2025 a été re-dérivé sur `dev`, en mieux » | Faux pour la structure de bases (`4819755e` sur `main` = structure imbriquée). La vérification fichier par fichier ne suffit pas : il faut **booter la prod** (§2, règle de vérification). | §2 |
| `curl -sI https://lecircographe.fr` → `x-robots-tag: noindex, nofollow` | Faux : la page de maintenance est produite par le middleware, avant le controller, et `SEO_INDEXABLE` est déjà `true`. Attendu : **503 sans `x-robots-tag`**. | §7 |
| Arbre cible = `origin/dev` | Cible = **`origin/staging`** (seul arbre déployé et validé), figée par son SHA au moment du merge. | §2, §6.1 |
| `main` : « 1 review requise » | L'API ne renvoie ni review ni check requis sur `main` (push restreint, pas de force-push). `staging` : aucune protection. | §11.2 |
| Ouverture le 18/09 | Date passée, maintenance toujours voulue : la date est à re-fixer. | §9 |
| `db:prepare` seed « proprement » une base vide | `db/seeds.rb` faisait un `DELETE` sur toutes les tables et créait des comptes `123456` sur toute base fraîche. Corrigé (profil « contenu seul »). | R8, §5.2 |
| Trailer `Co-Authored-By` / `Claude-Session` dans le message de merge | Interdit sur ce projet. Retiré. | §6.1 |

## 1. Constat (au 2026-09-23)

| | `origin/main` | `origin/staging` | `origin/dev` | PR #540 |
| --- | --- | --- | --- | --- |
| Dernier commit | `b7a99d09` — **2025-10-13** | `db0185da` — 2026-09-22 | `fecf389f` — 2026-09-22 | `chore/cold-start-safe-seeds` |
| Écart | 484 commits uniques, 1984 de retard sur `staging` | 4 commits de promotion d'avance sur `dev`, 1 de retard | — | d'avance sur `dev` : correctifs du cold start + ce plan ; 0 de retard |
| Schéma DB (`db/schema.rb`) | `2025_04_20_081208` (Rails 8.0) | `2026_08_26_092957` annoncé, périmé (migration `20260903140500` présente) | `2026_09_03_140500` (Rails 8.1) | idem `dev` |
| Ruby | `3.2.5` | `4.0.1` | `4.0.1` | `4.0.1` |
| Structure DB (`database.yml`) | imbriquée (`primary/cache/queue/cable`) | **plate** (prod ne démarre pas) | **plate** (prod ne démarre pas) | **imbriquée** (production + staging) |
| Seeds | — | destructifs + comptes `123456` | destructifs + comptes `123456` | contenu seul |
| Workflows CI/CD | `01..05-*.yml` (manuels, tests désactivés, `npm install`) | `ci-dev.yml` + `deploy-*.yml` | idem | idem |
| Node/Yarn | présent | supprimé (importmap only) | supprimé | supprimé |

**Les histoires de `main` et de `dev`/`staging` sont parallèles.** Constats à retenir :

- `origin/main` n'a **jamais été réécrite** (`b7a99d09`). La branche `main` **locale** est toujours un faux merge (`405e1886`, jamais poussé) issu d'un `filter-branch` du 18/08 puis d'un `git pull` du 09/09 : **ne jamais partir d'elle.**
- `staging` et `dev` partagent leur histoire depuis la resynchronisation du 18/08 : chaque promotion est un merge `--no-ff` de `dev` dans `staging`, sans réécriture. Leur seule différence de contenu est `db/schema.rb`.
- 299 des 316 commits non-merge de `main` ont un patch identique dans `dev`, sous d'autres SHA : les deux histoires ont été réécrites l'une par rapport à l'autre, d'où 4 merge-bases de décembre 2024 (`git merge-base --all`) et des conflits partout avec un merge classique.
- Les 17 commits de `main` dont le patch est absent de `dev` : issue templates + suppression de `robots.txt`/noindex de mars 2025 (`cdd7593d`), et 16 correctifs d'infra d'octobre 2025 (maintenance, bases Solid*, `SECRET_KEY_BASE`, workflows).

## 2. Principe directeur

**`staging` (arbre validé) est la source de vérité — application ET infrastructure.**

Les ~200 fichiers « présents sur `main`, absents de `dev` » sont du legacy supprimé ou renommé (`BookOfEntry`/`UserMembership`/`Order`/`Product`, migrations `2024*`–`202503*`, `knowledge/*`, `package.json`, assets réorganisés). Rien à conserver.

→ La réconciliation n'est **pas un merge de contenu** mais un **remplacement d'arbre** : `main` adopte l'arbre exact de la cible, dans **un commit de merge à deux parents** pour que les promotions futures `dev → staging → main` redeviennent triviales.

**Cible = `origin/staging`, pas `dev` brut.** Seul `staging` porte un arbre déployé et validé. Tout ce qu'on veut en prod (dont la PR #540) passe d'abord par `dev`, puis est promu en `staging` (workflow `deploy-promote-staging`) et validé avant la réconciliation : voir §6.0.

**Règle de vérification (ajoutée le 2026-09-19).** Comparer des fichiers ne suffit pas : l'erreur `database.yml` est passée à travers. Avant toute PR, **rejouer le boot production en local** sur des fichiers jetables :

```bash
# storage/production*.sqlite3 est git-ignoré ; le supprimer après
SECRET_KEY_BASE_DUMMY=1 RAILS_ENV=production bin/rails db:prepare
SECRET_KEY_BASE_DUMMY=1 RAILS_ENV=production bin/rails runner 'puts [User.count, Faq.count, SolidQueue::Job.count, SolidCable::Message.count].inspect'
```

Attendu : 4 fichiers `production*.sqlite3`, `User.count == 0`, `Faq.count > 0`, aucune erreur de base non configurée.

## 3. Risques

| # | Risque | Gravité | Mitigation |
| --- | --- | --- | --- |
| R1 | **État de la base de prod** : si la prod a été déployée depuis `main`, ses `schema_migrations` suivent la lignée `main`. `db:prepare` de l'image `dev` peut échouer ou migrer à tort. | 🔴 élevée | §5.2 — vérifier le volume `circographe_production_storage` **avant** tout deploy. |
| R2 | **Secrets/variables GitHub** : les workflows attendent `KAMAL_REGISTRY_PASSWORD`, `SSH_PRIVATE_KEY`, `vars.PRODUCTION_SERVER_IP`, `RAILS_MASTER_KEY`. | 🟠 moyenne | §5.1 |
| R3 | **`secret_key_base` en prod** : le garde-fou `.presence ||` n'existe que dans `staging.rb`. | 🟡 faible | §7 / §11.5 |
| R4 | **Premier deploy prod = vrai changement de stack** (Ruby 3.2→4.0, image neuve). | 🟠 moyenne | Staging valide l'arbre ; health-check + rollback auto. |
| R5 | **Branch protection `main`** : aucun check ni review requis (constat 2026-09-19). | 🟠 moyenne | §11.2 |
| R6 | **Perte de l'historique `main`** si `push --force`. | 🟠 moyenne | Merge à 2 parents ; interdire tout `--force`. |
| R7 | **Structure de bases** : prod ne démarrait pas (voir §0). | 🔴 bloquant | Corrigé (commit `fix: use the nested Solid database layout in production`) + spec `spec/config/database_layout_spec.rb` ; staging aligné pour la valider vraiment. |
| R8 | **Seeds destructifs / comptes `123456` en prod** sur toute base fraîche. | 🔴 bloquant | Corrigé : `Seeds::Profile` (contenu seul en prod, `SEED_DEMO=true` refusé), specs. |
| R9 | **Bucket Litestream absent** : pas de section `litestream:` dans `credentials.yml.enc`. Avec `LITESTREAM_REPLICATE_IN_PUMA: true`, Puma s'arrête si Litestream meurt ; l'entrypoint arrête aussi le conteneur sur erreur de restauration. Le premier deploy prod **échoue** tant que le bucket n'est pas configuré. | 🔴 bloquant | §5.0 |
| R10 | **Credentials partagés staging/prod** : un seul `credentials.yml.enc` et un seul `RAILS_MASTER_KEY` pour les deux. Ajouter le bucket prod dedans l'expose au conteneur staging. | 🟠 moyenne | §5.0 |
| R11 | **Maintenance = pas de setup par l'interface** : `/session/new` et `/admin` répondent 503, donc le super-admin ne peut pas saisir le catalogue avant l'ouverture. | 🟠 décision | §9, point ouvert P1 |
| R12 | **La prod n'envoie aucun mail** : le bloc `smtp_settings` de `production.rb` est commenté et les credentials ne contiennent que `mailjet.sandbox` (staging). Mots de passe oubliés, mail de bienvenue (dont celui du premier super-admin), reçus de dons, formulaire de contact, rappels d'adhésion : tout échouera en prod. | 🟠 bloquant à l'ouverture | §5.0 |

## 4. Inventaire « ancien comportement » → équivalent `dev` (checklist de non-régression)

| Comportement prod (octobre 2025, sur `main`) | Équivalent sur `dev` | État |
| --- | --- | --- |
| Mode maintenance avec bypass, healthcheck `/up` toujours ouvert | `app/middleware/maintenance_mode_middleware.rb` (allowlist `/up` + PWA + `/assets/*` + `/robots.txt` ; **plus de bypass admin**) | ✅ |
| `MAINTENANCE_MODE: true` par défaut en prod | `config/deploy.production.yml` → `env.clear.MAINTENANCE_MODE: true` | ✅ (date d'ouverture à re-fixer, §9) |
| Login/admin **bloqués** aussi pendant la maintenance | Comportement `dev` : tout est 503 sauf allowlist | ✅ changement volontaire, **mais voir R11 / P1** |
| `config.hosts.clear` en prod | `config/environments/production.rb` | ✅ |
| SSL redirect exclut `/up` | `config/environments/production.rb` | ✅ |
| `secret_key_base` via `ENV` ou credentials | Défaut Rails ; `.presence` seulement dans `staging.rb` | ⚠️ R3 |
| Assets précompilés dans l'image | `Dockerfile` + `config/deploy.production.yml` | ✅ |
| Puma single-mode (`WEB_CONCURRENCY=0`), SolidQueue in Puma | `config/puma.rb` + `env.clear` | ✅ |
| **Bases Solid\* (cache/queue/cable)** | `config/database.yml` **imbriquée** pour `production` et `staging` + `cable.yml` `connects_to` + `db/*_schema.rb` (dossiers `db/*_migrate/` vides) | ✅ **corrigé le 2026-09-19** (était ❌, voir §0) |
| Seeds au premier boot | `db/seeds.rb` profil « contenu seul » : FAQ, conseil d'administration, partenaires, tables vides seulement ; jamais de comptes ni de catalogue | ✅ **corrigé le 2026-09-19** |
| Non-indexation moteurs de recherche | `X-Robots-Tag: noindex` posé par `ApplicationController#set_robots_header` tant que `SEO_INDEXABLE` est faux ; `robots.txt` en `Allow: /` | ✅ (la page de maintenance ne porte **jamais** ce header, voir §7) |
| `SEO_INDEXABLE` prêt pour le jour J | `config/deploy.production.yml` → `SEO_INDEXABLE: true` | ✅ |
| Sitemap | **absent** du dépôt (ni `public/sitemap.xml`, ni route, ni gem) | ⚠️ à créer avant l'ouverture (§9) |
| Déploiement Kamal prod sur VPS Ionos | `config/deploy.production.yml` + `.github/workflows/deploy-production.yml` | ✅ |
| Disaster recovery volume SQLite | `bin/docker-entrypoint` : `litestream:restore -if-replica-exists`, arrêt du conteneur sur erreur | ✅ **corrigé le 2026-09-19** (le wrapper rake sort toujours en code 0) |
| Premier super-admin | `kamal create_super_admin` → `circographe:create_super_admin` (interactif, mot de passe sans écho, refuse s'il en existe un) | ✅ nouveau |
| `.kamal/hooks/*.sample` | absents — fichiers d'exemple | ➖ ignorer |
| Workflows numérotés `01..05` | remplacés par `ci-dev.yml` + `deploy-*.yml` | ➖ supprimés par le merge |
| `.github/ISSUE_TEMPLATE/*` | absents de `dev` | ⚠️ voir §8 |

## 5. Prérequis (à faire AVANT la PR)

### 5.0 — Bucket Litestream et credentials par environnement — **bloquant (R9, R10)**

1. Créer le bucket **Scaleway Object Storage** (`fr-par`, classe Standard) et une clé d'API d'application IAM **dédiée à la prod** (voir `docs/backup-restore.md` §1).
2. Créer des credentials **séparés** :
   ```bash
   bin/rails credentials:edit --environment production   # config/credentials/production.yml.enc + production.key
   ```
   Y mettre `secret_key_base`, les clés Mailjet **de production** (aujourd'hui seules les clés `mailjet.sandbox` existent, R12 ; il faut aussi décommenter et renseigner `config.action_mailer.smtp_settings` dans `config/environments/production.rb`, sur le modèle de `staging.rb`) et la section `litestream:` (`replica_bucket`, `replica_region`, `replica_endpoint`, `replica_key_id`, `replica_access_key`, `dashboard_username`, `dashboard_password`). Dès que ce fichier existe, la production ne lit **plus** `credentials.yml.enc` : rien ne doit y manquer.
3. Poser `RAILS_MASTER_KEY` = contenu de `production.key` dans l'**environnement GitHub `production`** (pas au niveau organisation), et garder l'ancienne clé pour staging. Le conteneur staging ne peut alors plus déchiffrer les secrets de la prod. `config/credentials/*.key` est déjà git-ignoré.
4. Un bucket ou un préfixe **distinct** pour staging si on veut y répéter la restauration (optionnel).

### 5.1 — Secrets & variables GitHub (org ou repo)

Dépôt : **`LeCircographe-asso/core`** (branche par défaut `dev`). À faire vérifier par un admin de l'orga :

```bash
gh api orgs/LeCircographe-asso/actions/secrets   --jq '.secrets[].name'
gh api orgs/LeCircographe-asso/actions/variables --jq '.variables[].name'
```

- **Secrets** : `RAILS_MASTER_KEY`, `KAMAL_REGISTRY_PASSWORD`, `SSH_PRIVATE_KEY`, `SECRET_KEY_BASE`, `STAGING_PASSWORD`
- **Variables** : `STAGING_SERVER_IP`, `PRODUCTION_SERVER_IP`
- **Déploiement prod** : la PR #544 (promote seul) doit être en staging **avant** le merge de réconciliation, pour que ce merge ne déploie rien tout seul (§6.0).

### 5.2 — État de la base de production (R1) — **bloquant**

Sur le VPS prod (`ssh deploy@$PRODUCTION_SERVER_IP`) :

```bash
docker volume inspect circographe_production_storage
ls -la /var/lib/docker/volumes/circographe_production_storage/_data/
sqlite3 .../production.sqlite3 "SELECT version FROM schema_migrations ORDER BY version DESC LIMIT 3;" 2>/dev/null
sqlite3 .../production.sqlite3 "SELECT count(*) FROM users;" 2>/dev/null
```

Décision :

- **Volume absent / base vide / 0 users** → cas nominal : l'entrypoint tente la restauration Litestream (bucket vide = INFO, on continue), `db:prepare` crée les 4 bases depuis `db/*schema.rb` et lance le seed de contenu.
- **Base avec un schéma lignée `main`** → **ne pas laisser `db:prepare` migrer.** Sauvegarder, puis repartir d'une base fraîche (pré-lancement, pas de données métier à conserver), ou planifier une migration de données.
- **Fichiers `production_cache.sqlite3`, `production_queue.sqlite3`, `production_cable.sqlite3` déjà présents** (image d'octobre 2025 en structure imbriquée) → les **supprimer** : ils sont régénérables et le schéma de `cache` (colonne `expires_at`) est incompatible avec solid_cache 1.0. **Ne jamais toucher `production.sqlite3`.**
- **Litestream** : vérifier que le bucket/chemin de `config/litestream.yml` ne va pas restaurer une vieille base au premier boot.

### 5.3 — Validation staging

Après promotion, staging tourne sur l'arbre cible **avec la structure Solid\* de la prod**. Vérifier :

- dernier run `deploy-staging` **vert**, `https://staging.lecircographe.fr/up` → 200 ;
- répétition du cold start : `bundle exec kamal reset_db -c config/deploy.staging.yml` puis `bundle exec kamal create_super_admin -c config/deploy.staging.yml`, connexion, création d'un admin, saisie d'un type d'adhésion et d'une formule ;
- `ls storage` dans le conteneur : 4 fichiers `staging*.sqlite3`, et les jobs récurrents tournent (`SolidQueue`).

## 6. Procédure de réconciliation (le merge)

### 6.0 — Amorçage : faire passer le flux `dev → staging → main` sans réécrire l'historique

Règle : **chaque changement entre par `dev`**, monte en `staging` par le workflow `deploy-promote-staging` (merge `--no-ff`), puis en `main`. Aucun commit direct sur `staging` ni sur `main`, aucun `push --force`, aucun rebase de branche partagée. La réconciliation de `main` est le **seul** merge fait hors workflow, une seule fois.

| # | Étape | Branche touchée | Mécanisme | Condition pour passer à la suite |
| --- | --- | --- | --- | --- |
| 1 | Sortir la PR #540 du draft, relire, merger dans `dev` ; merger la PR #544 (prod déployée uniquement par le promote) | `dev` | PR, « Create a merge commit » | CI `dev` verte après le merge (`ci-dev` **et** `ci-docker-cache` : exigés par l'étape 2) |
| 2 | Promouvoir `dev → staging` | `staging` | workflow `deploy-promote-staging` | `deploy-staging` vert ; `staging^{tree}` == `dev^{tree}` |
| 3 | Répéter le cold start sur staging (§5.3) : 4 bases `staging*.sqlite3`, super-admin, saisie catalogue | — | `kamal reset_db` + `kamal create_super_admin` | Checklist §5.3 cochée |
| 4 | **Geler** les promotions `dev → staging` jusqu'au merge de la réconciliation, puis réconcilier `main` avec le SHA de staging validé à l'étape 3 (§6.1) | `main` | PR de merge à 2 parents | Prérequis §5.0–5.2 levés ; PR #544 présente dans le SHA de staging validé |
| 5 | Rétablir la promotion automatique `staging → main` | — | Autoriser le bot à pousser sur `main` (ajouter l'app `github-actions` aux restrictions de push) **ou** faire ouvrir une PR par `deploy-promote-main.yml` au lieu de pousser | Premier `deploy-promote-main` réussi, merge sans conflit |

Pourquoi geler à l'étape 4 : la PR de réconciliation fige l'arbre de `staging` à un SHA précis. Si une promotion arrive entre la validation et le merge, la PR ne correspond plus à ce qui a été validé ; il faudrait refaire la branche de réconciliation (jamais la modifier à la main).

Pourquoi la promotion suivante est triviale : après le merge à 2 parents, tout l'historique de `staging` est ancêtre de `main`. Le `merge --no-ff origin/staging` de `deploy-promote-main.yml` n'a plus que les nouveaux commits à appliquer, et `main` ne portant aucun commit propre, il ne peut pas y avoir de conflit.

**Simulation du 2026-09-23** (worktree jetable, rien de poussé) :

| Étape simulée | Résultat |
| --- | --- |
| PR #540 mergée dans `dev` puis promue dans `staging` | arbre `staging` == arbre `dev` |
| `origin/main` + `merge -s ours` + `read-tree -m -u` de ce `staging` | arbre `main` == arbre `staging`, 2 parents |
| Nouveau commit sur `dev` → promotion `staging` → `merge --no-ff` dans `main` (comme `deploy-promote-main`) | aucun conflit ; arbre `main` == arbre `staging` ; diff limité au nouveau commit |
| `origin/main` d'octobre 2025 | toujours ancêtre de `main` (historique conservé) |

### 6.1 — Le merge de réconciliation

Objectif : `main` obtient **l'arbre exact de la cible**, via **un commit de merge à deux parents** (`main` + cible), sans réécrire l'historique. **Tests à blanc réussis le 2026-09-19 et le 2026-09-23** (arbre bit-à-bit identique, 2 parents).

Utiliser un **worktree** (le checkout courant peut contenir des modifications non commitées) et **`origin/main`**, jamais la `main` locale. La cible est **le SHA de `staging` validé à l'étape 3 de §6.0**, pas la référence mouvante `origin/staging` :

```bash
git fetch origin
CIBLE=$(git rev-parse origin/staging)   # à comparer au SHA validé en §6.0 étape 3 ; différent => stop

git worktree add ../circographe-reconcile -b chore/reconcile-main-with-staging origin/main
cd ../circographe-reconcile

# Merge à 2 parents SANS toucher l'arbre pour l'instant
git merge -s ours --no-commit "$CIBLE"

# Remplacer l'index + le worktree par l'arbre de la cible (à l'identique)
git read-tree -m -u "$CIBLE"

git commit -m "chore: reconcile main with staging (staging = source of truth for app + infra)

The main and dev/staging histories diverged in 2024-12. staging carries
the validated tree: vocabulary migration, Node removal, mature CI/CD,
nested Solid databases, content-only production seeds. This merge aligns
main's tree with it, keeping both histories, so that dev -> staging ->
main promotions become trivial again."

# GARDE-FOU : l'arbre DOIT être identique à la cible
git diff --stat "$CIBLE" HEAD                     # => sortie vide obligatoire
[ "$(git rev-parse HEAD^{tree})" = "$(git rev-parse "$CIBLE"^{tree})" ] && echo "arbres identiques"
git log -1 --format='%P' | wc -w                  # => 2 parents
```

Si l'arbre n'est pas identique : **stop**, ne pas pousser.

```bash
git push origin chore/reconcile-main-with-staging
gh pr create --base main --head chore/reconcile-main-with-staging \
  --title "chore: reconcile main with staging" \
  --body "Voir docs/migrations/main_reconciliation_plan.md. Arbre identique à origin/staging (git diff vide). Merge à 2 parents, aucun historique réécrit."
```

**Merge de la PR** : « Create a merge commit » (pas squash, pas rebase).

> ⚠️ Avec la PR #544, le merge sur `main` **ne déploie pas** la prod. Le déploiement est lancé à la main, une fois §5.0 et §5.2 traités (sans bucket, le premier deploy échoue par conception) :
>
> ```bash
> gh workflow run deploy-production.yml --ref main
> ```
>
> Sans la PR #544 dans l'arbre cible, le merge déclencherait `deploy-production.yml` immédiatement : **ne pas merger dans ce cas.**

## 7. Validation post-merge (avant que la prod parte)

Le merge ne déploie rien (PR #544) : relire cette checklist, lancer `deploy-production` à la main (§6.1), puis suivre le run en direct, rollback prêt.

- [ ] Run `deploy-production` : `build-push` OK
- [ ] `deploy` OK (Kamal : image démarrée, healthcheck interne vert)
- [ ] `curl -fsS https://lecircographe.fr/up` → **200**
- [ ] `curl -I https://lecircographe.fr` → **503** avec `Retry-After: 300` (maintenance active)
- [ ] `curl -sI https://lecircographe.fr | grep -i x-robots-tag` → **aucun résultat** : la page de maintenance est produite par le middleware avant le controller, et `SEO_INDEXABLE` est à `true`. *(La version d'origine attendait `noindex, nofollow` : c'était faux.)*
- [ ] `curl https://lecircographe.fr/robots.txt` → 200, `Allow: /`
- [ ] Logs : `seeds de contenu (production)` **une seule fois** (premier boot), aucune ligne de seed aux boots suivants ; pas d'erreur `secret_key_base`, `Blocked hosts`, `Propshaft::MissingAssetError`, ni « database is not configured »
- [ ] Volume : 4 fichiers `production*.sqlite3` ; Litestream réplique (logs sans erreur de credentials/endpoint ; objets visibles dans le bucket)
- [ ] `bundle exec kamal create_super_admin -c config/deploy.production.yml` → super-admin créé (mot de passe non affiché)
- [ ] SolidQueue tourne (jobs récurrents planifiés)
- [ ] R3 : si `SECRET_KEY_BASE` est injecté au runtime, confirmer qu'il n'est pas vide ; sinon porter `.presence ||` dans `production.rb`

Échec ⇒ `bundle exec kamal rollback -c config/deploy.production.yml` (auto sur `health-check` failure). **Le rollback ne défait pas le schéma** : garder les migrations rétro-compatibles.

## 8. Après réconciliation

1. **`main` == cible** : les promotions reprennent le flux `dev → staging → main`. Plus jamais de commit direct sur `staging`/`main` ; un correctif urgent = branche depuis `dev`, PR, promotion.
2. **Templates d'issues** : si l'asso les veut, PR **sur `dev`**. Sinon, rien.
3. **Litestream prod** : confirmer la réplication continue (`LITESTREAM_REPLICATE_IN_PUMA: true`) et tester une restauration vers un fichier temporaire (`docs/backup-restore.md`).
4. Mettre à jour `docs/operations/deployment.md` : retirer « main pas encore resynchronisé », dater la réconciliation.
5. Purger la branche `chore/reconcile-main-with-staging` et le worktree (`git worktree remove ../circographe-reconcile`).
6. **Réaligner la branche locale `main`** sur `origin/main` (`git branch -f main origin/main` depuis une autre branche) pour supprimer le faux merge `405e1886`.

## 9. Ouverture publique — deploy séparé

**Date à re-fixer** (le 18/09 initial est passé). Une fois `main` réconcilié et la prod stable en maintenance, l'ouverture est **un seul changement** :

```yaml
# config/deploy.production.yml
env:
  clear:
    MAINTENANCE_MODE: false   # date d'ouverture
    SEO_INDEXABLE: true       # déjà à true — laisser
```

PR `dev` → `staging` (valider) → `main` → deploy (avec approbation). Ouvrir = un **redeploy complet** : `MAINTENANCE_MODE` est lu au démarrage du conteneur et le fichier-drapeau (`tmp/maintenance.flag`) ne peut qu'**ajouter** de la maintenance, pas la lever.

Avant d'ouvrir :

- [ ] **Sitemap** : créer `sitemap.xml` (aucun n'existe) et le référencer dans `robots.txt` ; puis le soumettre à Search Console.
- [ ] **Catalogue saisi** : types d'adhésion et formules de cotisation créés (voir P1).
- [ ] Un 503 prolongé finit par faire perdre des URL à Google : ne pas laisser la maintenance durer des semaines une fois le site connu des moteurs.

Après :

- [ ] `curl -I https://lecircographe.fr` → 200
- [ ] `x-robots-tag` **absent**
- [ ] Parcours adhésion + paiement + présence de bout en bout

### Point ouvert P1 — saisir le catalogue pendant la maintenance

Les types d'adhésion et formules de cotisation sont saisis par le super-admin/admin (décision du 2026-09-19), mais tant que `MAINTENANCE_MODE` est `true`, `/session/new` et `/admin` répondent 503. Options :

1. **Saisir via `kamal console`** (ou une tâche) pendant la maintenance — aucun changement de code, mais pas d'interface.
2. **Rouvrir un bypass admin** dans `MaintenanceModeMiddleware` (existait sur `main`, supprimé volontairement sur `dev`) — à concevoir avec soin (allowlist par session/IP).
3. **Ouvrir d'abord, avec un accès restreint** : `MAINTENANCE_MODE: false` mais inscription publique désactivée (`PUBLIC_REGISTRATION_ENABLED`), saisir le catalogue, puis annoncer.

À trancher avant §7.

## 10. Rollback global

- **Avant merge PR** : fermer la PR, rien n'a bougé.
- **Après merge, prod KO** : `kamal rollback` (revient à l'image d'octobre 2025 — dégradé mais debout, en maintenance de toute façon). Le schéma de la base n'est pas défait.
- **Base perdue ou corrompue** : `litestream:restore` depuis le bucket (`docs/backup-restore.md`).
- **Annuler la réconciliation** : `git revert -m 1 <sha-du-merge>` sur `main` via PR. **Jamais** `reset --hard` + `push --force` sur `main`.

---

## 11. Pipeline sain — durcissement CI/CD

### 11.1 — État actuel

Le pipeline `dev → staging → main` fonctionne et la logique de garde est correcte **dans les workflows** :

- `ci-dev.yml` : `lint` + `security` (Brakeman + bundler-audit) + `test` (RSpec + couverture ≥ 58 %), filtré par `paths-filter`.
- `ci-docker-cache.yml` : build Docker complet (sans push) à chaque push/PR `dev`.
- `deploy-promote-staging.yml` : refuse de promouvoir si le dernier `ci-dev` **ou** `ci-docker-cache` n'est pas vert ; merge `--no-ff`, déclenche `deploy-staging`, attend son succès.
- `deploy-promote-main.yml` : refuse si le dernier `deploy-staging` n'a pas réussi ; merge `staging`, déclenche `deploy-production`, attend son succès.
- `deploy-staging.yml` / `deploy-production.yml` : build → deploy Kamal → **health-check** `/up` → **rollback auto** sur échec.

### 11.2 — Protection de branches (constat API du 2026-09-19)

| Branche | Protection actuelle | Manque | Correctif |
| --- | --- | --- | --- |
| `dev` | checks requis `autocorrect/lint/test/security` (strict), 0 review, pas de force-push | rien de critique | — |
| `staging` | **aucun check, aucune review, push non restreint**, pas de force-push | un `git push origin staging` manuel court-circuite `deploy-promote-staging` | Restreindre le push à `github-actions[bot]` / Maintainers **ou** exiger un check |
| `main` | **aucun check, aucune review requise** ; push restreint ; pas de force-push ; admins non soumis | une PR jamais passée par la CI peut être mergée ; le merge déclenche un deploy prod | Checks requis `lint`, `test`, `security` ; 1 review |

*(La version d'origine indiquait « 1 review requise » sur `main` : ce n'est pas ce que l'API renvoie.)*

### 11.3 — Environnements GitHub

`production` et `staging` : **0 règle de protection**, et aucun job ne déclare `environment:` : une règle *Required reviewers* n'aurait donc aucun effet en l'état.

Décision du 2026-09-23 (rester simple) : le garde-fou entre staging et prod est le **promote** `deploy-promote-to-main` (confirmation `PROMOTE`, dernier `deploy-staging` vert), rendu obligatoire par la PR #544 (plus de déploiement sur push `main`). Une approbation par environnement reste possible plus tard : ajouter `environment: production` au job `deploy` de `deploy-production.yml`, puis la règle dans *Settings → Environments*.

### 11.4 — Nettoyage (dette du pipeline)

- **Branches mortes d'octobre 2025** à supprimer : `debug-puma-port`, `feature/maintenance-admin-bypass`, `feature/maintenance-mode-solidcache`, `fix-healthcheck-ssl-redirect`, `sync-dev-with-staging`. À examiner aussi : `clean-dev`.
  ```bash
  for b in debug-puma-port feature/maintenance-admin-bypass feature/maintenance-mode-solidcache \
           fix-healthcheck-ssl-redirect sync-dev-with-staging; do
    git push origin --delete "$b"
  done
  ```
- Les workflows `01..05-*.yml` disparaissent de `main` avec la réconciliation. Vérifier ensuite *Settings → Branches → main* : aucun **nom de check requis** ne doit référencer d'anciens jobs.
- `.github/ISSUE_TEMPLATE/*` : voir §8.

### 11.5 — Incohérence mineure à trancher

`deploy-staging.yml` passe `SECRET_KEY_BASE` ; `deploy-production.yml` non (prod = credentials). Avec des credentials de production dédiés (§5.0), la prod porte son propre `secret_key_base` : cette asymétrie devient cohérente. Porter quand même `ENV["SECRET_KEY_BASE"].presence || …` dans `production.rb` si un `SECRET_KEY_BASE` vide peut être injecté (R3).

### 11.6 — Ordre d'exécution recommandé

Les étapes 1, 2 et 8 suivent la séquence d'amorçage de §6.0.

1. Sortir la PR #540 (`chore/cold-start-safe-seeds`) du draft et la merger dans `dev` (CI verte) ; merger la PR #544 (prod déployée uniquement par le promote).
2. Promouvoir `dev → staging` ; **rejouer le cold start sur staging** (§5.3).
3. Admin orga : secrets/variables (§5.1) ; bucket Scaleway + credentials de production (§5.0).
4. État de la base de prod (§5.2) — **bloquant**.
5. Durcir `staging` + `main` (§11.2) (§11.3 : le promote suffit comme garde-fou prod).
6. Supprimer les branches mortes (§11.4).
7. Trancher P1 (§9).
8. Geler les promotions `dev → staging`, PR de réconciliation (§6.1) + validation (§7).
9. Rétablir la promotion automatique `staging → main` (§6.0 étape 5), puis dégeler.
10. Plus tard : ouverture publique (§9).
