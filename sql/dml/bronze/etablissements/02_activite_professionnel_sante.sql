
-- Livrable 2 - Membre C
-- Couche Bronze : activités des professionnels de santé
-- Conservation des données sources et ajout de la traçabilité

CREATE TABLE IF NOT EXISTS chu.bronze.activite_professionnel_sante
USING DELTA AS
SELECT
    *,
    _metadata.file_path AS _fichier_source,
    current_timestamp() AS _date_chargement,
    'activite_initial' AS _id_lot
FROM read_files(
    '/Volumes/chu/bronze/landing/etablissements/activite_professionnel_sante/activite_professionnel_sante.csv',
    format => 'csv',
    header => true,
    sep => ';',
    inferSchema => false
);
