-- Bronze - activite_professionnel_sante : lien professionnel <-> structure d'exercice.
-- Source : /Volumes/chu/bronze/landing/etablissements/activite_professionnel_sante/ (CSV, séparateur ;)
-- Rafraîchissement complet : photographie du référentiel.

CREATE OR REPLACE TABLE chu.bronze.activite_professionnel_sante
COMMENT 'Bronze - activités des professionnels de santé par structure, fidèle au fichier source'
AS
SELECT
  * EXCEPT (_rescued_data),
  _metadata.file_path                                  AS _fichier_source,
  current_timestamp()                                  AS _date_chargement,
  date_format(current_timestamp(), 'yyyyMMdd_HHmmss')  AS _id_lot
FROM read_files('/Volumes/chu/bronze/landing/etablissements/activite_professionnel_sante/',
                format => 'csv', header => true, sep => ';', inferColumnTypes => false);