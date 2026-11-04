-- Livrable 2 - Membre C
-- Couche Bronze : données des décès
-- Conservation des données sources sans nettoyage

CREATE TABLE IF NOT EXISTS chu.bronze.deces
USING DELTA AS
SELECT
    sexe,
    annee_naissance,
    date_deces,
    departement_deces,
    _rescued_data,
    'deces.csv' AS fichier_source,
    current_timestamp() AS date_chargement,
    'deces_import_initial' AS id_lot
FROM read_files(
    '/Volumes/chu/bronze/landing/deces/deces/deces.csv',
    format => 'csv',
    header => true,
    sep => ';',
    inferSchema => false
);
