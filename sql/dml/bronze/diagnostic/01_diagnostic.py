# Databricks notebook source
# /// script
# [tool.databricks.environment]
# environment_version = "6"
# ///
# Bronze - diagnostic : contenu inchangé, tout en texte, + traçabilité.
# Source : /Volumes/chu/bronze/landing/postgres/diagnostic/ (CSV, séparateur ;, avec en-tête)
# Cible  : chu.bronze.diagnostic
# Colonnes techniques communes au projet : _fichier_source, _date_chargement, _id_lot.

# COMMAND ----------

from datetime import datetime

from pyspark.sql import functions as F

DOSSIER = "/Volumes/chu/bronze/landing/postgres/diagnostic/"
ID_LOT = datetime.now().strftime("%Y%m%d_%H%M%S")   # un seul lot pour toute l'exécution

# L'en-tête est lu comme tel : les colonnes sont nommées, jamais repérées par leur position.
df = (spark.read
      .option("header", "true")
      .option("sep", ";")
      .option("quote", '"')
      .csv(DOSSIER)
      .select(
          F.col("Code_diag").cast("string").alias("code_diag"),
          F.col("Diagnostic").cast("string").alias("diagnostic"),
          F.col("_metadata.file_path").alias("_fichier_source"),
          F.current_timestamp().alias("_date_chargement"),
          F.lit(ID_LOT).alias("_id_lot"),
      ))

# Rafraîchissement complet : l'extraction PostgreSQL produit un instantané, pas un delta.
(df.write.mode("overwrite").format("delta")
   .saveAsTable("chu.bronze.diagnostic"))

print(f"lot {ID_LOT} - {spark.table('chu.bronze.diagnostic').count():,} lignes")  # attendu : 15 490