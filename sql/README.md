# Conventions et ordre d'exécution

Toutes les entités du projet suivent les mêmes conventions, quel que soit le membre
qui les a écrites. Un nouvel écart entre deux chaînes est un défaut, pas un choix.

## Nommage des fichiers

`<couche>/<entite>/<NN>_<objet>.sql|.py`

Le chemin porte la couche et l'entité : le nom du fichier ne les répète pas et ne
porte pas d'identifiant de membre (git donne l'auteur). `NN` ordonne les fichiers
d'un même dossier entre eux, pas le pipeline entier — cet ordre est ci-dessous.

## Colonnes techniques Bronze

Les trois colonnes suivantes sont obligatoires dans toute table Bronze :

| Colonne            | Type      | Contenu                                           |
|--------------------|-----------|---------------------------------------------------|
| `_fichier_source`  | STRING    | `_metadata.file_path`, jamais un littéral codé    |
| `_date_chargement` | TIMESTAMP | `current_timestamp()` au moment du chargement     |
| `_id_lot`          | STRING    | `yyyyMMdd_HHmmss`, identique pour toute une exécution |

Les couches Silver s'en servent pour dédoublonner (`ORDER BY _date_chargement DESC`)
et pour tracer l'origine des rejets.

Le mode de chargement, lui, dépend de la source et reste un choix par entité :
les extractions PostgreSQL et le fichier d'hospitalisation sont des instantanés
(rafraîchissement complet), les campagnes de satisfaction sont cumulatives
(`COPY INTO`, qui ignore les fichiers déjà chargés).

## Rejets Silver

Une seule table pour tout le groupe : `chu.silver.rejets`
(voir [dml/silver/00_rejets.sql](dml/silver/00_rejets.sql) pour le schéma et le
vocabulaire des règles). Pas de table `rejets_<entite>`.

Chaque script Silver efface ses propres rejets avant de les réécrire, puis charge
les lignes valides avec un `WHERE` exactement complémentaire : aucune ligne ne peut
être à la fois rejetée et chargée, ni disparaître sans trace.

## Ordre d'exécution

```
sql/00_setup/01_catalogue.sql
sql/00_setup/02_droits_equipe.sql

Bronze   sql/dml/bronze/patient/01_patient.py
         sql/dml/bronze/diagnostic/01_diagnostic.py
         sql/dml/bronze/hospitalisation/01_hospitalisation.sql
         etl/bronze/bronze_satisfaction.py          (les 18 tables de satisfaction)

Silver   sql/dml/silver/00_rejets.sql               (avant tout autre script Silver)
         sql/dml/silver/patient/01_patient.sql
         sql/dml/silver/diagnostic/01_diagnostic.sql
         sql/dml/silver/hospitalisation/01_hospitalisation.sql
         sql/dml/silver/satisfaction/01_ref_region_esatis.sql
         sql/dml/silver/satisfaction/02_satisfaction_esatis.sql
         sql/dml/silver/satisfaction/03_ref_seuils_esatis.sql

Gold     sql/dml/gold/dim/dim_patient/01_dim_patient.sql
         sql/dml/gold/dim/dim_diagnostic/01_dim_diagnostic.sql
         sql/dml/gold/dim/dim_temps/01_dim_temps.sql
         sql/dml/gold/fait/fait_hospitalisation/01_fait_hospitalisation.sql
         sql/ddl/gold/contraintes_gold.sql          (après les tables Gold)

Qualité  sql/quality/controles_qualite.sql
```

Les fichiers Bronze d'une même couche sont indépendants entre eux ; l'ordre au sein
d'une couche n'importe que pour `00_rejets.sql` et `contraintes_gold.sql`.

`sql/ddl/gold/fait_satisfaction.sql` et `sql/prototypes/` ne font pas partie de la
chaîne : le premier est une proposition de contrat Gold à valider, le second un
prototype d'indicateur sur Silver.
