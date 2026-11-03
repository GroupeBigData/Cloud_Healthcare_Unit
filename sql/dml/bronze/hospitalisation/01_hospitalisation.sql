-- Databricks notebook source
-- Bronze - hospitalisation : contenu inchangé, tout en texte, + traçabilité.
-- Source : /Volumes/chu/bronze/landing/hospitalisation/hospitalisations/ (CSV, séparateur ;)
-- Cible  : chu.bronze.hospitalisation
-- Colonnes techniques communes au projet : _fichier_source, _date_chargement, _id_lot.

-- COMMAND ----------
-- Rafraîchissement complet : le fichier source est un instantané, pas un delta.
CREATE OR REPLACE TABLE chu.bronze.hospitalisation
COMMENT 'Bronze - séjours hospitaliers, fidèle au fichier source'
AS
SELECT CAST(Num_Hospitalisation AS STRING)             AS num_hospitalisation,
       CAST(id_patient_pseudo AS STRING)               AS patient_id,
       CAST(identifiant_organisation AS STRING)        AS finess,
       CAST(Code_diagnostic AS STRING)                 AS code_diag,
       CAST(Date_Entree AS STRING)                     AS date_entree,
       CAST(Jour_Hospitalisation AS STRING)            AS jour_hospitalisation,
       _metadata.file_path                             AS _fichier_source,
       current_timestamp()                             AS _date_chargement,
       date_format(current_timestamp(), 'yyyyMMdd_HHmmss') AS _id_lot
FROM read_files('/Volumes/chu/bronze/landing/hospitalisation/hospitalisations/',
                format => 'csv', header => true, sep => ';', inferColumnTypes => false);

-- COMMAND ----------
SELECT count(*) AS nb, count(DISTINCT num_hospitalisation) AS ids_uniques,
       count(DISTINCT _id_lot) AS lots
FROM chu.bronze.hospitalisation;  -- attendu : 2479 / 2479 / 1
