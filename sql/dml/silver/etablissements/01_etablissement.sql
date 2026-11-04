
-- Livrable 2 - Membre C
-- Couche Silver : nettoyage des établissements
-- Rattachement géographique à partir du code commune

CREATE TABLE IF NOT EXISTS chu.silver.etablissement
USING DELTA AS
WITH etablissements_nettoyes AS (
    SELECT
        NULLIF(TRIM(identifiant_organisation), '') AS identifiant_organisation,
        NULLIF(TRIM(finess_site), '') AS finess_site,
        NULLIF(TRIM(finess_etablissement_juridique), '') AS finess_etablissement_juridique,
        NULLIF(TRIM(raison_sociale_site), '') AS raison_sociale_site,
        NULLIF(TRIM(code_commune), '') AS code_commune,
        NULLIF(TRIM(code_postal), '') AS code_postal,
        NULLIF(TRIM(commune), '') AS commune,
        _fichier_source,
        _date_chargement,
        _id_lot
    FROM chu.bronze.etablissement_sante
),
avec_departement AS (
    SELECT
        *,
        CASE
            WHEN SUBSTRING(code_commune, 1, 3)
                 IN ('971', '972', '973', '974', '976')
                THEN SUBSTRING(code_commune, 1, 3)
            WHEN SUBSTRING(code_commune, 1, 2) IN ('2A', '2B')
                THEN SUBSTRING(code_commune, 1, 2)
            WHEN SUBSTRING(code_commune, 1, 2) BETWEEN '01' AND '95'
                THEN SUBSTRING(code_commune, 1, 2)
            ELSE NULL
        END AS code_departement
    FROM etablissements_nettoyes
)
SELECT
    e.*,
    r.code_region,
    r.nom_region,
    CASE
        WHEN r.code_region IS NOT NULL THEN 'RATTACHE'
        WHEN e.code_commune IS NULL THEN 'CODE_COMMUNE_MANQUANT'
        ELSE 'REGION_NON_DETERMINEE'
    END AS statut_rattachement
FROM avec_departement e
LEFT JOIN chu.silver.ref_region r
    ON e.code_departement = r.code_departement;
