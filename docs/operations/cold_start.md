# Cold start & seeds — dev / staging / production

> **Statut** : stable | **Dernière vérification** : 2026-09-19
> **Sources de vérité** : `bin/docker-entrypoint`, `db/seeds.rb`, `app/services/seeds/profile.rb`, `config/database.yml`, `lib/tasks/create_super_admin.rake`.

Principe : **la production n'est jamais reseedée.** Une base de production ne reçoit que des données saisies par des humains (admin, membres) ou restaurées depuis Litestream. Un déploiement depuis staging n'apporte que du code et des migrations.

## 1. Trois profils de seeds

| Environnement | `db/seeds.rb` exécute | Comptes |
| --- | --- | --- |
| `development`, `test` | démo complète : remise à zéro de toutes les tables, comptes système, catalogue, événements, FAQ/CA/partenaires, population aléatoire | `super-admin@rails.com` / `123456`… |
| `staging` (défaut) | **contenu seul** : FAQ, conseil d'administration, partenaires — uniquement si leur table est vide | aucun |
| `staging` + `SEED_DEMO=true` (alias `reset_db_demo`) | démo complète, pour tester l'UX | idem dev |
| `production` | **contenu seul**, comme staging | aucun ; `SEED_DEMO=true` **lève une erreur** |

Le profil est choisi par `Seeds::Profile.demo?`. Le contenu seul ne supprime jamais rien : une table déjà remplie est ignorée (`= faq.rb ignoré : N Faq déjà présent(s)`), donc un `db:seed` manuel en production reste inoffensif.

Types d'adhésion (`MembershipType`) et formules de cotisation (`ContributionFormula`) ne sont **pas** seedés en staging/production : le super-admin ou un admin les saisit depuis l'interface pour initialiser l'application.

`db:prepare` (lancé par `bin/docker-entrypoint` à chaque boot) ne seed que lorsqu'il **crée** la base principale. Sur une base existante il applique seulement les migrations en attente.

## 2. Premier boot de production

1. `bin/docker-entrypoint` : si `storage/production.sqlite3` est absent, `litestream:restore -if-replica-exists`.
   - bucket joignable mais vide (tout premier déploiement) → INFO, on continue ;
   - bucket non configuré / injoignable / clés invalides → le conteneur **s'arrête** (la tâche Ruby sort en code 0 même en erreur, l'entrypoint lit donc sa sortie) ;
   - réplique trouvée → base restaurée, aucun seed.
2. `db:prepare` crée `primary` + `cache` + `queue` + `cable` depuis `db/*schema.rb` puis lance le seed de contenu.
3. `bundle exec kamal create_super_admin -c config/deploy.production.yml` (voir §3).

**Pré-requis** : un bucket IONOS et une section `litestream:` dans les credentials (`bin/rails credentials:edit`) avant le premier déploiement.

## 3. Créer le premier super-admin (SSH)

```bash
bundle exec kamal create_super_admin -c config/deploy.production.yml   # ou deploy.staging.yml
```

La tâche `circographe:create_super_admin` demande email, prénom, nom, puis le mot de passe **sans écho** (12 caractères minimum, confirmation). Elle passe par `People::Register` (Person + User liés), refuse de tourner si un super-admin existe déjà, et n'écrit le mot de passe ni dans l'environnement, ni dans l'historique du shell, ni dans le dépôt. Les admins suivants se créent depuis l'interface d'administration.

`circographe:seed_system_accounts` (comptes `123456`) est interdite en production.

## 4. Structure des bases

`production` utilise la structure **imbriquée** (`primary`, `cache`, `queue`, `cable`) exigée par Solid Cache / Solid Queue / Solid Cable. Seule `storage/production.sqlite3` est répliquée par Litestream ; les trois autres se régénèrent depuis `db/cache_schema.rb`, `db/queue_schema.rb`, `db/cable_schema.rb` (les dossiers `db/*_migrate/` restent vides).

En structure plate (`production_cache:` au premier niveau), Rails prend ces clés pour des environnements distincts et l'app ne démarre pas : `spec/config/database_layout_spec.rb` protège ce point.

**Staging n'est pas encore aligné** : il reste en structure plate et n'utilise pas Solid Cache / Solid Queue en base. Il ne valide donc pas la couche Solid* de la production.

## 5. Répétition sur staging

```bash
bundle exec kamal reset_db -c config/deploy.staging.yml           # db:reset : schema:load + seeds de contenu
bundle exec kamal create_super_admin -c config/deploy.staging.yml
```

Se connecter, créer un admin depuis l'interface, saisir un type d'adhésion et une formule. C'est la procédure exacte à rejouer en production.
