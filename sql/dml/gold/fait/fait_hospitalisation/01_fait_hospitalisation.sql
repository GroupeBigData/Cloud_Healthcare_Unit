-- Databricks notebook source
-- Gold - DML fait_hospitalisation. Prérequis : DDL 10_fait_hospitalisation.sql et les dimensions.
-- Jointures gauches : aucun séjour ne disparaît ; une dimension introuvable donne -1.
INSERT OVERWRITE chu.gold.fait_hospitalisation
WITH sejours AS (
  SELECT s.num_hospitalisation,
         coalesce(p.patient_sk, -1)                    AS patient_sk,
         coalesce(d.diagnostic_sk, -1)                 AS diagnostic_sk,
         coalesce(e.etablissement_sk, -1)              AS etablissement_sk,
         s.date_entree,
         s.jours,
         year(s.date_entree) - p.annee_naissance       AS age_entree
  FROM chu.silver.hospitalisation s
  LEFT JOIN chu.gold.dim_patient p
         ON s.patient_id = p.patient_id AND p.patient_sk <> -1
  LEFT JOIN chu.gold.dim_diagnostic d
         ON s.code_diag = d.code_diag AND d.diagnostic_sk <> -1
  LEFT JOIN chu.gold.dim_etablissement e
         ON s.finess = e.identifiant_organisation AND e.etablissement_sk <> -1
)
SELECT num_hospitalisation,
       patient_sk,
       diagnostic_sk,
       etablissement_sk,
       CAST(date_format(date_entree, 'yyyyMMdd') AS INT),
       CAST(date_format(date_add(date_entree, jours), 'yyyyMMdd') AS INT),
       jours,
       age_entree,
       CASE
         WHEN age_entree IS NULL THEN 'Inconnu'
         WHEN age_entree < 0     THEN 'Incohérent'
         WHEN age_entree >= 90   THEN '90 ans et +'
         ELSE concat(lpad(CAST(floor(age_entree / 10) * 10 AS STRING), 2, '0'), '-',
                     lpad(CAST(floor(age_entree / 10) * 10 + 9 AS STRING), 2, '0'), ' ans')
       END,
       1
FROM sejours;