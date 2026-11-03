-- ============================================================
-- 02_bronze_professionnel_de_sante.sql
-- Source : /Volumes/chu/bronze/landing/postgres/professionnel_de_sante/
-- Attendu : 1 048 575 lignes
-- ============================================================

CREATE TABLE IF NOT EXISTS chu.bronze.professionnel_de_sante
  COMMENT 'Bronze - professionnels de santé PostgreSQL, fidèle à la source, tout en texte';

COPY INTO chu.bronze.professionnel_de_sante
FROM (
  SELECT
    *,
    _metadata.file_path                                  AS _fichier_source,
    current_timestamp()                                  AS _date_chargement,
    date_format(current_timestamp(), 'yyyyMMdd_HHmmss')  AS _id_lot
  FROM '/Volumes/chu/bronze/landing/postgres/professionnel_de_sante/'
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