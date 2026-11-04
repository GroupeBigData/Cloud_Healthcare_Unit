-- Réinitialisation du Gold : à lancer UNE FOIS, à la main, avant le premier DDL Gold.
-- Ne fait pas partie de run_pipeline. Les faits d'abord : ils référencent les dimensions.
DROP TABLE IF EXISTS chu.gold.fait_hospitalisation;
DROP TABLE IF EXISTS chu.gold.fait_deces;
DROP TABLE IF EXISTS chu.gold.fait_satisfaction;
DROP TABLE IF EXISTS chu.gold.pont_professionnel_etablissement;
DROP TABLE IF EXISTS chu.gold.dim_patient;
DROP TABLE IF EXISTS chu.gold.dim_diagnostic;
DROP TABLE IF EXISTS chu.gold.dim_temps;
DROP TABLE IF EXISTS chu.gold.dim_etablissement;
DROP TABLE IF EXISTS chu.gold.dim_region;
DROP TABLE IF EXISTS chu.gold.dim_enquete;

SHOW TABLES IN chu.gold;