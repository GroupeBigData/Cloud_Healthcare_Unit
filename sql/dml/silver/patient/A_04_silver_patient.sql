-- Databricks notebook source
-- Membre A - Silver patient : normalisation du sexe, typage, dedoublonnage sur patient_id
CREATE SCHEMA IF NOT EXISTS chu.silver;

-- COMMAND ----------
CREATE OR REPLACE TABLE chu.silver.patient AS
SELECT patient_id,
       CASE lower(trim(sexe)) WHEN 'female' THEN 'F' WHEN 'male' THEN 'M' ELSE 'INCONNU' END AS sexe,
       CAST(annee_naissance AS INT) AS annee_naissance
FROM (
  SELECT *, row_number() OVER (PARTITION BY patient_id ORDER BY _ingest_ts DESC) AS rn
  FROM chu.bronze.patient
  WHERE patient_id IS NOT NULL
) WHERE rn = 1;
