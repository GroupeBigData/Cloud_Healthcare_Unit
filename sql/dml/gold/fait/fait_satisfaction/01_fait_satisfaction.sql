-- Gold - DML fait_satisfaction. Prérequis : DDL 14_fait_satisfaction.sql et les dimensions.
-- Une seule fiche établissement par FINESS : un FINESS en double ne duplique jamais un score.
INSERT OVERWRITE chu.gold.fait_satisfaction
WITH etab AS (
  SELECT finess_geo, etablissement_sk,
         row_number() OVER (
           PARTITION BY finess_geo
           ORDER BY length(identifiant_organisation),
                    try_to_date(substr(identifiant_organisation, 11, 8), 'ddMMyyyy') DESC
         ) AS rang
  FROM chu.gold.dim_etablissement
  WHERE finess_geo IS NOT NULL AND etablissement_sk <> -1
)
SELECT coalesce(e.etablissement_sk, -1),
       coalesce(r.region_sk, -1),
       coalesce(q.enquete_sk, -1),
       s.millesime * 10000 + 101,
       s.finess_geo,
       s.classement,
       s.est_classe,
       s.score_global,
       s.nb_reponses,
       CAST(s.score_global * s.nb_reponses AS DECIMAL(12,2)),
       s.taux_reco_brut
FROM chu.silver.satisfaction_esatis s
LEFT JOIN etab e
       ON e.finess_geo = s.finess_geo AND e.rang = 1
LEFT JOIN chu.gold.dim_region r
       ON r.code_region = s.code_region AND r.region_sk <> -1
LEFT JOIN chu.gold.dim_enquete q
       ON q.code_enquete = s.enquete AND q.enquete_sk <> -1;