-- ============================================================
-- 01_silver_specialite.sql
-- Source Bronze : chu.bronze.specialites (93 lignes)
-- Grain         : un code spécialité normalisé
-- Attendu       : 93 lignes Silver, 0 rejet
-- À exécuter après : sql/dml/silver/00_rejets.sql
-- ============================================================

-- 1. Normaliser et marquer les lignes
CREATE OR REPLACE TEMPORARY VIEW silver_specialite_marks AS
WITH src AS (
  SELECT
    trim(Code_specialite)                         AS code_specialite_source,
    upper(NULLIF(trim(Code_specialite), ''))      AS code_specialite,
    NULLIF(trim(Fonction), '')                    AS fonction,
    NULLIF(trim(Specialite), '')                  AS specialite,
    _fichier_source,
    _date_chargement,
    _id_lot
  FROM chu.bronze.specialites
),
marks AS (
  SELECT
    *,
    CASE
      WHEN code_specialite IS NULL THEN 'code_specialite_vide'
    END AS motif_rejet,
    row_number() OVER (
      PARTITION BY code_specialite
      ORDER BY _date_chargement DESC, _fichier_source
    ) AS rn
  FROM src
)
SELECT * FROM marks;

-- 2. Remplacer les rejets de cette table
DELETE FROM chu.silver.rejets
WHERE table_cible = 'specialite';

INSERT INTO chu.silver.rejets
  (table_cible, table_source, regle, cle, valeur,
   _fichier_source, _id_lot, date_rejet)
SELECT
  'specialite',
  'specialites',
  COALESCE(motif_rejet, 'doublon_code_specialite'),
  COALESCE(code_specialite, code_specialite_source, ''),
  COALESCE(code_specialite_source, ''),
  _fichier_source,
  _id_lot,
  current_timestamp()
FROM silver_specialite_marks
WHERE motif_rejet IS NOT NULL OR rn > 1;

-- 3. Table Silver : 93 lignes attendues
CREATE OR REPLACE TABLE chu.silver.specialite (
  code_specialite   STRING NOT NULL COMMENT 'Code source normalisé : majuscules, sans espaces',
  fonction          STRING COMMENT 'Fonction issue de specialites.Fonction',
  specialite        STRING COMMENT 'Libellé de la spécialité',
  _fichier_source   STRING COMMENT 'Fichier Bronze d''origine',
  _date_chargement  TIMESTAMP COMMENT 'Date de chargement Bronze',
  _id_lot           STRING COMMENT 'Lot de chargement Bronze'
) COMMENT 'Spécialités médicales nettoyées, une ligne par code normalisé';

INSERT INTO chu.silver.specialite
SELECT
  code_specialite,
  fonction,
  specialite,
  _fichier_source,
  _date_chargement,
  _id_lot
FROM silver_specialite_marks
WHERE motif_rejet IS NULL
  AND rn = 1;

-- 4. Contrôle d'équilibre
SELECT
  'specialite' AS objet, count(*) AS lignes
FROM chu.silver.specialite
UNION ALL
SELECT
  'rejets_specialite', count(*)
FROM chu.silver.rejets
WHERE table_cible = 'specialite';
