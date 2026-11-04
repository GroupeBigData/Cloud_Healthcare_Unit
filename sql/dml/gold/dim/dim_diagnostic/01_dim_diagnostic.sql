-- Databricks notebook source
-- Gold - DML dim_diagnostic. Prérequis : sql/ddl/gold/03_dim_diagnostic.sql
INSERT OVERWRITE chu.gold.dim_diagnostic (code_diag, libelle, lettre_cim10)
SELECT code_diag, diagnostic, left(code_diag, 1)
FROM chu.silver.diagnostic;

INSERT INTO chu.gold.dim_diagnostic (diagnostic_sk, code_diag, libelle, lettre_cim10)
VALUES (-1, 'INCONNU', 'Diagnostic inconnu', NULL);