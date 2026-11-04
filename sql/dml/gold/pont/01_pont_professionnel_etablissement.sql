-- Gold - DML pont professionnel <-> établissement.
-- Prérequis : DDL 12_pont_professionnel_etablissement.sql, dim_professionnel, dim_etablissement.
INSERT OVERWRITE chu.gold.pont_professionnel_etablissement
-- 1. Les couples dont le professionnel est dans la dimension (poids calculés en Silver)
SELECT pr.professionnel_sk, e.etablissement_sk, p.poids, p.modes_exercice
FROM chu.silver.pont_professionnel_etablissement p
JOIN chu.gold.dim_professionnel pr
  ON pr.type_identifiant = p.type_identifiant AND pr.identifiant = p.identifiant
 AND pr.professionnel_sk <> -1
JOIN chu.gold.dim_etablissement e
  ON e.identifiant_organisation = p.identifiant_organisation AND e.etablissement_sk <> -1
UNION ALL
-- 2. Les professionnels sans aucune structure : tout leur poids va à l'établissement inconnu
SELECT pr.professionnel_sk, -1, 1.0D, CAST(NULL AS STRING)
FROM chu.gold.dim_professionnel pr
WHERE NOT EXISTS (
  SELECT 1 FROM chu.silver.pont_professionnel_etablissement p
  WHERE p.type_identifiant = pr.type_identifiant AND p.identifiant = pr.identifiant
);