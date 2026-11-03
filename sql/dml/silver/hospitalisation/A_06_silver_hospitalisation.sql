-- Databricks notebook source
-- Membre A - Silver hospitalisation : dates (ISO apres read_files), duree, dedoublonnage, rejets

-- COMMAND ----------
CREATE OR REPLACE TABLE chu.silver.rejets_hospitalisation AS
SELECT num_hospitalisation, patient_id, code_diag, date_entree, jour_hospitalisation,
       CASE WHEN num_hospitalisation IS NULL THEN 'cle_nulle'
            WHEN try_to_date(trim(date_entree)) IS NULL THEN 'date_invalide'
            ELSE 'duree_invalide' END AS motif
FROM chu.bronze.hospitalisation
WHERE num_hospitalisation IS NULL
   OR try_to_date(trim(date_entree)) IS NULL
   OR try_cast(trim(jour_hospitalisation) AS INT) IS NULL
   OR try_cast(trim(jour_hospitalisation) AS INT) < 0;

-- COMMAND ----------
CREATE OR REPLACE TABLE chu.silver.hospitalisation AS
SELECT num_hospitalisation, patient_id, finess, code_diag, date_entree, jours FROM (
  SELECT trim(num_hospitalisation)                   AS num_hospitalisation,
         trim(patient_id)                            AS patient_id,
         upper(trim(finess))                         AS finess,
         upper(trim(code_diag))                      AS code_diag,
         try_to_date(trim(date_entree))              AS date_entree,
         try_cast(trim(jour_hospitalisation) AS INT) AS jours,
         row_number() OVER (PARTITION BY trim(num_hospitalisation) ORDER BY _ingest_ts DESC) AS rn
  FROM chu.bronze.hospitalisation
  WHERE num_hospitalisation IS NOT NULL
) WHERE rn = 1 AND date_entree IS NOT NULL AND jours IS NOT NULL AND jours >= 0;
