
-- Livrable 2 - Membre C
-- Benchmark avant optimisation
-- Requête B1 : nombre de décès par année

SELECT
    annee_deces,
    COUNT(*) AS nombre_deces
FROM chu.gold.fait_deces
GROUP BY annee_deces
ORDER BY annee_deces DESC;
