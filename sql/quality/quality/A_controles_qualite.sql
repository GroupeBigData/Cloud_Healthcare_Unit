-- Databricks notebook source
-- Membre A - Controles qualite (patient, diagnostic, temps, fait_hospitalisation)

-- COMMAND ----------
SELECT 'bronze_patient' AS table_, count(*) AS nb FROM chu.bronze.patient
UNION ALL SELECT 'silver_patient', count(*) FROM chu.silver.patient
UNION ALL SELECT 'gold_dim_patient', count(*) FROM chu.gold.dim_patient
UNION ALL SELECT 'bronze_diagnostic', count(*) FROM chu.bronze.diagnostic
UNION ALL SELECT 'silver_diagnostic', count(*) FROM chu.silver.diagnostic
UNION ALL SELECT 'gold_dim_diagnostic', count(*) FROM chu.gold.dim_diagnostic;

-- COMMAND ----------
SELECT sexe, count(*) AS nb, min(annee_naissance) AS annee_min, max(annee_naissance) AS annee_max,
       sum(CASE WHEN annee_naissance IS NULL THEN 1 ELSE 0 END) AS annee_nulle
FROM chu.silver.patient GROUP BY sexe;

-- COMMAND ----------
SELECT count(*) AS nb,
       sum(CASE WHEN diagnostic IS NULL OR trim(diagnostic) = '' THEN 1 ELSE 0 END) AS libelle_vide,
       sum(CASE WHEN NOT code_diag RLIKE '^[A-Z][0-9]{2,3}[A-Z0-9]*$' THEN 1 ELSE 0 END) AS format_invalide
FROM chu.gold.dim_diagnostic;

-- COMMAND ----------
-- dim_temps (attendu : 5844 / 5844 / 2010-01-01 / 2025-12-31)
SELECT count(*) AS nb_jours, count(DISTINCT date_sk) AS cles_uniques,
       min(date_complete) AS date_min, max(date_complete) AS date_max
FROM chu.gold.dim_temps;

-- COMMAND ----------
SELECT (SELECT count(*) FROM chu.bronze.hospitalisation)        AS bronze,
       (SELECT count(*) FROM chu.silver.rejets_hospitalisation) AS rejets,
       (SELECT count(*) FROM chu.silver.hospitalisation)        AS silver,
       (SELECT count(*) FROM chu.gold.fait_hospitalisation)     AS gold,
       (SELECT count(*) FROM chu.gold.fait_hospitalisation f
          LEFT JOIN chu.gold.dim_temps t ON f.date_entree_sk = t.date_sk
          WHERE t.date_sk IS NULL)                              AS entrees_hors_dim_temps,
       (SELECT count(*) FROM chu.gold.fait_hospitalisation f
          LEFT JOIN chu.gold.dim_temps t ON f.date_sortie_sk = t.date_sk
          WHERE t.date_sk IS NULL)                              AS sorties_hors_dim_temps;
