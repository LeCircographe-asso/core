# Exports CSV — CRM

> **Statut** : en place (code + specs), non déployé
> **Code** : `app/services/exports/`, `Admin::ExportsController#show`
> **Accès** : admin et super_admin (`require_admin_rights`)

## Exports disponibles

| Clé | Grain | Filtre période sur |
|---|---|---|
| `payment_lines` | une ligne par élément payé (payeur + bénéficiaire) | `payments.created_at` |
| `memberships` | une adhésion | `started_at` |
| `contributions` | une cotisation | `purchased_at` |
| `attendances` | une présence | `date` |
| `donations` | un don (donateur + n° de reçu de don, non fiscal) | `payments.created_at` |

URL : `/admin/exports/<clé>.csv?from=AAAA-MM-JJ&to=AAAA-MM-JJ` (bornes optionnelles, incluses).
Fichier : `<clé>_v<version>[_<from>_<to>]_<date du jour>.csv`, UTF-8 avec BOM (Excel), séparateur virgule.

## Faire évoluer un export (les données vont changer)

Les en-têtes sont des clés techniques stables (snake_case anglais), pas des libellés : un outil
(tableur compta, réimport) peut s'y fier.

- **Ajouter une colonne** : la déclarer **à la fin** de la classe, sans changer la version.
- **Renommer, supprimer, réordonner, changer le sens d'une colonne** : incrémenter `export_version`.
  La version apparaît dans le nom du fichier, les consommateurs voient le changement.
- **Nouveau domaine** (ex. événements, dons) : nouvelle sous-classe de `Exports::Base`, ajoutée à
  `Exports::Catalog::ALL` et aux traductions `admin.exports.index.crm_exports.<clé>`.

Le spec `spec/services/exports/catalog_spec.rb` fige la liste exacte des en-têtes par version :
toute modification échoue tant que le spec (et la version si nécessaire) n'est pas mis à jour
consciemment.

## Sécurité / RGPD

- Chaque export est tracé : log `[export.audit] user_id=… export=… version=… from=… to=… rows=…`
  et notification `export.admin` (`ActiveSupport::Notifications`), à brancher sur le futur journal
  d'audit super_admin.
- Les valeurs commençant par `= + - @` sont préfixées d'une apostrophe (injection de formules tableur).
- Les fichiers contiennent des données personnelles : ne pas les stocker hors des outils de l'asso.
