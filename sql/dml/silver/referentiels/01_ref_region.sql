
-- Livrable 2 - Membre C
-- Couche Silver : référentiel géographique
-- Association des départements aux régions
-- Source : Code officiel géographique 2026

CREATE TABLE IF NOT EXISTS chu.silver.ref_region
USING DELTA AS
SELECT
    d.DEP AS code_departement,
    d.LIBELLE AS nom_departement,
    d.REG AS code_region,
    r.LIBELLE AS nom_region,
    current_timestamp() AS _date_chargement,
    'cog_2026' AS _id_lot
FROM chu.bronze.cog_departement d
LEFT JOIN chu.bronze.cog_region r
    ON d.REG = r.REG;
