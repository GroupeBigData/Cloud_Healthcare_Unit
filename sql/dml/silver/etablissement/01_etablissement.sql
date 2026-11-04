-- Silver - etablissement : décodage de identifiant_organisation, rattachement à la région.
-- Source : chu.bronze.etablissement_sante (416 665 lignes)
-- Grain  : une structure (identifiant_organisation)
-- Prérequis : 00_rejets.sql, referentiels/01_ref_geographie.sql
--
-- Règles issues du profilage (phase 1) :
--   identifiant_organisation = lettre + identifiant : F (FINESS), C (SIRET/autre), R (RPPS)
--   F + 9  : FINESS géographique ; F + 17 : FINESS + date (pharmacies)
--   finess_site écartée : contient un SIREN, remplie à 0,05 %

-- 1. Normaliser, décoder et marquer les lignes
CREATE OR REPLACE TEMPORARY VIEW silver_etablissement_marks AS
WITH src AS (
  SELECT
    NULLIF(trim(identifiant_organisation), '')        AS identifiant_organisation,
    NULLIF(trim(finess_etablissement_juridique), '')  AS finess_juridique,
    NULLIF(trim(raison_sociale_site), '')             AS raison_sociale,
    NULLIF(trim(code_commune), '')                    AS code_commune,
    NULLIF(trim(code_postal), '')                     AS code_postal,
    NULLIF(trim(commune), '')                         AS commune,
    _fichier_source, _date_chargement, _id_lot
  FROM chu.bronze.etablissement_sante
),
decode AS (
  SELECT *,
    left(identifiant_organisation, 1)                                    AS type_structure,
    length(identifiant_organisation) - 1                                 AS longueur_id,
    CASE WHEN left(identifiant_organisation, 1) = 'F'
         THEN substr(identifiant_organisation, 2, 9) END                 AS finess_geo,
    CASE WHEN code_commune LIKE '97%' THEN left(code_commune, 3)
         ELSE left(code_commune, 2) END                                  AS code_departement
  FROM src
)
SELECT *,
  CASE
    WHEN identifiant_organisation IS NULL THEN 'identifiant_organisation_vide'
    WHEN NOT (   (type_structure = 'F' AND longueur_id IN (9, 17))
              OR (type_structure = 'C' AND longueur_id IN (11, 14))
              OR (type_structure = 'R' AND longueur_id = 14))
      THEN 'identifiant_organisation_invalide'
  END AS motif_rejet,
  row_number() OVER (PARTITION BY identifiant_organisation
                     ORDER BY _date_chargement DESC, _fichier_source) AS rn
FROM decode;

-- 2. Effacer les anciens rejets de CETTE table, puis écrire les nouveaux
DELETE FROM chu.silver.rejets WHERE table_cible = 'etablissement';

INSERT INTO chu.silver.rejets
SELECT 'etablissement', 'etablissement_sante', motif_rejet,
       coalesce(identifiant_organisation, ''), identifiant_organisation,
       _fichier_source, _id_lot, current_timestamp()
FROM silver_etablissement_marks
WHERE motif_rejet IS NOT NULL;

-- 3. Construire la table Silver avec les lignes valides
CREATE OR REPLACE TABLE chu.silver.etablissement (
  identifiant_organisation  STRING  NOT NULL COMMENT 'Clé naturelle : lettre de type + identifiant',
  type_structure            STRING  NOT NULL COMMENT 'F = établissement FINESS, C = SIRET ou autre, R = cabinet RPPS',
  finess_geo                STRING           COMMENT 'FINESS géographique (structures F), clé de jointure e-Satis',
  finess_juridique          STRING           COMMENT 'FINESS de l''entité juridique de rattachement',
  est_entite_juridique      BOOLEAN NOT NULL COMMENT 'Vrai si la fiche décrit l''entité juridique elle-même',
  raison_sociale            STRING           COMMENT 'Raison sociale du site',
  code_commune              STRING           COMMENT 'Code commune INSEE (5 caractères, 2A/2B conservés)',
  code_postal               STRING           COMMENT 'Code postal',
  commune                   STRING           COMMENT 'Libellé de la commune',
  code_departement          STRING           COMMENT 'Déduit du code commune (3 caractères en outre-mer)',
  code_region               STRING           COMMENT 'Zone de silver.ref_region ; NULL si commune absente ou non rattachée',
  _fichier_source           STRING           COMMENT 'Fichier Bronze d''origine',
  _id_lot                   STRING           COMMENT 'Lot de chargement Bronze'
) COMMENT 'Silver - structures de santé, identifiant décodé et région rattachée';

INSERT INTO chu.silver.etablissement
SELECT m.identifiant_organisation, m.type_structure, m.finess_geo, m.finess_juridique,
       coalesce(m.finess_geo = m.finess_juridique, false),
       m.raison_sociale, m.code_commune, m.code_postal, m.commune,
       m.code_departement, d.code_region,
       m._fichier_source, m._id_lot
FROM silver_etablissement_marks m
LEFT JOIN chu.silver.ref_departement d ON m.code_departement = d.code_departement
WHERE m.motif_rejet IS NULL AND m.rn = 1;