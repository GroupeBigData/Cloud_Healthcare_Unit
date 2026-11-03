-- Databricks notebook source
-- Contrôles qualité : volumétrie et cohérence de bout en bout, toutes entités du groupe.
-- À exécuter après l'ensemble des scripts Bronze, Silver et Gold.

-- COMMAND ----------
-- 1. Volumétrie par couche et par entité
SELECT 'patient'         AS entite, 'bronze' AS couche, count(*) AS nb FROM chu.bronze.patient
UNION ALL SELECT 'patient',         'silver', count(*) FROM chu.silver.patient
UNION ALL SELECT 'patient',         'gold',   count(*) FROM chu.gold.dim_patient
UNION ALL SELECT 'diagnostic',      'bronze', count(*) FROM chu.bronze.diagnostic
UNION ALL SELECT 'diagnostic',      'silver', count(*) FROM chu.silver.diagnostic
UNION ALL SELECT 'diagnostic',      'gold',   count(*) FROM chu.gold.dim_diagnostic
UNION ALL SELECT 'hospitalisation', 'bronze', count(*) FROM chu.bronze.hospitalisation
UNION ALL SELECT 'hospitalisation', 'silver', count(*) FROM chu.silver.hospitalisation
UNION ALL SELECT 'hospitalisation', 'gold',   count(*) FROM chu.gold.fait_hospitalisation
UNION ALL SELECT 'satisfaction',    'silver', count(*) FROM chu.silver.satisfaction_esatis
ORDER BY entite, couche;

-- COMMAND ----------
-- 2. Rejets Silver : vue d'ensemble de la table commune, toutes entités confondues.
--    Une entité absente de ce résultat n'a produit aucun rejet au dernier passage.
SELECT table_cible, table_source, regle, count(*) AS nb,
       count(DISTINCT _id_lot) AS lots, max(date_rejet) AS dernier_rejet
FROM chu.silver.rejets
GROUP BY table_cible, table_source, regle
ORDER BY table_cible, regle;

-- COMMAND ----------
-- 3. Réconciliation Bronze = Silver + rejets, pour les entités dotées de règles de rejet
SELECT 'hospitalisation' AS entite,
       (SELECT count(*) FROM chu.bronze.hospitalisation)                                  AS bronze,
       (SELECT count(*) FROM chu.silver.hospitalisation)                                  AS silver,
       (SELECT count(*) FROM chu.silver.rejets WHERE table_cible = 'hospitalisation')     AS rejets,
       (SELECT count(*) FROM chu.bronze.hospitalisation)
         - (SELECT count(*) FROM chu.silver.hospitalisation)
         - (SELECT count(*) FROM chu.silver.rejets WHERE table_cible = 'hospitalisation') AS ecart_doublons
UNION ALL
SELECT 'diagnostic',
       (SELECT count(*) FROM chu.bronze.diagnostic),
       (SELECT count(*) FROM chu.silver.diagnostic),
       (SELECT count(*) FROM chu.silver.rejets WHERE table_cible = 'diagnostic'),
       (SELECT count(*) FROM chu.bronze.diagnostic)
         - (SELECT count(*) FROM chu.silver.diagnostic)
         - (SELECT count(*) FROM chu.silver.rejets WHERE table_cible = 'diagnostic')
UNION ALL
SELECT 'satisfaction_esatis',
       (SELECT count(*) FROM chu.bronze.esatis48h_mco_recueil2017_donnees)
         + (SELECT count(*) FROM chu.bronze.resultats_esatis48h_mco_open_data_2019)
         + (SELECT count(*) FROM chu.bronze.resultats_esatis48h_mco_open_data_2020)
         + (SELECT count(*) FROM chu.bronze.resultats_esatisca_mco_open_data_2019)
         + (SELECT count(*) FROM chu.bronze.resultats_esatisca_mco_open_data_2020),
       (SELECT count(*) FROM chu.silver.satisfaction_esatis),
       (SELECT count(*) FROM chu.silver.rejets WHERE table_cible = 'satisfaction_esatis'),
       NULL;   -- pas de dédoublonnage sur cette entité : l'écart doit être nul

-- COMMAND ----------
-- 4. Patient : répartition du sexe et bornes des années de naissance
SELECT sexe, count(*) AS nb, min(annee_naissance) AS annee_min, max(annee_naissance) AS annee_max,
       sum(CASE WHEN annee_naissance IS NULL THEN 1 ELSE 0 END) AS annee_nulle
FROM chu.silver.patient GROUP BY sexe ORDER BY sexe;

-- COMMAND ----------
-- 5. Diagnostic : libellés vides et codes au format CIM-10 inattendu
SELECT count(*) AS nb,
       sum(CASE WHEN diagnostic IS NULL OR trim(diagnostic) = '' THEN 1 ELSE 0 END) AS libelle_vide,
       sum(CASE WHEN NOT code_diag RLIKE '^[A-Z][0-9]{2,3}[A-Z0-9]*$' THEN 1 ELSE 0 END) AS format_invalide
FROM chu.gold.dim_diagnostic;

-- COMMAND ----------
-- 6. dim_temps : couverture du calendrier (attendu : 5844 / 5844 / 2010-01-01 / 2025-12-31)
SELECT count(*) AS nb_jours, count(DISTINCT date_sk) AS cles_uniques,
       min(date_complete) AS date_min, max(date_complete) AS date_max
FROM chu.gold.dim_temps;

-- COMMAND ----------
-- 7. fait_hospitalisation : intégrité des clés de dimension.
--    sejours_perdus > 0 signale des séjours écartés par les jointures internes du fait
--    (patient ou diagnostic absent des dimensions), sans trace dans la table des rejets.
SELECT (SELECT count(*) FROM chu.silver.hospitalisation)
         - (SELECT count(*) FROM chu.gold.fait_hospitalisation)        AS sejours_perdus,
       (SELECT count(*) FROM chu.gold.fait_hospitalisation f
          LEFT JOIN chu.gold.dim_temps t ON f.date_entree_sk = t.date_sk
          WHERE t.date_sk IS NULL)                                     AS entrees_hors_dim_temps,
       (SELECT count(*) FROM chu.gold.fait_hospitalisation f
          LEFT JOIN chu.gold.dim_temps t ON f.date_sortie_sk = t.date_sk
          WHERE t.date_sk IS NULL)                                     AS sorties_hors_dim_temps;

-- COMMAND ----------
-- 8. satisfaction_esatis : millésimes chargés et régions non rattachées au référentiel INSEE
SELECT millesime, enquete, count(*) AS etablissements,
       sum(CASE WHEN code_region IS NULL THEN 1 ELSE 0 END) AS region_non_rattachee,
       sum(CASE WHEN est_classe THEN 1 ELSE 0 END)          AS classes_a_d
FROM chu.silver.satisfaction_esatis
GROUP BY millesime, enquete ORDER BY millesime, enquete;
