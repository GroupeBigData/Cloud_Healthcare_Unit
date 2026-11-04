-- Gold - DDL fait_deces : grain = un décès (INSEE, 1882-2020). Alimente l'indicateur 7.
-- Pas de clé patient (décision D3) ; pas de clé primaire (aucun identifiant de décès).
-- Construite sans clustering : version de référence (« avant ») du benchmark.
CREATE TABLE IF NOT EXISTS chu.gold.fait_deces (
  date_sk            INT    NOT NULL COMMENT 'Date du décès (AAAAMMJJ)',
  region_sk          BIGINT NOT NULL COMMENT 'Zone du lieu de décès ; -1 si département non rattachable',
  sexe               STRING NOT NULL COMMENT 'M ou F (dimension dégénérée)',
  age_deces          INT             COMMENT 'Âge au décès ; NULL si année de naissance inconnue',
  tranche_age        STRING NOT NULL COMMENT 'Tranche de 10 ans (00-09 ans ... 90 ans et +) ou Inconnu',
  precision_date     STRING NOT NULL COMMENT 'jour, mois ou annee : précision de la date source',
  departement_deces  STRING          COMMENT 'Département du lieu de décès (dimension dégénérée)',
  nb_deces           INT    NOT NULL COMMENT 'Toujours 1 : on l''additionne pour compter les décès',
  CONSTRAINT fk_fd_date   FOREIGN KEY (date_sk)   REFERENCES chu.gold.dim_temps (date_sk),
  CONSTRAINT fk_fd_region FOREIGN KEY (region_sk) REFERENCES chu.gold.dim_region (region_sk)
) COMMENT 'Gold - faits des décès INSEE, anonymisés, sans lien avec les patients';