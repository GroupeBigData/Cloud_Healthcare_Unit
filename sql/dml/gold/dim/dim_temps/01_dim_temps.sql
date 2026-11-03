-- Databricks notebook source
-- Gold - dim_temps : calendrier généré par code (pas de Bronze ni de Silver)
CREATE OR REPLACE TABLE chu.gold.dim_temps
COMMENT 'Dimension calendrier generee, cle date_sk au format yyyyMMdd'
AS
SELECT
  CAST(date_format(d, 'yyyyMMdd') AS INT) AS date_sk,
  d                                       AS date_complete,
  year(d)                                 AS annee,
  quarter(d)                              AS trimestre,
  month(d)                                AS mois,
  date_format(d, 'MMMM')                  AS nom_mois,
  weekofyear(d)                           AS semaine,
  dayofweek(d)                            AS jour_semaine,
  dayofweek(d) IN (1, 7)                  AS est_weekend
FROM (SELECT explode(sequence(DATE'2010-01-01', DATE'2025-12-31', INTERVAL 1 DAY)) AS d);
