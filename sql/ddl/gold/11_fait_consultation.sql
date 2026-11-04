-- Gold - DDL fait_consultation : grain = une consultation.
-- Alimente les indicateurs 2 (par diagnostic) et 6 (par professionnel) ;
-- l'indicateur 1 (par établissement) passe par pont_professionnel_etablissement.
CREATE TABLE IF NOT EXISTS chu.gold.fait_consultation (
  consultation_id   STRING NOT NULL COMMENT 'Numéro de consultation (Num_consultation), clé naturelle',
  patient_sk        BIGINT NOT NULL COMMENT 'Patient ; -1 si introuvable dans dim_patient',
  professionnel_sk  BIGINT NOT NULL COMMENT 'Professionnel (RPPS) ; -1 si introuvable dans dim_professionnel',
  diagnostic_sk     BIGINT NOT NULL COMMENT 'Diagnostic ; -1 si introuvable dans dim_diagnostic',
  date_sk           INT    NOT NULL COMMENT 'Date de la consultation (AAAAMMJJ)',
  duree_minutes     INT             COMMENT 'Durée en minutes (consultations de nuit corrigées en Silver)',
  nb_consultations  INT    NOT NULL COMMENT 'Toujours 1 : on l''additionne pour compter les consultations',
  CONSTRAINT pk_fait_consultation PRIMARY KEY (consultation_id),
  CONSTRAINT fk_fc_patient       FOREIGN KEY (patient_sk)       REFERENCES chu.gold.dim_patient (patient_sk),
  CONSTRAINT fk_fc_professionnel FOREIGN KEY (professionnel_sk) REFERENCES chu.gold.dim_professionnel (professionnel_sk),
  CONSTRAINT fk_fc_diagnostic    FOREIGN KEY (diagnostic_sk)    REFERENCES chu.gold.dim_diagnostic (diagnostic_sk),
  CONSTRAINT fk_fc_date          FOREIGN KEY (date_sk)          REFERENCES chu.gold.dim_temps (date_sk)
) COMMENT 'Gold - faits des consultations';