-- Gold - DML fait_deces. Prérequis : DDL 13_fait_deces.sql, dim_temps, dim_region.
INSERT OVERWRITE chu.gold.fait_deces
SELECT d.date_sk,
       coalesce(r.region_sk, -1),
       d.sexe,
       d.age_deces,
       CASE
         WHEN d.age_deces IS NULL THEN 'Inconnu'
         WHEN d.age_deces >= 90   THEN '90 ans et +'
         ELSE concat(lpad(CAST(floor(d.age_deces / 10) * 10 AS STRING), 2, '0'), '-',
                     lpad(CAST(floor(d.age_deces / 10) * 10 + 9 AS STRING), 2, '0'), ' ans')
       END,
       d.precision_date,
       d.departement_deces,
       1
FROM chu.silver.deces d
LEFT JOIN chu.gold.dim_region r
       ON d.code_region = r.code_region AND r.region_sk <> -1;