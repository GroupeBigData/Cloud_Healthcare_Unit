-- Correspondance des libellés de région écrits par la HAS -> codes région INSEE (découpage 2016).
-- Océan Indien est absent : il recouvre deux régions, départagées par le préfixe FINESS en Silver.

CREATE OR REPLACE TABLE chu.silver.ref_region_esatis (
  libelle_has  STRING NOT NULL COMMENT 'Libellé de région tel qu''écrit dans les fichiers e-Satis',
  code_region  STRING NOT NULL COMMENT 'Code région INSEE, découpage en vigueur depuis 2016'
) COMMENT 'Référentiel projet : libellés HAS -> codes région INSEE (Océan Indien traité par préfixe FINESS)';

INSERT INTO chu.silver.ref_region_esatis VALUES
  ('Auvergne-Rhône-Alpes',     '84'),
  ('Bourgogne-Franche-Comté',  '27'),
  ('Bretagne',                 '53'),
  ('Centre-Val de Loire',      '24'),
  ('Corse',                    '94'),
  ('Grand Est',                '44'),
  ('Guadeloupe',               '01'),
  ('Guyane',                   '03'),
  ('Hauts de France',          '32'),
  ('Ile de France',            '11'),
  ('Martinique',               '02'),
  ('Normandie',                '28'),
  ('Nouvelle Aquitaine',       '75'),
  ('Occitanie',                '76'),
  ('PACA',                     '93'),
  ('Pays de la Loire',         '52');