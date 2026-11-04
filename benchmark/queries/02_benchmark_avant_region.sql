-- Livrable 2 - Membre C
-- Benchmark B2 avant optimisation
-- Nombre de décès par région

SET use_cached_result = false;

SELECT
    COALESCE(nom_region, 'Région non déterminée') AS region,
    COUNT(*) AS nombre_deces
FROM chu.gold.fait_deces
GROUP BY COALESCE(nom_region, 'Région non déterminée')
ORDER BY nombre_deces DESC;