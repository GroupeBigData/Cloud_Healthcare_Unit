-- Databricks notebook source
-- Gold - DML dim_patient. Prérequis : sql/ddl/gold/02_dim_patient.sql
INSERT OVERWRITE chu.gold.dim_patient (patient_id, sexe, annee_naissance)
SELECT patient_id, sexe, annee_naissance
FROM chu.silver.patient;

INSERT INTO chu.gold.dim_patient (patient_sk, patient_id, sexe, annee_naissance)
VALUES (-1, 'INCONNU', 'INCONNU', NULL);