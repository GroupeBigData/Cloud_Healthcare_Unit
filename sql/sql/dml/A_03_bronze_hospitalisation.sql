-- Databricks notebook source
-- Membre A - Bronze hospitalisation
-- Source : /Volumes/chu/bronze/landing/hospitalisation/hospitalisations/ (CSV, separateur ;)
-- Cible  : chu.bronze.hospitalisation

-- COMMAND ----------
CREATE OR REPLACE TABLE chu.bronze.hospitalisation AS
SELECT CAST(Num_Hospitalisation AS STRING)      AS num_hospitalisation,
       CAST(id_patient_pseudo AS STRING)        AS patient_id,
       CAST(identifiant_organisation AS STRING) AS finess,
       CAST(Code_diagnostic AS STRING)          AS code_diag,
       CAST(Date_Entree AS STRING)              AS date_entree,
       CAST(Jour_Hospitalisation AS STRING)     AS jour_hospitalisation,
       current_timestamp()                      AS _ingest_ts,
       'hospitalisations'                       AS _source_file
FROM read_files('/Volumes/chu/bronze/landing/hospitalisation/hospitalisations/',
                format => 'csv', header => true, sep => ';');

-- COMMAND ----------
SELECT count(*) AS nb, count(DISTINCT num_hospitalisation) AS ids_uniques
FROM chu.bronze.hospitalisation;  -- attendu : 2479 / 2479
