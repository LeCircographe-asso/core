# Plan de réconciliation `main` ← arbre validé en staging

> **Statut** : révisé | **Rédigé le** : 2026-09-03 | **Révisé le** : 2026-09-19 | **Cible** : aligner `main` (prod) sur l'arbre validé en staging, en gardant la prod en maintenance jusqu'à l'ouverture
> **Pré-requis de lecture** : [docs/operations/deployment.md](../operations/deployment.md), [docs/operations/cold_start.md](../operations/cold_start.md)

## 0. Corrections du 2026-09-19 (à lire en premier)

La première version de ce plan contenait des affirmations fausses. Elles sont corrigées ci-dessous ; les résumer évite qu'un relecteur s'y fie encore.

| Affirmation d'origine | Réalité vérifiée le 2026-09-19 | Traité en |
| --- | --- | --- |
| `database.yml` plat = « standard Rails 8, ✅ tourne sur staging » | En `RAILS_ENV=production` seule la base `primary` existait : `production.rb` exige `queue`, `cache.yml` exige `cache`. **L'app ne démarrait pas en prod.** Staging ne le voyait pas : il tournait en `AsyncAdapter` + `MemoryStore`, sans Solid* (`shared.rb` ne définit plus rien). | R7, §4 — corrigé sur `chore/cold-start-safe-seeds`, staging aligné |
| « Chaque correctif d'octobre 2025 a été re-dérivé sur `dev`, en mieux » | Faux pour la structure de bases (`4819755e` sur `main` = structure imbriquée). La vérification fichier par fichier ne suffit pas : il faut **booter la prod** (§2, règle de vérification). | §2 |
| `curl -sI https://lecircographe.fr` → `x-robots-tag: noindex, nofollow` | Faux : la page de maintenance est produite par le middleware, avant le controller, et `SEO_INDEXABLE` est déjà `true`. Attendu : **503 sans `x-robots-tag`**. | §7 |
| Arbre cible = `origin/dev` | `dev` a 6 commits jamais validés en staging (PR #536 + migration). Cible = **`origin/staging`**. | §2, §6 |
| `main` : « 1 review requise » | L'API ne renvoie ni review ni check requis sur `main` (push restreint, pas de force-push). `staging` : aucune protection. | §11.2 |
| Ouverture le 18/09 | Date passée, maintenance toujours voulue : la date est à re-fixer. | §9 |
| `db:prepare` seed « proprement » une base vide | `db/seeds.rb` faisait un `DELETE` sur toutes les tables et créait des comptes `123456` sur toute base fraîche. Corrigé (profil « contenu seul »). | R8, §5.2 |
| Trailer `Co-Authored-By` / `Claude-Session` dans le message de merge | Interdit sur ce projet. Retiré. | §6 |

## 1. Constat

| | `origin/main` | `origin/staging` | `origin/dev` |
| --- | --- | --- | --- |
| Dernier commit | `b7a99d09` — **2025-10-13** | `84cbb91a` — 2026-09-03 | `2decfd2a` — 2026-09-09 |
| Écart avec `dev` | 484 commits uniques (vs 1972) | 2 commits de promotion, 6 de retard | — |
| Schéma DB | `2025_04_20_081208` (Rails 8.0) | idem `dev` moins la migration `20260903140500` | `2026_09_03_140500` (Rails 8.1) |
| Ruby | `3.2.5` | `4.0.1` | `4.0.1` |
| Structure DB | imbriquée (`primary/cache/queue/cable`) | plate → **alignée** sur la branche de travail | plate → **corrigée** (production + staging) |
| Workflows CI/CD | `01..05-*.yml` (manuels, tests désactivés, `npm install`) | `ci-dev.yml` + `deploy-*.yml` | idem |
| Node/Yarn | présent | supprimé (importmap only) | supprimé |

**Les histoires de `main` et `dev` sont parallèles.** Constats à retenir :

- `origin/main` n'a **jamais été réécrite** (`b7a99d09`). La branche `main` **locale** est un faux merge (`405e1886`, jamais poussé) issu d'un `filter-branch` du 18/08 puis d'un `git pull` du 09/09 : **ne jamais partir d'elle.**
- 299 des 316 commits non-merge de `main` ont un patch identique dans `dev`, sous d'autres SHA : les deux histoires ont été réécrites l'une par rapport à l'autre, d'où 4 merge-bases (`git merge-base --all`) et des conflits partout avec un merge classique.
- Les 17 commits de `main` dont le patch est absent de `dev` : issue templates + suppression de `robots.txt`/noindex de mars 2025 (`cdd7593d`), et 16 correctifs d'infra d'octobre 2025 (maintenance, bases Solid*, `SECRET_KEY_BASE`, workflows).

## 2. Principe directeur

**`staging` (arbre validé) est la source de vérité — application ET infrastructure.**

Les ~200 fichiers « présents sur `main`, absents de `dev` » sont du legacy supprimé ou renommé (`BookOfEntry`/`UserMembership`/`Order`/`Product`, migrations `2024*`–`202503*`, `knowledge/*`, `package.json`, assets réorganisés). Rien à conserver.

→ La réconciliation n'est **pas un merge de contenu** mais un **remplacement d'arbre** : `main` adopte l'arbre exact de la cible, dans **un commit de merge à deux parents** pour que les promotions futures `dev → staging → main` redeviennent triviales.

**Cible = `origin/staging`, pas `dev` brut.** `dev` porte 6 commits (PR #536 « bug reports » + une migration) jamais déployés en staging. Si on les veut en prod : promouvoir d'abord `dev → staging` (workflow `deploy-promote-staging`), valider, puis réconcilier.

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

1. Créer le bucket IONOS Object Storage et une clé d'accès **dédiée à la prod** (voir `docs/backup-restore.md`).
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
- **Environnement GitHub `production`** : 0 règle de protection au 2026-09-19 → ajouter *Required reviewers* (§11.3) **avant** le merge : pousser sur `main` déclenche `deploy-production`.

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

Objectif : `main` obtient **l'arbre exact de la cible**, via **un commit de merge à deux parents** (`main` + cible), sans réécrire l'historique. **Test à blanc réussi le 2026-09-19** (arbre bit-à-bit identique, 2 parents).

Utiliser un **worktree** (le checkout courant peut contenir des modifications non commitées) et **`origin/main`**, jamais la `main` locale :

```bash
git fetch origin
CIBLE=origin/staging

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

> ⚠️ Le push sur `main` **déclenche `deploy-production.yml`**. Poser d'abord *Required reviewers* sur l'environnement `production` (§11.3) et avoir traité §5.0 et §5.2 : sans bucket, le premier deploy échoue par conception.

## 7. Validation post-merge (avant que la prod parte)

Avec *Required reviewers*, le deploy attend une approbation : c'est le moment de relire cette checklist. Sans cela, surveiller le run en direct, rollback prêt.

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

`production` et `staging` : **0 règle de protection**. Recommandé **au moins jusqu'à l'ouverture** :

- `production` → **Required reviewers** (1 mainteneur) : un humain approuve chaque déploiement prod. C'est aussi ce qui laisse le temps de dérouler §5.2 et §7.
- Optionnel : `wait timer` de quelques minutes.

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

1. Valider et pousser `chore/cold-start-safe-seeds` vers `dev` (PR, CI verte).
2. Promouvoir `dev → staging` ; **rejouer le cold start sur staging** (§5.3).
3. Admin orga : secrets/variables (§5.1) ; bucket IONOS + credentials de production (§5.0).
4. État de la base de prod (§5.2) — **bloquant**.
5. Durcir `staging` + `main` (§11.2) et poser *Required reviewers* sur `production` (§11.3).
6. Supprimer les branches mortes (§11.4).
7. Trancher P1 (§9).
8. PR de réconciliation (§6) + validation (§7).
9. Plus tard : ouverture publique (§9).
