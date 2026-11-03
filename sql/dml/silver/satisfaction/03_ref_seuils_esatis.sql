-- Seuils des classes e-Satis, recopiés des lexiques de la HAS.
-- Convention : borne_min incluse, borne_max exclue ; NULL = pas de borne de ce côté.

CREATE OR REPLACE TABLE chu.silver.ref_seuils_esatis (
  millesime  INT          NOT NULL COMMENT 'Campagne e-Satis',
  enquete    STRING       NOT NULL COMMENT '48H_MCO ou CA_MCO',
  classe     STRING       NOT NULL COMMENT 'A, B, C ou D',
  borne_min  DECIMAL(5,2)          COMMENT 'Score minimal, inclus (NULL pour la classe D)',
  borne_max  DECIMAL(5,2)          COMMENT 'Score maximal, exclu (NULL pour la classe A)',
  source     STRING       NOT NULL COMMENT 'Lexique HAS d''où viennent les seuils'
) COMMENT 'Référentiel projet : seuils des classes A-D par enquête et par campagne';

INSERT INTO chu.silver.ref_seuils_esatis VALUES
  -- +48h MCO : identiques en 2017, 2019 et 2020
  (2017, '48H_MCO', 'A', 77.3, NULL, 'ESATIS48H_MCO_recueil2017_lexique'),
  (2017, '48H_MCO', 'B', 74.0, 77.3, 'ESATIS48H_MCO_recueil2017_lexique'),
  (2017, '48H_MCO', 'C', 70.7, 74.0, 'ESATIS48H_MCO_recueil2017_lexique'),
  (2017, '48H_MCO', 'D', NULL, 70.7, 'ESATIS48H_MCO_recueil2017_lexique'),
  (2019, '48H_MCO', 'A', 77.3, NULL, 'lexique-esatis48h-mco-open-data-2019'),
  (2019, '48H_MCO', 'B', 74.0, 77.3, 'lexique-esatis48h-mco-open-data-2019'),
  (2019, '48H_MCO', 'C', 70.7, 74.0, 'lexique-esatis48h-mco-open-data-2019'),
  (2019, '48H_MCO', 'D', NULL, 70.7, 'lexique-esatis48h-mco-open-data-2019'),
  (2020, '48H_MCO', 'A', 77.3, NULL, 'lexique-esatis48h-mco-open-data-2020'),
  (2020, '48H_MCO', 'B', 74.0, 77.3, 'lexique-esatis48h-mco-open-data-2020'),
  (2020, '48H_MCO', 'C', 70.7, 74.0, 'lexique-esatis48h-mco-open-data-2020'),
  (2020, '48H_MCO', 'D', NULL, 70.7, 'lexique-esatis48h-mco-open-data-2020'),
  -- CA MCO : identiques en 2019 et 2020
  (2019, 'CA_MCO',  'A', 79.7, NULL, 'lexique-esatisca-mco-open-data-2019'),
  (2019, 'CA_MCO',  'B', 76.5, 79.7, 'lexique-esatisca-mco-open-data-2019'),
  (2019, 'CA_MCO',  'C', 73.1, 76.5, 'lexique-esatisca-mco-open-data-2019'),
  (2019, 'CA_MCO',  'D', NULL, 73.1, 'lexique-esatisca-mco-open-data-2019'),
  (2020, 'CA_MCO',  'A', 79.7, NULL, 'lexique-esatisca-mco-open-data-2020'),
  (2020, 'CA_MCO',  'B', 76.5, 79.7, 'lexique-esatisca-mco-open-data-2020'),
  (2020, 'CA_MCO',  'C', 73.1, 76.5, 'lexique-esatisca-mco-open-data-2020'),
  (2020, 'CA_MCO',  'D', NULL, 73.1, 'lexique-esatisca-mco-open-data-2020');