-- PROPOSITION pour le contrat Gold - à valider en synchro 1 avant exécution.
-- Grain : un établissement géographique x une enquête x une campagne.

CREATE OR REPLACE TABLE chu.gold.dim_enquete (
  enquete_sk     INT     NOT NULL COMMENT 'Clé de substitution ; -1 = inconnue',
  code_enquete   STRING  NOT NULL COMMENT '48H_MCO ou CA_MCO',
  libelle        STRING           COMMENT 'Libellé lisible de l''enquête',
  CONSTRAINT pk_dim_enquete PRIMARY KEY (enquete_sk)
) COMMENT 'Enquêtes de satisfaction e-Satis (HAS)';

CREATE OR REPLACE TABLE chu.gold.fait_satisfaction (
  etablissement_sk  BIGINT       NOT NULL COMMENT 'Établissement (dim C) ; -1 si FINESS absent du référentiel',
  region_sk         BIGINT       NOT NULL COMMENT 'Région (dim C), issue du libellé HAS ou du préfixe FINESS',
  enquete_sk        INT          NOT NULL COMMENT 'Enquête +48h ou CA',
  date_sk           INT          NOT NULL COMMENT '1er janvier de la campagne (AAAA0101), dim_temps (A)',
  finess_geo        STRING       NOT NULL COMMENT 'Dimension dégénérée : FINESS géographique, pour la traçabilité',
  classement        STRING                COMMENT 'Classe HAS : A, B, C, D, DI, NR, NV',
  est_classe        BOOLEAN      NOT NULL COMMENT 'Vrai si classe A à D : seules ces lignes entrent dans l''indicateur 8',
  score_global      DECIMAL(5,2)          COMMENT 'Score de satisfaction globale ajusté (/100)',
  nb_reponses       INT                   COMMENT 'Nombre de réponses exploitables',
  score_x_reponses  DECIMAL(12,2)         COMMENT 'score_global x nb_reponses : numérateur additif de la moyenne pondérée',
  taux_reco_brut    DECIMAL(5,2)          COMMENT '% de patients recommandant certainement l''établissement',
  CONSTRAINT pk_fait_satisfaction PRIMARY KEY (finess_geo, enquete_sk, date_sk),
  CONSTRAINT fk_fs_etab    FOREIGN KEY (etablissement_sk) REFERENCES chu.gold.dim_etablissement,
  CONSTRAINT fk_fs_region  FOREIGN KEY (region_sk)        REFERENCES chu.gold.dim_region,
  CONSTRAINT fk_fs_enquete FOREIGN KEY (enquete_sk)       REFERENCES chu.gold.dim_enquete,
  CONSTRAINT fk_fs_temps   FOREIGN KEY (date_sk)          REFERENCES chu.gold.dim_temps
) COMMENT 'Faits de satisfaction e-Satis - alimente l''indicateur 8';