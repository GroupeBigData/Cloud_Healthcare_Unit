
-- Livrable 2 - Membre C
-- Couche Silver : nettoyage des données de décès
-- Typage, normalisation et contrôles de qualité
-- Conservation de toutes les lignes Bronze

CREATE TABLE IF NOT EXISTS chu.silver.deces
USING DELTA AS
WITH donnees_typees AS (
    SELECT
        TRIM(sexe) AS sexe,
        annee_naissance AS annee_naissance_brute,
        date_deces AS date_deces_brute,
        NULLIF(TRIM(departement_deces), '') AS departement_deces,
        TRY_CAST(annee_naissance AS INT) AS annee_naissance,
        TRY_CAST(date_deces AS DATE) AS date_deces,
        fichier_source,
        date_chargement,
        id_lot
    FROM chu.bronze.deces
)
SELECT
    *,
    CASE
        WHEN annee_naissance IS NULL
            THEN 'NAISSANCE_INCONNUE'
        WHEN date_deces IS NOT NULL
             AND annee_naissance > YEAR(date_deces)
            THEN 'NAISSANCE_APRES_DECES'
        WHEN annee_naissance < 1800
             OR annee_naissance > 2020
            THEN 'ANNEE_HORS_PLAGE'
        WHEN date_deces IS NOT NULL
             AND YEAR(date_deces) - annee_naissance > 120
            THEN 'AGE_SUPERIEUR_120'
        ELSE 'VALIDE'
    END AS statut_naissance,
    CASE
        WHEN date_deces IS NULL
            THEN 'DATE_INVALIDE_OU_MANQUANTE'
        ELSE 'VALIDE'
    END AS statut_date_deces,
    CASE
        WHEN departement_deces IS NULL
            THEN 'DEPARTEMENT_MANQUANT'
        ELSE 'RENSEIGNE'
    END AS statut_departement
FROM donnees_typees;
