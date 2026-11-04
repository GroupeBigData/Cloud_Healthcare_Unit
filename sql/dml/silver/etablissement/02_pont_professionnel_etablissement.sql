-- Silver - pont professionnel <-> structure : base du rattachement des consultations
-- aux établissements (indicateur 1).
-- Source : chu.bronze.activite_professionnel_sante (1 823 588 lignes)
-- Grain  : un couple (identifiant du professionnel, identifiant_organisation)
-- Prérequis : etablissements/01_etablissement.sql, consultations/02_silver_professionnel.sql
--
-- Règles issues du profilage :
--   identifiant : 9 chiffres = ADELI, 11 = RPPS (aucune autre longueur, aucun zéro perdu)
--   couples en double (même professionnel, même structure) : regroupés, modes d'exercice listés
--   poids = 1 / nombre de structures du professionnel (structures inconnues comprises)

-- 1. Normaliser et marquer les lignes
CREATE OR REPLACE TEMPORARY VIEW silver_pont_marks AS
WITH src AS (
  SELECT
    NULLIF(trim(identifiant), '')               AS identifiant,
    NULLIF(trim(identifiant_organisation), '')  AS identifiant_organisation,
    NULLIF(trim(mode_exercice), '')             AS mode_exercice,
    _fichier_source, _id_lot
  FROM chu.bronze.activite_professionnel_sante
)
SELECT *,
  CASE
    WHEN identifiant IS NULL              THEN 'identifiant_vide'
    WHEN identifiant_organisation IS NULL THEN 'identifiant_organisation_vide'
    WHEN length(identifiant) NOT IN (9, 11) THEN 'identifiant_invalide'
  END AS motif_rejet
FROM src;

-- 2. Effacer les anciens rejets de CETTE table, puis écrire les nouveaux
DELETE FROM chu.silver.rejets WHERE table_cible = 'pont_professionnel_etablissement';

INSERT INTO chu.silver.rejets
SELECT 'pont_professionnel_etablissement', 'activite_professionnel_sante', motif_rejet,
       concat_ws('|', identifiant, identifiant_organisation), identifiant,
       _fichier_source, _id_lot, current_timestamp()
FROM silver_pont_marks
WHERE motif_rejet IS NOT NULL;

-- 3. Construire le pont : une ligne par couple, avec poids et indicateurs de rattachement
CREATE OR REPLACE TABLE chu.silver.pont_professionnel_etablissement (
  identifiant               STRING  NOT NULL COMMENT 'Identifiant du professionnel (ADELI 9 ou RPPS 11 chiffres)',
  type_identifiant          STRING  NOT NULL COMMENT 'ADELI ou RPPS, déduit de la longueur',
  identifiant_organisation  STRING  NOT NULL COMMENT 'Structure d''exercice, clé de silver.etablissement',
  modes_exercice            STRING           COMMENT 'Modes d''exercice regroupés pour ce couple',
  nb_activites              INT     NOT NULL COMMENT 'Lignes Bronze regroupées dans ce couple',
  nb_structures             INT     NOT NULL COMMENT 'Nombre de structures du professionnel',
  poids                     DOUBLE  NOT NULL COMMENT '1 / nb_structures : part des consultations attribuée à cette structure',
  professionnel_connu       BOOLEAN NOT NULL COMMENT 'Vrai si le professionnel existe dans silver.professionnel',
  structure_connue          BOOLEAN NOT NULL COMMENT 'Vrai si la structure existe dans silver.etablissement',
  _fichier_source           STRING           COMMENT 'Fichier Bronze d''origine',
  _id_lot                   STRING           COMMENT 'Lot de chargement Bronze'
) COMMENT 'Silver - pont professionnel <-> structure, pondéré pour l''indicateur 1';

INSERT INTO chu.silver.pont_professionnel_etablissement
WITH paires AS (
  SELECT identifiant, identifiant_organisation,
         concat_ws(', ', array_sort(collect_set(mode_exercice))) AS modes_exercice,
         count(*)              AS nb_activites,
         min(_fichier_source)  AS _fichier_source,
         min(_id_lot)          AS _id_lot
  FROM silver_pont_marks
  WHERE motif_rejet IS NULL
  GROUP BY identifiant, identifiant_organisation
),
typees AS (
  SELECT *,
         CASE length(identifiant) WHEN 11 THEN 'RPPS' ELSE 'ADELI' END AS type_identifiant,
         count(*) OVER (PARTITION BY identifiant)                     AS nb_structures
  FROM paires
)
SELECT t.identifiant, t.type_identifiant, t.identifiant_organisation,
       t.modes_exercice, CAST(t.nb_activites AS INT), CAST(t.nb_structures AS INT),
       1.0D / t.nb_structures,
       pr.identifiant_normalise IS NOT NULL,
       e.identifiant_organisation IS NOT NULL,
       t._fichier_source, t._id_lot
FROM typees t
LEFT JOIN chu.silver.professionnel pr
       ON pr.type_identifiant = t.type_identifiant
      AND pr.identifiant_normalise = t.identifiant
LEFT JOIN chu.silver.etablissement e
       ON e.identifiant_organisation = t.identifiant_organisation;