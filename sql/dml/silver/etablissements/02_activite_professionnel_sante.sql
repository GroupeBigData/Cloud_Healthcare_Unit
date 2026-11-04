
-- Livrable 2 - Membre C
-- Couche Silver : activités des professionnels de santé
-- Nettoyage des identifiants sans suppression des lignes sources

CREATE TABLE IF NOT EXISTS chu.silver.activite_professionnel_sante
USING DELTA AS
SELECT
    NULLIF(TRIM(identifiant), '') AS identifiant_professionnel,
    NULLIF(TRIM(identifiant_organisation), '') AS identifiant_organisation,
    NULLIF(TRIM(mode_exercice), '') AS mode_exercice,
    CASE
        WHEN identifiant_organisation IS NULL
             OR TRIM(identifiant_organisation) = ''
        THEN 'ORGANISATION_MANQUANTE'
        ELSE 'ORGANISATION_RENSEIGNEE'
    END AS statut_organisation,
    _fichier_source,
    _date_chargement,
    _id_lot
FROM chu.bronze.activite_professionnel_sante;
