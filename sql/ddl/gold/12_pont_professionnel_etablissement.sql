-- Gold - DDL pont professionnel <-> établissement : répartit les consultations d'un
-- professionnel entre ses structures d'exercice (indicateur 1).
-- Propriété garantie par le DML : pour chaque professionnel, la somme des poids vaut 1.
CREATE TABLE IF NOT EXISTS chu.gold.pont_professionnel_etablissement (
  professionnel_sk  BIGINT NOT NULL COMMENT 'Professionnel (dim_professionnel)',
  etablissement_sk  BIGINT NOT NULL COMMENT 'Structure d''exercice ; -1 si le professionnel n''a aucune structure connue',
  poids             DOUBLE NOT NULL COMMENT 'Part des consultations attribuée à cette structure ; somme = 1 par professionnel',
  modes_exercice    STRING          COMMENT 'Modes d''exercice dans cette structure',
  CONSTRAINT pk_pont_prof_etab PRIMARY KEY (professionnel_sk, etablissement_sk),
  CONSTRAINT fk_pont_professionnel FOREIGN KEY (professionnel_sk) REFERENCES chu.gold.dim_professionnel (professionnel_sk),
  CONSTRAINT fk_pont_etablissement FOREIGN KEY (etablissement_sk) REFERENCES chu.gold.dim_etablissement (etablissement_sk)
) COMMENT 'Gold - table pont pondérée professionnel <-> établissement';