# Databricks notebook source
# Membre A - Bronze patient
# Source : /Volumes/chu/bronze/landing/postgres/patient/patient.csv (separateur ;, avec en-tete)
# Cible  : chu.bronze.patient (tout en texte, colonnes techniques _ingest_ts / _source_file)

# COMMAND ----------
from pyspark.sql import functions as F

raw = (spark.read
       .option("header", "false")
       .option("sep", ";")
       .csv("/Volumes/chu/bronze/landing/postgres/patient/patient.csv"))

# l'en-tete est lu comme une donnee : on le filtre puis on nomme les colonnes
df_patient = (raw
              .filter(F.col("_c0") != "id_patient_pseudo")
              .toDF("patient_id", "sexe", "annee_naissance"))

(df_patient
 .withColumn("_ingest_ts", F.current_timestamp())
 .withColumn("_source_file", F.lit("patient.csv"))
 .write.mode("overwrite").format("delta")
 .saveAsTable("chu.bronze.patient"))

print(spark.table("chu.bronze.patient").count())  # attendu : 100000
