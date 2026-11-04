
-- Livrable 2 - Membre C
-- Couche Gold : pont professionnel-etablissement
-- Granularité : professionnel + établissement + mode d'exercice

CREATE TABLE IF NOT EXISTS chu.gold.pont_professionnel_etablissement
USING DELTA AS
SELECT
    a.identifiant_professionnel,
    a.identifiant_organisation,
    a.mode_exercice,
    e.code_departement,
    e.code_region,
    current_timestamp() AS _date_creation
FROM chu.silver.activite_professionnel_sante a
INNER JOIN chu.gold.dim_etablissement e
    ON a.identifiant_organisation = e.identifiant_organisation
WHERE
    a.identifiant_professionnel IS NOT NULL
    AND a.identifiant_organisation IS NOT NULL;
