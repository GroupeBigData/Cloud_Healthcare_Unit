-- Gold - DDL fait_satisfaction : grain = un établissement géographique x une enquête x une campagne.
-- Alimente l'indicateur 8. Les scores ne se comparent ni entre enquêtes, ni entre campagnes.
CREATE TABLE IF NOT EXISTS chu.gold.fait_satisfaction (
  etablissement_sk  BIGINT        NOT NULL COMMENT 'Établissement ; -1 si FINESS absent du référentiel',
  region_sk         BIGINT        NOT NULL COMMENT 'Région issue du libellé HAS ou du préfixe FINESS',
  enquete_sk        BIGINT        NOT NULL COMMENT 'Enquête +48h ou CA',
  date_sk           INT           NOT NULL COMMENT '1er janvier de la campagne (AAAA0101)',
  finess_geo        STRING        NOT NULL COMMENT 'FINESS géographique (dimension dégénérée, traçabilité)',
  classement        STRING                 COMMENT 'Classe HAS : A, B, C, D, DI, NR, NV',
  est_classe        BOOLEAN       NOT NULL COMMENT 'Vrai si classe A à D : seules ces lignes entrent dans l''indicateur 8',
  score_global      DECIMAL(5,2)           COMMENT 'Score de satisfaction globale ajusté (/100)',
  nb_reponses       INT                    COMMENT 'Nombre de réponses exploitables',
  score_x_reponses  DECIMAL(12,2)          COMMENT 'score_global x nb_reponses : numérateur additif de la moyenne pondérée',
  taux_reco_brut    DECIMAL(5,2)           COMMENT '% de patients recommandant certainement l''établissement',
  CONSTRAINT pk_fait_satisfaction PRIMARY KEY (finess_geo, enquete_sk, date_sk),
  CONSTRAINT fk_fs_etablissement FOREIGN KEY (etablissement_sk) REFERENCES chu.gold.dim_etablissement (etablissement_sk),
  CONSTRAINT fk_fs_region        FOREIGN KEY (region_sk)        REFERENCES chu.gold.dim_region (region_sk),
  CONSTRAINT fk_fs_enquete       FOREIGN KEY (enquete_sk)       REFERENCES chu.gold.dim_enquete (enquete_sk),
  CONSTRAINT fk_fs_date          FOREIGN KEY (date_sk)          REFERENCES chu.gold.dim_temps (date_sk)
) COMMENT 'Gold - faits de satisfaction e-Satis (HAS) ; alimente l''indicateur 8';