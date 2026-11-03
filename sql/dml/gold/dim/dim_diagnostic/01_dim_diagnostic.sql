-- Databricks notebook source
-- Gold - dim_diagnostic (clé de substitution calculée par row_number)
CREATE OR REPLACE TABLE chu.gold.dim_diagnostic AS
SELECT row_number() OVER (ORDER BY code_diag) AS diagnostic_sk,
       code_diag,
       diagnostic,
       left(code_diag, 1) AS chapitre_cim10
FROM chu.silver.diagnostic;
