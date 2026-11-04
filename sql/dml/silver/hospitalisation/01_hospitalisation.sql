-- Databricks notebook source
-- Silver - hospitalisation : dates (ISO après read_files), durée, dédoublonnage, rejets.
-- Prérequis : sql/dml/silver/00_rejets.sql (table commune chu.silver.rejets).

-- COMMAND ----------

-- 1. Effacer les anciens rejets de CETTE table (et seulement ceux-là)
DELETE FROM chu.silver.rejets WHERE table_cible = 'hospitalisation';

-- COMMAND ----------

-- 2. Écrire les nouveaux rejets dans la table commune.
--    L'ordre des CASE suit celui du WHERE : une ligne ne porte qu'un motif, le premier rencontré.
--    jours_illisible (non convertible en entier) et jours_invalide (entier négatif) sont
--    distingués : ils ne se corrigent pas de la même façon à la source.
INSERT INTO chu.silver.rejets
SELECT 'hospitalisation', 'hospitalisation',
       CASE
         WHEN num_hospitalisation IS NULL
              OR trim(num_hospitalisation) = ''                     THEN 'num_hospitalisation_vide'
         WHEN try_to_date(trim(date_entree), 'dd/MM/yyyy') IS NULL                THEN 'date_entree_illisible'
         WHEN try_cast(trim(jour_hospitalisation) AS INT) IS NULL    THEN 'jours_illisible'
         ELSE 'jours_invalide'
       END,
       num_hospitalisation,
       CASE
         WHEN num_hospitalisation IS NULL
              OR trim(num_hospitalisation) = ''                     THEN NULL
         WHEN try_to_date(trim(date_entree), 'dd/MM/yyyy') IS NULL                THEN date_entree
         ELSE jour_hospitalisation
       END,
       _fichier_source, _id_lot, current_timestamp()
FROM chu.bronze.hospitalisation
WHERE num_hospitalisation IS NULL
   OR trim(num_hospitalisation) = ''
   OR try_to_date(trim(date_entree), 'dd/MM/yyyy') IS NULL
   OR try_cast(trim(jour_hospitalisation) AS INT) IS NULL
   OR try_cast(trim(jour_hospitalisation) AS INT) < 0;

-- COMMAND ----------

-- 3. Construire la table Silver avec les lignes valides.
--    Le WHERE est exactement le complément de celui des rejets : aucune ligne
--    ne peut être à la fois rejetée et chargée, ni disparaître sans trace.
CREATE OR REPLACE TABLE chu.silver.hospitalisation AS
SELECT num_hospitalisation, patient_id, finess, code_diag, date_entree, jours FROM (
  SELECT trim(num_hospitalisation)                   AS num_hospitalisation,
         trim(patient_id)                            AS patient_id,
         upper(trim(finess))                         AS finess,
         upper(trim(code_diag))                      AS code_diag,
         try_to_date(trim(date_entree), 'dd/MM/yyyy')              AS date_entree,
         try_cast(trim(jour_hospitalisation) AS INT) AS jours,
         row_number() OVER (PARTITION BY trim(num_hospitalisation)
                            ORDER BY _date_chargement DESC) AS rn
  FROM chu.bronze.hospitalisation
  WHERE num_hospitalisation IS NOT NULL AND trim(num_hospitalisation) <> ''
) WHERE rn = 1 AND date_entree IS NOT NULL AND jours IS NOT NULL AND jours >= 0;

-- COMMAND ----------

-- Réinitialisation du Gold : à lancer UNE FOIS, à la main, avant le premier DDL Gold.
-- Ne fait pas partie de run_pipeline. Les faits d'abord : ils référencent les dimensions.
DROP TABLE IF EXISTS chu.gold.fait_hospitalisation;
DROP TABLE IF EXISTS chu.gold.fait_deces;
DROP TABLE IF EXISTS chu.gold.fait_satisfaction;
DROP TABLE IF EXISTS chu.gold.pont_professionnel_etablissement;
DROP TABLE IF EXISTS chu.gold.dim_patient;
DROP TABLE IF EXISTS chu.gold.dim_diagnostic;
DROP TABLE IF EXISTS chu.gold.dim_temps;
DROP TABLE IF EXISTS chu.gold.dim_etablissement;
DROP TABLE IF EXISTS chu.gold.dim_region;
DROP TABLE IF EXISTS chu.gold.dim_enquete;

SHOW TABLES IN chu.gold;