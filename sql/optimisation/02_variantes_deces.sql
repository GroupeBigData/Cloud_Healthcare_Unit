-- Databricks notebook source
-- Optimisation physique de fait_deces : trois copies de test dans chu.bench (le Gold n'est pas modifié).
-- V0 référence : même organisation que le Gold (ni partitionnement, ni clustering).
-- V1 partitionnement par année : l'approche classique, pour mesurer son coût à ce volume.
-- V2 liquid clustering (annee_deces, region_sk) avec des fichiers cibles de 8 Mo :
--    la cible par défaut (256 Mo) laisserait la table de 61,6 Mio dans un seul fichier.
-- Les trois copies ont les mêmes colonnes : les requêtes de benchmark sont identiques.

-- COMMAND ----------

CREATE OR REPLACE TABLE chu.bench.deces_reference
COMMENT 'Benchmark V0 - copie de gold.fait_deces sans organisation physique'
AS SELECT *, date_sk DIV 10000 AS annee_deces FROM chu.gold.fait_deces;

-- COMMAND ----------

CREATE OR REPLACE TABLE chu.bench.deces_partition
PARTITIONED BY (annee_deces)
COMMENT 'Benchmark V1 - partitionnement par année de décès'
AS SELECT *, date_sk DIV 10000 AS annee_deces FROM chu.gold.fait_deces;

-- COMMAND ----------

CREATE OR REPLACE TABLE chu.bench.deces_cluster
CLUSTER BY (annee_deces, region_sk)
COMMENT 'Benchmark V2 - liquid clustering (annee_deces, region_sk), fichiers cibles de 8 Mo'
TBLPROPERTIES ('delta.targetFileSize' = '8mb')
AS SELECT *, date_sk DIV 10000 AS annee_deces FROM chu.gold.fait_deces;

-- COMMAND ----------

-- Réorganise V2 selon ses colonnes de clustering et sa taille de fichier cible
OPTIMIZE chu.bench.deces_cluster;

-- COMMAND ----------

DESCRIBE DETAIL chu.bench.deces_reference;

-- COMMAND ----------

DESCRIBE DETAIL chu.bench.deces_partition;

-- COMMAND ----------

DESCRIBE DETAIL chu.bench.deces_cluster;