
-- Livrable 2 - Membre C
-- Contrôle qualité des établissements de santé
-- et des activités des professionnels de santé

-- 1. Vérification des volumes Bronze, Silver et Gold

SELECT 'Bronze établissements' AS table_controlee,
       COUNT(*) AS nombre_lignes
FROM chu.bronze.etablissement_sante

UNION ALL

SELECT 'Silver établissements',
       COUNT(*)
FROM chu.silver.etablissement

UNION ALL

SELECT 'Gold établissements',
       COUNT(*)
FROM chu.gold.dim_etablissement

UNION ALL

SELECT 'Bronze activités',
       COUNT(*)
FROM chu.bronze.activite_professionnel_sante

UNION ALL

SELECT 'Silver activités',
       COUNT(*)
FROM chu.silver.activite_professionnel_sante

UNION ALL

SELECT 'Gold pont professionnel-établissement',
       COUNT(*)
FROM chu.gold.pont_professionnel_etablissement;


-- 2. Contrôle des identifiants des établissements

SELECT
    COUNT(*) AS total_etablissements,
    COUNT(DISTINCT identifiant_organisation)
        AS identifiants_distincts,
    SUM(
        CASE WHEN identifiant_organisation IS NULL
        THEN 1 ELSE 0 END
    ) AS identifiants_manquants
FROM chu.silver.etablissement;


-- 3. Contrôle du rattachement géographique

SELECT
    statut_rattachement,
    COUNT(*) AS nombre_etablissements
FROM chu.silver.etablissement
GROUP BY statut_rattachement
ORDER BY nombre_etablissements DESC;


-- 4. Contrôle des activités professionnelles

SELECT
    statut_organisation,
    COUNT(*) AS nombre_activites
FROM chu.silver.activite_professionnel_sante
GROUP BY statut_organisation
ORDER BY nombre_activites DESC;


-- 5. Vérification des liens professionnel-établissement

SELECT
    COUNT(*) AS nombre_relations,
    COUNT(DISTINCT identifiant_professionnel)
        AS professionnels_distincts,
    COUNT(DISTINCT identifiant_organisation)
        AS etablissements_distincts
FROM chu.gold.pont_professionnel_etablissement;
