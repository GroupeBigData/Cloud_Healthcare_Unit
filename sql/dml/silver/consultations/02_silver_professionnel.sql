-- ============================================================
-- 02_silver_professionnel.sql
-- Source Bronze : chu.bronze.professionnel_de_sante (1 048 575 lignes)
-- Grain         : un professionnel = (type_identifiant, identifiant_normalise)
-- Attendu       : 1 048 575 lignes Silver, 0 rejet
-- À exécuter après : 01_silver_specialite.sql
-- ============================================================

-- 1. Normaliser et marquer les lignes
CREATE OR REPLACE TEMPORARY VIEW silver_professionnel_marks AS
WITH src AS (
  SELECT
    trim(Identifiant)                               AS identifiant_source,
    upper(trim(Type_identifiant))                   AS type_identifiant,
    NULLIF(trim(Categorie_professionnelle), '')     AS categorie_professionnelle,
    NULLIF(trim(Profession), '')                    AS profession,
    upper(NULLIF(trim(Code_specialite), ''))        AS code_specialite,
    _fichier_source,
    _date_chargement,
    _id_lot
  FROM chu.bronze.professionnel_de_sante
),
norm AS (
  SELECT
    *,
    CASE
      -- ADELI : 8 chiffres = zéro initial perdu ; on complète à 9.
      WHEN type_identifiant = 'ADELI'
       AND length(identifiant_source) IN (8, 9)
        THEN lpad(identifiant_source, 9, '0')
      -- RPPS : on ne touche pas aux 11 chiffres.
      ELSE identifiant_source
    END AS identifiant_normalise
  FROM src
),
marks AS (
  SELECT
    *,
    CASE
      WHEN identifiant_source IS NULL OR identifiant_source = ''
        THEN 'identifiant_vide'
      WHEN type_identifiant IS NULL OR type_identifiant = ''
        THEN 'type_identifiant_vide'
      WHEN type_identifiant = 'ADELI'
       AND length(identifiant_source) NOT IN (8, 9)
        THEN 'identifiant_longueur_invalide'
      WHEN type_identifiant = 'RPPS'
       AND length(identifiant_source) <> 11
        THEN 'identifiant_longueur_invalide'
      WHEN type_identifiant NOT IN ('ADELI', 'RPPS')
        THEN 'type_identifiant_inconnu'
    END AS motif_rejet,
    row_number() OVER (
      PARTITION BY type_identifiant, identifiant_normalise
      ORDER BY _date_chargement DESC, _fichier_source
    ) AS rn
  FROM norm
)
SELECT * FROM marks;

-- 2. Remplacer les rejets de cette table
DELETE FROM chu.silver.rejets
WHERE table_cible = 'professionnel';

INSERT INTO chu.silver.rejets
  (table_cible, table_source, regle, cle, valeur,
   _fichier_source, _id_lot, date_rejet)
SELECT
  'professionnel',
  'professionnel_de_sante',
  COALESCE(motif_rejet, 'doublon_identifiant'),
  COALESCE(identifiant_normalise, identifiant_source, ''),
  COALESCE(identifiant_source, ''),
  _fichier_source,
  _id_lot,
  current_timestamp()
FROM silver_professionnel_marks
WHERE motif_rejet IS NOT NULL OR rn > 1;

-- 3. Table Silver : 1 048 575 lignes attendues
CREATE OR REPLACE TABLE chu.silver.professionnel (
  type_identifiant          STRING NOT NULL COMMENT 'Type d''identifiant normalisé : ADELI ou RPPS',
  identifiant_normalise     STRING NOT NULL COMMENT 'ADELI 9 chiffres (lpad), RPPS 11 chiffres',
  identifiant_source        STRING COMMENT 'Identifiant tel que fourni, sans espaces',
  categorie_professionnelle STRING COMMENT 'Catégorie professionnelle source',
  profession                STRING COMMENT 'Profession source',
  code_specialite           STRING COMMENT 'Code spécialité normalisé ; NULL ou absent = spécialité inconnue en Gold',
  _fichier_source           STRING COMMENT 'Fichier Bronze d''origine',
  _date_chargement          TIMESTAMP COMMENT 'Date de chargement Bronze',
  _id_lot                   STRING COMMENT 'Lot de chargement Bronze'
) COMMENT 'Professionnels de santé nettoyés, une ligne par (type_identifiant, identifiant_normalise)';

INSERT INTO chu.silver.professionnel
SELECT
  type_identifiant,
  identifiant_normalise,
  identifiant_source,
  categorie_professionnelle,
  profession,
  code_specialite,
  _fichier_source,
  _date_chargement,
  _id_lot
FROM silver_professionnel_marks
WHERE motif_rejet IS NULL
  AND rn = 1;

-- 4. Contrôles d'équilibre
SELECT
  'professionnel' AS objet, count(*) AS lignes
FROM chu.silver.professionnel
UNION ALL
SELECT
  'rejets_professionnel', count(*)
FROM chu.silver.rejets
WHERE table_cible = 'professionnel';

-- Le seul professionnel sans spécialité connue doit rester dans la table.
SELECT count(*) AS professionnels_sans_specialite
FROM chu.silver.professionnel p
LEFT JOIN chu.silver.specialite s
  ON p.code_specialite = s.code_specialite
WHERE s.code_specialite IS NULL;
