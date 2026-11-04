-- Silver - référentiel géographique : régions et départements.
-- Base : COG INSEE au 1er janvier 2026 (chu.bronze.cog_region, chu.bronze.cog_departement),
-- complété par des lignes « projet » pour les codes historiques et hors région
-- rencontrés dans les décès (décision documentée dans docs/decisions/).
-- Les codes non rattachables (vide, 00, 96, 970) restent absents : membre « inconnu » en Gold.

-- 1. Les zones : régions INSEE + zones hors région
CREATE OR REPLACE TABLE chu.silver.ref_region (
  code_region      STRING NOT NULL COMMENT 'Code région INSEE (découpage 2016), ou COM / ETR',
  libelle_region   STRING NOT NULL COMMENT 'Libellé officiel INSEE, ou libellé de la zone projet',
  type_zone        STRING NOT NULL COMMENT 'region | hors_region | etranger',
  source           STRING NOT NULL COMMENT 'COG INSEE 2026 ou projet',
  _fichier_source  STRING          COMMENT 'Fichier Bronze d''origine (NULL pour les lignes projet)',
  _id_lot          STRING          COMMENT 'Lot de chargement Bronze (NULL pour les lignes projet)'
) COMMENT 'Silver - régions INSEE et zones hors région ; base de dim_region';

INSERT INTO chu.silver.ref_region
SELECT trim(REG), trim(LIBELLE), 'region', 'COG INSEE 2026', _fichier_source, _id_lot
FROM chu.bronze.cog_region;

INSERT INTO chu.silver.ref_region VALUES
  ('COM', 'Outre-mer hors région', 'hors_region', 'projet', NULL, NULL),
  ('ETR', 'Étranger',              'etranger',    'projet', NULL, NULL);

-- 2. La table de passage département -> zone
CREATE OR REPLACE TABLE chu.silver.ref_departement (
  code_departement     STRING NOT NULL COMMENT 'Code département (2A, 2B, 971...) ou code historique',
  libelle_departement  STRING NOT NULL COMMENT 'Libellé officiel INSEE, ou libellé projet',
  code_region          STRING NOT NULL COMMENT 'Zone de rattachement, clé de silver.ref_region',
  source               STRING NOT NULL COMMENT 'COG INSEE 2026 ou projet',
  _fichier_source      STRING          COMMENT 'Fichier Bronze d''origine (NULL pour les lignes projet)',
  _id_lot              STRING          COMMENT 'Lot de chargement Bronze (NULL pour les lignes projet)'
) COMMENT 'Silver - départements et codes historiques, rattachés à une zone de silver.ref_region';

INSERT INTO chu.silver.ref_departement
SELECT trim(DEP), trim(LIBELLE), trim(REG), 'COG INSEE 2026', _fichier_source, _id_lot
FROM chu.bronze.cog_departement;

INSERT INTO chu.silver.ref_departement VALUES
  ('20',  'Corse (code antérieur à 1976)',              '94',  'projet', NULL, NULL),
  ('975', 'Saint-Pierre-et-Miquelon',                   'COM', 'projet', NULL, NULL),
  ('977', 'Saint-Barthélemy',                           'COM', 'projet', NULL, NULL),
  ('978', 'Saint-Martin',                               'COM', 'projet', NULL, NULL),
  ('98',  'Collectivités du Pacifique et TAAF',         'COM', 'projet', NULL, NULL),
  ('99',  'Étranger',                                   'ETR', 'projet', NULL, NULL);