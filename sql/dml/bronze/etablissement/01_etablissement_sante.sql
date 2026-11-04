-- Bronze - etablissement_sante : référentiel des structures de santé (FINESS, SIRET, RPPS).
-- Source : /Volumes/chu/bronze/landing/etablissements/etablissement_sante/ (CSV, séparateur ;)
-- Rafraîchissement complet : le référentiel est une photographie, pas un flux cumulatif.
-- Colonnes de la source conservées telles quelles + colonnes techniques communes.

CREATE OR REPLACE TABLE chu.bronze.etablissement_sante
COMMENT 'Bronze - référentiel des établissements et structures de santé, fidèle au fichier source'
AS
SELECT
  * EXCEPT (_rescued_data),
  _metadata.file_path                                  AS _fichier_source,
  current_timestamp()                                  AS _date_chargement,
  date_format(current_timestamp(), 'yyyyMMdd_HHmmss')  AS _id_lot
FROM read_files('/Volumes/chu/bronze/landing/etablissements/etablissement_sante/',
                format => 'csv', header => true, sep => ';', inferColumnTypes => false);

SELECT count(*) AS lignes, count(DISTINCT identifiant_organisation) AS ids_uniques,
       count(_fichier_source) AS avec_fichier
FROM chu.bronze.etablissement_sante;   -- attendu : 416 665 / 416 665 / 416 665