-- Livrable 2 - Membre C
-- Benchmark B4 avant optimisation
-- Nombre de décès par sexe et par année (2015-2019)

SET use_cached_result = false;

SELECT
    annee_deces,
    CASE
        WHEN sexe = '1' THEN 'Masculin'
        WHEN sexe = '2' THEN 'Féminin'
        ELSE 'Non renseigné'
    END AS sexe_libelle,
    COUNT(*) AS nombre_deces
FROM chu.gold.fait_deces
WHERE annee_deces BETWEEN 2015 AND 2019
GROUP BY
    annee_deces,
    CASE
        WHEN sexe = '1' THEN 'Masculin'
        WHEN sexe = '2' THEN 'Féminin'
        ELSE 'Non renseigné'
    END
ORDER BY
    annee_deces DESC,
    sexe_libelle;