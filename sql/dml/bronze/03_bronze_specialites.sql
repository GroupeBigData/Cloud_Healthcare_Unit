-- ============================================================
-- 03_bronze_specialites.sql
-- Source : /Volumes/chu/bronze/landing/postgres/specialites/
-- Attendu : 93 lignes
-- ============================================================

CREATE TABLE IF NOT EXISTS chu.bronze.specialites
  COMMENT 'Bronze - spécialités médicales PostgreSQL, fidèle à la source, tout en texte';

COPY INTO chu.bronze.specialites
FROM (
  SELECT
    *,
    _metadata.file_path                                  AS _fichier_source,
    current_timestamp()                                  AS _date_chargement,
    date_format(current_timestamp(), 'yyyyMMdd_HHmmss')  AS _id_lot
  FROM '/Volumes/chu/bronze/landing/postgres/specialites/'
)
FILEFORMAT = CSV
FORMAT_OPTIONS (
  'header' = 'true',
  'sep' = ';',
  'encoding' = 'UTF-8',
  'inferSchema' = 'false',
  'mergeSchema' = 'true'
)
COPY_OPTIONS ('mergeSchema' = 'true');