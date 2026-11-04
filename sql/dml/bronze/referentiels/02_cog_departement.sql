
-- Livrable 2 - Membre C
-- Couche Bronze : référentiel des départements
-- Source : Code officiel géographique (COG 2026)

CREATE TABLE IF NOT EXISTS chu.bronze.cog_departement
USING DELTA AS
SELECT
    DEP,
    REG,
    CHEFLIEU,
    TNCC,
    NCC,
    NCCENR,
    LIBELLE,
    _metadata.file_path AS _fichier_source,
    current_timestamp() AS _date_chargement,
    'cog_2026' AS _id_lot
FROM read_files(
    '/Volumes/chu/bronze/landing/referentiels/cog_departement/v_departement_2026.csv',
    format => 'csv',
    header => true,
    sep => ',',
    inferSchema => false
);
