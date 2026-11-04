-- Silver - deces : décès INSEE typés, âge au décès, région de décès.
-- Source : chu.bronze.deces (24 875 168 lignes, 1882 - mars 2020)
-- Grain  : un décès (aucune clé naturelle : les noms ont été supprimés en local)
-- Prérequis : 00_rejets.sql, referentiels/01_ref_geographie.sql
--
-- Pas de dédoublonnage : fait en local avant suppression des noms (213 040 doublons).
-- Années de naissance hors d'un âge plausible (0 à 120 ans) ramenées à NULL, sans rejet.

-- 1. Typer et marquer les lignes
CREATE OR REPLACE TEMPORARY VIEW silver_deces_marks AS
WITH src AS (
  SELECT
    trim(sexe)                                         AS sexe_source,
    trim(annee_naissance)                              AS annee_naissance_source,
    trim(date_deces)                                   AS date_deces_source,
    NULLIF(trim(departement_deces), '')                AS departement_deces,
    CASE
      WHEN trim(date_deces) RLIKE '^[0-9]{4}$'
        THEN try_to_date(concat(trim(date_deces), '-01-01'), 'yyyy-MM-dd')
      WHEN trim(date_deces) RLIKE '^[0-9]{4}-[0-9]{2}$'
        THEN try_to_date(concat(trim(date_deces), '-01'), 'yyyy-MM-dd')
      ELSE try_to_date(trim(date_deces), 'yyyy-MM-dd')
    END                                                AS date_deces,
    CASE
      WHEN trim(date_deces) RLIKE '^[0-9]{4}$'          THEN 'annee'
      WHEN trim(date_deces) RLIKE '^[0-9]{4}-[0-9]{2}$' THEN 'mois'
      ELSE 'jour'
    END                                                AS precision_date,    try_cast(trim(annee_naissance) AS INT)             AS annee_naissance_brute,
    _fichier_source, _id_lot
  FROM chu.bronze.deces
)
SELECT *,
  CASE WHEN date_deces IS NULL THEN 'date_deces_illisible' END AS motif_rejet
FROM src;

-- 2. Effacer les anciens rejets de CETTE table, puis écrire les nouveaux
DELETE FROM chu.silver.rejets WHERE table_cible = 'deces';

INSERT INTO chu.silver.rejets
SELECT 'deces', 'deces', motif_rejet,
       concat_ws('|', sexe_source, annee_naissance_source, date_deces_source, departement_deces),
       date_deces_source, _fichier_source, _id_lot, current_timestamp()
FROM silver_deces_marks
WHERE motif_rejet IS NOT NULL;

-- 3. Construire la table Silver avec les lignes valides
CREATE OR REPLACE TABLE chu.silver.deces (
  sexe               STRING NOT NULL COMMENT 'M, F ou INCONNU (mêmes codes que silver.patient)',
  annee_naissance    INT             COMMENT 'Année de naissance ; NULL si âge au décès hors de 0 à 120 ans',
  date_deces         DATE   NOT NULL COMMENT 'Date du décès',
  precision_date     STRING NOT NULL COMMENT 'jour = date complète ; mois = jour inconnu (fixé au 1er) ; annee = seule l''année connue (fixée au 1er janvier)',
  date_sk            INT    NOT NULL COMMENT 'Clé date AAAAMMJJ pour dim_temps',
  age_deces          INT             COMMENT 'Année du décès - année de naissance ; NULL si naissance inconnue',
  departement_deces  STRING          COMMENT 'Département du lieu de décès (généralisé en local), ou code historique',
  code_region        STRING          COMMENT 'Zone de silver.ref_region ; NULL si code non rattachable',
  _fichier_source    STRING          COMMENT 'Fichier Bronze d''origine',
  _id_lot            STRING          COMMENT 'Lot de chargement Bronze'
) COMMENT 'Silver - décès INSEE 1882-2020, anonymisés, typés et rattachés à une région';

INSERT INTO chu.silver.deces
WITH valides AS (
  SELECT m.*,
         CASE WHEN year(m.date_deces) - m.annee_naissance_brute BETWEEN 0 AND 120
              THEN m.annee_naissance_brute END AS annee_naissance
  FROM silver_deces_marks m
  WHERE m.motif_rejet IS NULL
)
SELECT
  CASE v.sexe_source WHEN '1' THEN 'M' WHEN '2' THEN 'F' ELSE 'INCONNU' END,
  v.annee_naissance,
  v.date_deces,
  v.precision_date,
  CAST(date_format(v.date_deces, 'yyyyMMdd') AS INT),
  year(v.date_deces) - v.annee_naissance,
  v.departement_deces,
  d.code_region,
  v._fichier_source,
  v._id_lot
FROM valides v
LEFT JOIN chu.silver.ref_departement d ON v.departement_deces = d.code_departement;