
-- Livrable 2 - Membre C
-- Couche Gold : dimension des régions
-- Source : référentiel géographique COG 2026

CREATE TABLE IF NOT EXISTS chu.gold.dim_region
USING DELTA AS
SELECT
    REG AS code_region,
    LIBELLE AS nom_region,
    current_timestamp() AS _date_chargement
FROM chu.bronze.cog_region;
