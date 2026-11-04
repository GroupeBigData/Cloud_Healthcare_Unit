
-- Livrable 2 - Membre C
-- Contrôle qualité des données de décès
-- Vérification des volumes et des anomalies Silver

-- 1. Vérification du nombre de lignes Bronze et Silver
SELECT
    'Bronze' AS couche,
    COUNT(*) AS nombre_lignes
FROM chu.bronze.deces

UNION ALL

SELECT
    'Silver' AS couche,
    COUNT(*) AS nombre_lignes
FROM chu.silver.deces;


-- 2. Contrôle des anomalies dans les décès
SELECT
    COUNT(*) AS total_deces,

    SUM(
        CASE WHEN statut_naissance <> 'VALIDE'
        THEN 1 ELSE 0 END
    ) AS anomalies_naissance,

    SUM(
        CASE WHEN statut_date_deces <> 'VALIDE'
        THEN 1 ELSE 0 END
    ) AS anomalies_date_deces,

    SUM(
        CASE WHEN statut_departement = 'DEPARTEMENT_MANQUANT'
        THEN 1 ELSE 0 END
    ) AS departements_manquants

FROM chu.silver.deces;


-- 3. Vérification du rattachement géographique Gold
SELECT
    COUNT(*) AS total_deces,

    SUM(
        CASE WHEN code_region IS NOT NULL
        THEN 1 ELSE 0 END
    ) AS deces_avec_region,

    SUM(
        CASE WHEN code_region IS NULL
        THEN 1 ELSE 0 END
    ) AS deces_sans_region,

    ROUND(
        100.0 * SUM(
            CASE WHEN code_region IS NOT NULL
            THEN 1 ELSE 0 END
        ) / COUNT(*),
        2
    ) AS taux_rattachement_region

FROM chu.gold.fait_deces;
