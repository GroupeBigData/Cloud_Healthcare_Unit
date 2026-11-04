-- Livrable 2 - Membre C
-- Benchmark B5 avant optimisation
-- Nombre de décès par tranche d'âge (2015-2019)

SET use_cached_result = false;

WITH deces_avec_age AS (
    SELECT
        annee_deces - annee_naissance AS age
    FROM chu.gold.fait_deces
    WHERE annee_deces BETWEEN 2015 AND 2019
      AND annee_naissance IS NOT NULL
),
tranches_age AS (
    SELECT
        CASE
            WHEN age < 20 THEN 'Moins de 20 ans'
            WHEN age BETWEEN 20 AND 39 THEN '20-39 ans'
            WHEN age BETWEEN 40 AND 59 THEN '40-59 ans'
            WHEN age BETWEEN 60 AND 79 THEN '60-79 ans'
            ELSE '80 ans et plus'
        END AS tranche_age
    FROM deces_avec_age
    WHERE age BETWEEN 0 AND 120
)
SELECT
    tranche_age,
    COUNT(*) AS nombre_deces
FROM tranches_age
GROUP BY tranche_age
ORDER BY tranche_age;