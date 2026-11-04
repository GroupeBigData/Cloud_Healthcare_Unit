-- Gold - DML dim_etablissement. Prérequis : sql/ddl/gold/05_dim_etablissement.sql
INSERT OVERWRITE chu.gold.dim_etablissement
  (identifiant_organisation, type_structure, libelle_type, finess_geo, finess_juridique,
   est_entite_juridique, raison_sociale, code_commune, commune, code_departement,
   code_region, libelle_region)
SELECT e.identifiant_organisation,
       e.type_structure,
       CASE e.type_structure
         WHEN 'F' THEN 'Établissement (FINESS)'
         WHEN 'C' THEN 'Structure (SIRET ou autre)'
         WHEN 'R' THEN 'Cabinet (RPPS)'
       END,
       e.finess_geo, e.finess_juridique, e.est_entite_juridique, e.raison_sociale,
       e.code_commune, e.commune, e.code_departement,
       e.code_region, r.libelle_region
FROM chu.silver.etablissement e
LEFT JOIN chu.silver.ref_region r ON e.code_region = r.code_region;

INSERT INTO chu.gold.dim_etablissement
  (etablissement_sk, identifiant_organisation, type_structure, libelle_type,
   est_entite_juridique, raison_sociale)
VALUES (-1, 'INCONNU', '?', 'Inconnu', false, 'Établissement inconnu');