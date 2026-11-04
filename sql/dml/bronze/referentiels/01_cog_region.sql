-- Livrable 2 - Membre C
-- Chargement Bronze du référentiel des régions (COG 2026)

CREATE TABLE IF NOT EXISTS chu.bronze.cog_region
USING DELTA AS
SELECT
    REG,
    CHEFLIEU,
    TNCC,
    NCC,
    NCCENR,
    LIBELLE,
    input_file_name() AS _fichier_source,
    current_timestamp() AS _date_chargement,
    'cog_2026' AS _id_lot
FROM read_files(
    '/Volumes/chu/bronze/landing/referentiels/cog_region/v_region_2026.csv',
    format => 'csv',
    header => true,
    sep => ',',
    inferSchema => false
);
