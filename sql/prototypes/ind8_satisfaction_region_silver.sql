-- Prototype de l'indicateur 8 sur Silver : satisfaction globale par région, campagne 2020.
-- Moyenne pondérée par le nombre de réponses ; établissements classés A à D uniquement.
WITH regions AS (
  SELECT REG AS code_region, LIBELLE AS region
  FROM read_files('/Volumes/chu/bronze/landing/referentiels/cog_region/',
                  format => 'csv', header => true, sep => ',', inferColumnTypes => false)
)
SELECT
  s.enquete,
  CASE WHEN grouping(r.region) = 1 THEN 'France entière' ELSE r.region END   AS region,
  grouping(r.region)                                                          AS est_total,
  count(*)                                                                    AS etablissements,
  sum(s.nb_reponses)                                                          AS reponses,
  round(sum(s.score_global * s.nb_reponses) / sum(s.nb_reponses), 2)          AS score_pondere,
  round(avg(s.score_global), 2)                                               AS score_simple
FROM chu.silver.satisfaction_esatis s
LEFT JOIN regions r ON s.code_region = r.code_region
WHERE s.millesime = 2020
  AND s.est_classe
GROUP BY GROUPING SETS ((s.enquete, r.region), (s.enquete))
ORDER BY s.enquete, est_total, score_pondere DESC;