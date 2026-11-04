
-- Livrable 2 - Membre C
-- Couche Gold : table de faits des décès
-- Enrichissement géographique avec les régions
-- Traitement particulier du code historique 20 (Corse)

CREATE TABLE IF NOT EXISTS chu.gold.fait_deces
USING DELTA AS
WITH referentiel AS (
    SELECT DISTINCT
        code_departement,
        code_region,
        nom_region
    FROM chu.silver.ref_region
),
deces_enrichis AS (
    SELECT
        d.sexe,
        d.annee_naissance,
        d.date_deces,
        YEAR(d.date_deces) AS annee_deces,
        d.departement_deces,
        CASE
            WHEN d.departement_deces = '20' THEN '94'
            ELSE r.code_region
        END AS code_region,
        CASE
            WHEN d.departement_deces = '20' THEN 'Corse'
            ELSE r.nom_region
        END AS nom_region,
        d.statut_naissance,
        d.statut_date_deces,
        d.statut_departement,
        d.fichier_source,
        d.date_chargement,
        d.id_lot
    FROM chu.silver.deces d
    LEFT JOIN referentiel r
        ON d.departement_deces = r.code_departement
)
SELECT *
FROM deces_enrichis;
