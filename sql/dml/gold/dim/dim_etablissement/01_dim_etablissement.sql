
-- Livrable 2 - Membre C
-- Couche Gold : dimension des établissements de santé
-- Source : chu.silver.etablissement

CREATE TABLE IF NOT EXISTS chu.gold.dim_etablissement
USING DELTA AS
SELECT
    identifiant_organisation,
    raison_sociale_site,
    finess_site,
    finess_etablissement_juridique,
    code_commune,
    code_postal,
    commune,
    code_departement,
    code_region,
    statut_rattachement,
    current_timestamp() AS _date_creation
FROM chu.silver.etablissement;
