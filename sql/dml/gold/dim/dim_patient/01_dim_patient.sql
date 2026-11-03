-- Databricks notebook source
-- Gold - dim_patient (identifiant déjà pseudonymisé à la source)
CREATE SCHEMA IF NOT EXISTS chu.gold;

-- COMMAND ----------
CREATE OR REPLACE TABLE chu.gold.dim_patient (
  patient_sk      BIGINT GENERATED ALWAYS AS IDENTITY,
  patient_id      STRING NOT NULL,
  sexe            STRING,
  annee_naissance INT,
  CONSTRAINT pk_dim_patient PRIMARY KEY (patient_sk)
) USING DELTA;

-- COMMAND ----------
INSERT INTO chu.gold.dim_patient (patient_id, sexe, annee_naissance)
SELECT patient_id, sexe, annee_naissance FROM chu.silver.patient;
