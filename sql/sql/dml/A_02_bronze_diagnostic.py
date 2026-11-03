# Databricks notebook source
# Membre A - Bronze diagnostic
# Source : /Volumes/chu/bronze/landing/postgres/diagnostic/diagnostic.csv (separateur ;, avec en-tete)
# Cible  : chu.bronze.diagnostic

# COMMAND ----------
from pyspark.sql import functions as F

raw = (spark.read
       .option("header", "false")
       .option("sep", ";")
       .option("quote", '"')
       .csv("/Volumes/chu/bronze/landing/postgres/diagnostic/diagnostic.csv"))

df_diag = (raw
           .filter(F.col("_c0") != "Code_diag")
           .toDF("code_diag", "diagnostic"))

(df_diag
 .withColumn("_ingest_ts", F.current_timestamp())
 .withColumn("_source_file", F.lit("diagnostic.csv"))
 .write.mode("overwrite").format("delta")
 .saveAsTable("chu.bronze.diagnostic"))

print(spark.table("chu.bronze.diagnostic").count())  # attendu : 15490
