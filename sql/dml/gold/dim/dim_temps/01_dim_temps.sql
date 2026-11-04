-- Databricks notebook source
-- Gold - DML dim_temps : calendrier généré (aucune source Bronze ni Silver).
-- Prérequis : sql/ddl/gold/01_dim_temps.sql
INSERT OVERWRITE chu.gold.dim_temps
SELECT
  CAST(date_format(d, 'yyyyMMdd') AS INT),
  d,
  year(d),
  CAST(floor(year(d) / 10) * 10 AS INT),
  quarter(d),
  month(d),
  element_at(array('janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet',
                   'août', 'septembre', 'octobre', 'novembre', 'décembre'), month(d)),
  weekofyear(d),
  weekday(d) + 1,
  element_at(array('lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'),
             weekday(d) + 1),
  weekday(d) >= 5
FROM (SELECT explode(sequence(DATE'1880-01-01', DATE'2025-12-31', INTERVAL 1 DAY)) AS d);

INSERT INTO chu.gold.dim_temps VALUES
  (-1, NULL, NULL, NULL, NULL, NULL, 'Inconnu', NULL, NULL, 'Inconnu', NULL);