-- Silver - e-Satis : 5 fichiers réunis en une table harmonisée.
-- Grain : un établissement géographique x une enquête x un millésime.

-- 1. Réunir les 5 fichiers sous des noms de colonnes communs (valeurs encore brutes)
CREATE OR REPLACE TEMPORARY VIEW esatis_brut AS
SELECT 2017 AS millesime, '48H_MCO' AS enquete, 'esatis48h_mco_recueil2017_donnees' AS table_source,
       finess, finess_geo, rs_finess_geo, region, participation, Depot,
       score_all_rea_ajust AS score, nb_rep_score_all_rea_ajust AS nb_rep, classement, evolution,
       CAST(NULL AS STRING) AS taux_reco, CAST(NULL AS STRING) AS nb_reco,
       _fichier_source, _id_lot
FROM chu.bronze.esatis48h_mco_recueil2017_donnees
UNION ALL
SELECT 2019, '48H_MCO', 'resultats_esatis48h_mco_open_data_2019',
       finess, finess_geo, rs_finess_geo, region, participation, Depot,
       score_all_rea_ajust, nb_rep_score_all_rea_ajust, classement, evolution,
       taux_reco_brut, nb_reco_brut, _fichier_source, _id_lot
FROM chu.bronze.resultats_esatis48h_mco_open_data_2019
UNION ALL
SELECT 2020, '48H_MCO', 'resultats_esatis48h_mco_open_data_2020',
       finess, finess_geo, rs_finess_geo, region, participation, Depot,
       score_all_rea_ajust, nb_rep_score_all_rea_ajust, classement, evolution,
       taux_reco_brut, nb_reco_brut, _fichier_source, _id_lot
FROM chu.bronze.resultats_esatis48h_mco_open_data_2020
UNION ALL
SELECT 2019, 'CA_MCO', 'resultats_esatisca_mco_open_data_2019',
       finess, finess_geo, rs_finess_geo, region, participation, Depot,
       score_all_ajust, nb_rep_score_all_ajust, classement, evolution,
       taux_reco_brut, nb_reco_brut, _fichier_source, _id_lot
FROM chu.bronze.resultats_esatisca_mco_open_data_2019
UNION ALL
SELECT 2020, 'CA_MCO', 'resultats_esatisca_mco_open_data_2020',
       finess, finess_geo, rs_finess_geo, region, participation, Depot,
       score_all_ajust, nb_rep_score_all_ajust, classement, evolution,
       taux_reco_brut, nb_reco_brut, _fichier_source, _id_lot
FROM chu.bronze.resultats_esatisca_mco_open_data_2020;

-- 2. Décider, pour chaque ligne, si elle est valide ou rejetée (et pourquoi)
CREATE OR REPLACE TEMPORARY VIEW esatis_controle AS
SELECT *,
       CASE
         WHEN finess_geo IS NULL THEN 'finess_geo_vide'
         WHEN coalesce(classement IN ('A','B','C','D'), false)
              AND try_cast(replace(score, ',', '.') AS DECIMAL(5,2)) IS NULL THEN 'score_illisible'
       END AS motif_rejet
FROM esatis_brut;

-- 3. Effacer les anciens rejets de CETTE table (et seulement ceux-là)
DELETE FROM chu.silver.rejets WHERE table_cible = 'satisfaction_esatis';

-- 4. Écrire les nouveaux rejets
INSERT INTO chu.silver.rejets
SELECT 'satisfaction_esatis', table_source, motif_rejet,
       concat_ws('|', finess_geo, enquete, CAST(millesime AS STRING)),
       score, _fichier_source, _id_lot, current_timestamp()
FROM esatis_controle
WHERE motif_rejet IS NOT NULL;

-- 5. Construire la table Silver avec les lignes valides
CREATE OR REPLACE TABLE chu.silver.satisfaction_esatis
COMMENT 'Silver - e-Satis +48h et CA réunis ; grain : établissement géographique x enquête x millésime'
AS
SELECT
  c.millesime,
  c.enquete,
  c.finess                                                    AS finess_juridique,
  c.finess_geo,
  c.rs_finess_geo                                             AS raison_sociale,
  c.region                                                    AS libelle_region_has,
  coalesce(r.code_region,
           CASE WHEN c.region = 'Océan Indien' AND left(c.finess_geo, 4) = '9704' THEN '04'
                WHEN c.region = 'Océan Indien' AND left(c.finess_geo, 4) = '9805' THEN '06'
           END)                                               AS code_region,
  c.participation,
  c.Depot                                                     AS depot,
  try_cast(replace(c.score, ',', '.') AS DECIMAL(5,2))        AS score_global,
  try_cast(c.nb_rep AS INT)                                   AS nb_reponses,
  c.classement,
  coalesce(c.classement IN ('A','B','C','D'), false)          AS est_classe,
  c.evolution,
  try_cast(replace(c.taux_reco, ',', '.') AS DECIMAL(5,2))    AS taux_reco_brut,
  try_cast(c.nb_reco AS INT)                                  AS nb_reco_brut,
  c._fichier_source,
  c._id_lot
FROM esatis_controle c
LEFT JOIN chu.silver.ref_region_esatis r ON c.region = r.libelle_has
WHERE c.motif_rejet IS NULL;