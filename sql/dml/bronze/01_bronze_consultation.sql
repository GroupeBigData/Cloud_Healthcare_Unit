-- ============================================================
-- 01_bronze_consultation.sql
-- Source : /Volumes/chu/bronze/landing/postgres/consultation/
-- Attendu : 1 027 157 lignes
-- À exécuter après : sql/00_setup/01_catalogue.sql
-- ============================================================

CREATE TABLE IF NOT EXISTS chu.bronze.consultation
  COMMENT 'Bronze - consultations PostgreSQL, fidèle à la source, tout en texte';

COPY INTO chu.bronze.consultation
FROM (
  SELECT
    *,
    _metadata.file_path                                  AS _fichier_source,
    current_timestamp()                                  AS _date_chargement,
    date_format(current_timestamp(), 'yyyyMMdd_HHmmss')  AS _id_lot
  FROM '/Volumes/chu/bronze/landing/postgres/consultation/'
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