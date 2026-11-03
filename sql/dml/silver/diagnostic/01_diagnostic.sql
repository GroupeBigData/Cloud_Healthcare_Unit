-- Databricks notebook source
-- Silver - diagnostic : nettoyage des codes, rejets, dédoublonnage.
-- Prérequis : sql/dml/silver/00_rejets.sql (table commune chu.silver.rejets).

-- COMMAND ----------
-- 1. Effacer les anciens rejets de CETTE table (et seulement ceux-là)
DELETE FROM chu.silver.rejets WHERE table_cible = 'diagnostic';

-- COMMAND ----------
-- 2. Écrire les nouveaux rejets dans la table commune
--    cle = code_diag : vide ou nul, c'est précisément le motif du rejet.
--    valeur = libellé : seul élément permettant de retrouver la ligne en Bronze.
INSERT INTO chu.silver.rejets
SELECT 'diagnostic', 'diagnostic', 'code_diag_vide',
       code_diag, diagnostic,
       _fichier_source, _id_lot, current_timestamp()
FROM chu.bronze.diagnostic
WHERE code_diag IS NULL OR trim(code_diag) = '';

-- COMMAND ----------
-- 3. Construire la table Silver avec les lignes valides
CREATE OR REPLACE TABLE chu.silver.diagnostic AS
SELECT code_diag, diagnostic FROM (
  SELECT upper(trim(code_diag)) AS code_diag,
         trim(diagnostic)       AS diagnostic,
         row_number() OVER (PARTITION BY upper(trim(code_diag))
                            ORDER BY _date_chargement DESC) AS rn
  FROM chu.bronze.diagnostic
  WHERE code_diag IS NOT NULL AND trim(code_diag) <> ''
) WHERE rn = 1;
