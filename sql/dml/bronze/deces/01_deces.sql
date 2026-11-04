-- Bronze - deces : fichier INSEE des personnes décédées, anonymisé en local avant envoi.
-- Source : /Volumes/chu/bronze/landing/deces/deces/ (CSV, séparateur ;)
-- Contenu : sexe, annee_naissance, date_deces, departement_deces (noms supprimés,
-- 213 040 doublons retirés en préparation locale). Période : 1882 - mars 2020.
-- Rafraîchissement complet : le fichier est une photographie.

CREATE OR REPLACE TABLE chu.bronze.deces
COMMENT 'Bronze - décès INSEE (1882-2020), anonymisés en local, fidèles au fichier envoyé'
AS
SELECT
  * EXCEPT (_rescued_data),
  _metadata.file_path                                  AS _fichier_source,
  current_timestamp()                                  AS _date_chargement,
  date_format(current_timestamp(), 'yyyyMMdd_HHmmss')  AS _id_lot
FROM read_files('/Volumes/chu/bronze/landing/deces/deces/',
                format => 'csv', header => true, sep => ';', inferColumnTypes => false);