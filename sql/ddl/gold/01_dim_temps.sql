-- Gold - DDL dim_temps : calendrier de 1880 à 2025 (décès depuis 1882), clé AAAAMMJJ.
CREATE TABLE IF NOT EXISTS chu.gold.dim_temps (
  date_sk        INT     NOT NULL COMMENT 'Clé AAAAMMJJ ; -1 = date inconnue',
  date_complete  DATE             COMMENT 'Date du jour (NULL pour -1)',
  annee          INT              COMMENT 'Année',
  decennie       INT              COMMENT 'Décennie (1880, 1890...), pour l''historique des décès',
  trimestre      INT              COMMENT 'Trimestre (1 à 4)',
  mois           INT              COMMENT 'Mois (1 à 12)',
  nom_mois       STRING           COMMENT 'Nom du mois en français',
  semaine_iso    INT              COMMENT 'Numéro de semaine ISO',
  jour_semaine   INT              COMMENT '1 = lundi ... 7 = dimanche (norme ISO)',
  nom_jour       STRING           COMMENT 'Nom du jour en français',
  est_weekend    BOOLEAN          COMMENT 'Vrai le samedi et le dimanche',
  CONSTRAINT pk_dim_temps PRIMARY KEY (date_sk)
) COMMENT 'Gold - dimension calendrier, générée ; couvre 1880-01-01 à 2025-12-31';