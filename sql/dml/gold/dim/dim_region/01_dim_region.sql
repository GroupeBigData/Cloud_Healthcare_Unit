-- Gold - DML dim_region. Prérequis : sql/ddl/gold/04_dim_region.sql
INSERT OVERWRITE chu.gold.dim_region (code_region, libelle_region, type_zone)
SELECT code_region, libelle_region, type_zone
FROM chu.silver.ref_region;

INSERT INTO chu.gold.dim_region (region_sk, code_region, libelle_region, type_zone)
VALUES (-1, 'INC', 'Région inconnue', 'inconnu');