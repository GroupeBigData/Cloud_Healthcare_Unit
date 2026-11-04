-- Livrable 2 - Membre C
-- Benchmark B3 avant optimisation
-- Nombre de décès par année et par région (2015-2019)

SET use_cached_result = false;

SELECT
    annee_deces,
    COALESCE(nom_region, 'Région non déterminée') AS region,
    COUNT(*) AS nombre_deces
FROM chu.gold.fait_deces
WHERE annee_deces BETWEEN 2015 AND 2019
GROUP BY
    annee_deces,
    COALESCE(nom_region, 'Région non déterminée')
ORDER BY
    annee_deces DESC,
    nombre_deces DESC;