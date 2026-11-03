# Databricks notebook source
# Bronze - patient : contenu inchangé, tout en texte, + traçabilité.
# Source : /Volumes/chu/bronze/landing/postgres/patient/ (CSV, séparateur ;, avec en-tête)
# Cible  : chu.bronze.patient
# Colonnes techniques communes au projet : _fichier_source, _date_chargement, _id_lot.

# COMMAND ----------
from datetime import datetime

from pyspark.sql import functions as F

DOSSIER = "/Volumes/chu/bronze/landing/postgres/patient/"
ID_LOT = datetime.now().strftime("%Y%m%d_%H%M%S")   # un seul lot pour toute l'exécution

# L'en-tête est lu comme tel : les colonnes sont nommées, jamais repérées par leur position.
# Un renommage en amont fait donc échouer le select au lieu de décaler silencieusement les données.
df = (spark.read
      .option("header", "true")
      .option("sep", ";")
      .csv(DOSSIER)
      .select(
          F.col("id_patient_pseudo").cast("string").alias("patient_id"),
          F.col("Sexe").cast("string").alias("sexe"),
          F.col("annee_naissance").cast("string").alias("annee_naissance"),
          F.col("_metadata.file_path").alias("_fichier_source"),
          F.current_timestamp().alias("_date_chargement"),
          F.lit(ID_LOT).alias("_id_lot"),
      ))

# Rafraîchissement complet : l'extraction PostgreSQL produit un instantané, pas un delta.
(df.write.mode("overwrite").format("delta")
   .saveAsTable("chu.bronze.patient"))

print(f"lot {ID_LOT} - {spark.table('chu.bronze.patient').count():,} lignes")  # attendu : 100 000
