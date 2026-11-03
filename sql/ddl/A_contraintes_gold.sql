-- Databricks notebook source
-- Membre A - Cles primaires et etrangeres (informatives sur Databricks, non appliquees)
-- A lancer apres A_07 a A_10. Si une contrainte existe deja, passer la cellule.

-- COMMAND ----------
ALTER TABLE chu.gold.dim_diagnostic ALTER COLUMN diagnostic_sk SET NOT NULL;

-- COMMAND ----------
ALTER TABLE chu.gold.dim_diagnostic ADD CONSTRAINT pk_dim_diagnostic PRIMARY KEY (diagnostic_sk);

-- COMMAND ----------
ALTER TABLE chu.gold.dim_temps ALTER COLUMN date_sk SET NOT NULL;

-- COMMAND ----------
ALTER TABLE chu.gold.dim_temps ADD CONSTRAINT pk_dim_temps PRIMARY KEY (date_sk);

-- COMMAND ----------
ALTER TABLE chu.gold.fait_hospitalisation ALTER COLUMN hospitalisation_id SET NOT NULL;

-- COMMAND ----------
ALTER TABLE chu.gold.fait_hospitalisation ADD CONSTRAINT pk_fait_hospitalisation PRIMARY KEY (hospitalisation_id);

-- COMMAND ----------
ALTER TABLE chu.gold.fait_hospitalisation ADD CONSTRAINT fk_fh_patient
FOREIGN KEY (patient_sk) REFERENCES chu.gold.dim_patient (patient_sk);

-- COMMAND ----------
ALTER TABLE chu.gold.fait_hospitalisation ADD CONSTRAINT fk_fh_diagnostic
FOREIGN KEY (diagnostic_sk) REFERENCES chu.gold.dim_diagnostic (diagnostic_sk);

-- COMMAND ----------
ALTER TABLE chu.gold.fait_hospitalisation ADD CONSTRAINT fk_fh_date_entree
FOREIGN KEY (date_entree_sk) REFERENCES chu.gold.dim_temps (date_sk);

-- COMMAND ----------
ALTER TABLE chu.gold.fait_hospitalisation ADD CONSTRAINT fk_fh_date_sortie
FOREIGN KEY (date_sortie_sk) REFERENCES chu.gold.dim_temps (date_sk);
