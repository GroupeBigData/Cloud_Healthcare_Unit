-- Bronze - cog_departement : départements, Code officiel géographique INSEE au 1er janvier 2026.
-- Source : /Volumes/chu/bronze/landing/referentiels/cog_departement/ (CSV INSEE, séparateur ,)
-- Rafraîchissement complet : un millésime du COG remplace le précédent.

CREATE OR REPLACE TABLE chu.bronze.cog_departement
COMMENT 'Bronze - départements (COG INSEE 2026), fidèle au fichier source'
AS
SELECT
  * EXCEPT (_rescued_data),
  _metadata.file_path                                  AS _fichier_source,
  current_timestamp()                                  AS _date_chargement,
  date_format(current_timestamp(), 'yyyyMMdd_HHmmss')  AS _id_lot
FROM read_files('/Volumes/chu/bronze/landing/referentiels/cog_departement/',
                format => 'csv', header => true, sep => ',', inferColumnTypes => false);