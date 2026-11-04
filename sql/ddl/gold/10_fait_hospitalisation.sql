-- Gold - DDL fait_hospitalisation : grain = un séjour hospitalier.
-- Alimente les indicateurs 3 (hospitalisation globale), 4 (par diagnostic), 5 (par sexe et âge).
CREATE TABLE IF NOT EXISTS chu.gold.fait_hospitalisation (
  hospitalisation_id   STRING NOT NULL COMMENT 'Numéro de séjour (Num_Hospitalisation), clé naturelle',
  patient_sk           BIGINT NOT NULL COMMENT 'Patient ; -1 si introuvable dans dim_patient',
  diagnostic_sk        BIGINT NOT NULL COMMENT 'Diagnostic ; -1 si introuvable dans dim_diagnostic',
  etablissement_sk     BIGINT NOT NULL COMMENT 'Établissement ; -1 si introuvable dans dim_etablissement',
  date_entree_sk       INT    NOT NULL COMMENT 'Date d''entrée (AAAAMMJJ)',
  date_sortie_sk       INT    NOT NULL COMMENT 'Date de sortie = entrée + durée (AAAAMMJJ)',
  duree_sejour_jours   INT             COMMENT 'Durée du séjour en jours',
  age_entree           INT             COMMENT 'Âge à l''entrée = année d''entrée - année de naissance ; NULL si inconnue',
  tranche_age          STRING NOT NULL COMMENT 'Tranche de 10 ans (00-09 ans ... 90 ans et +), Inconnu ou Incohérent',
  nb_hospitalisations  INT    NOT NULL COMMENT 'Toujours 1 : on l''additionne pour compter les séjours',
  CONSTRAINT pk_fait_hospitalisation PRIMARY KEY (hospitalisation_id),
  CONSTRAINT fk_fh_patient       FOREIGN KEY (patient_sk)       REFERENCES chu.gold.dim_patient (patient_sk),
  CONSTRAINT fk_fh_diagnostic    FOREIGN KEY (diagnostic_sk)    REFERENCES chu.gold.dim_diagnostic (diagnostic_sk),
  CONSTRAINT fk_fh_etablissement FOREIGN KEY (etablissement_sk) REFERENCES chu.gold.dim_etablissement (etablissement_sk),
  CONSTRAINT fk_fh_date_entree   FOREIGN KEY (date_entree_sk)   REFERENCES chu.gold.dim_temps (date_sk),
  CONSTRAINT fk_fh_date_sortie   FOREIGN KEY (date_sortie_sk)   REFERENCES chu.gold.dim_temps (date_sk)
) COMMENT 'Gold - faits des séjours hospitaliers';