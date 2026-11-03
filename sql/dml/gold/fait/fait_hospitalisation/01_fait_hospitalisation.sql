-- Databricks notebook source
-- Gold - fait_hospitalisation (grain : un séjour)
-- etablissement_sk = NULL tant que dim_etablissement n'est pas livrée ; finess est temporaire
CREATE OR REPLACE TABLE chu.gold.fait_hospitalisation AS
SELECT s.num_hospitalisation                                                   AS hospitalisation_id,
       p.patient_sk,
       d.diagnostic_sk,
       CAST(NULL AS BIGINT)                                                    AS etablissement_sk,
       s.finess,
       CAST(date_format(s.date_entree, 'yyyyMMdd') AS INT)                     AS date_entree_sk,
       CAST(date_format(date_add(s.date_entree, s.jours), 'yyyyMMdd') AS INT)  AS date_sortie_sk,
       s.jours                                                                 AS duree_sejour_jours,
       1                                                                       AS nb_hospitalisations
FROM chu.silver.hospitalisation s
JOIN chu.gold.dim_patient p    ON s.patient_id = p.patient_id
JOIN chu.gold.dim_diagnostic d ON s.code_diag  = d.code_diag;
