-- Databricks notebook source
-- Membre A - Silver diagnostic : nettoyage des codes, rejets, dedoublonnage

-- COMMAND ----------
CREATE OR REPLACE TABLE chu.silver.rejets_diagnostic AS
SELECT code_diag, diagnostic, _ingest_ts, 'code_nul' AS motif
FROM chu.bronze.diagnostic
WHERE code_diag IS NULL OR trim(code_diag) = '';

-- COMMAND ----------
CREATE OR REPLACE TABLE chu.silver.diagnostic AS
SELECT code_diag, diagnostic FROM (
  SELECT upper(trim(code_diag)) AS code_diag,
         trim(diagnostic)       AS diagnostic,
         row_number() OVER (PARTITION BY upper(trim(code_diag)) ORDER BY _ingest_ts DESC) AS rn
  FROM chu.bronze.diagnostic
  WHERE code_diag IS NOT NULL AND trim(code_diag) <> ''
) WHERE rn = 1;
