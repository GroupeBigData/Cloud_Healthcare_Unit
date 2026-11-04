-- Gold - vues des 8 indicateurs (règle D5 : numérateur, dénominateur, taux).
-- Une ligne par année : le tableau de bord filtre l'année voulue (2019 pour l'indicateur 7,
-- 2020 pour l'indicateur 8). Les membres « Inconnu » restent visibles.

-- Indicateur 1 : consultations par établissement (réparties par le pont pondéré)
CREATE OR REPLACE VIEW chu.gold.v_ind1_consultations_etablissement
COMMENT 'Ind. 1 - consultations par établissement et par année, réparties par le pont pondéré'
AS
WITH par_etab AS (
  SELECT t.annee, b.etablissement_sk, sum(f.nb_consultations * b.poids) AS consultations
  FROM chu.gold.fait_consultation f
  JOIN chu.gold.dim_temps t ON f.date_sk = t.date_sk
  JOIN chu.gold.pont_professionnel_etablissement b ON f.professionnel_sk = b.professionnel_sk
  GROUP BY t.annee, b.etablissement_sk
)
SELECT p.annee, e.etablissement_sk, e.raison_sociale, e.libelle_type, e.libelle_region,
       p.consultations                                                           AS consultations,
       round(sum(p.consultations) OVER (PARTITION BY p.annee), 0)                AS total_annee,
       round(100 * p.consultations / sum(p.consultations) OVER (PARTITION BY p.annee), 4) AS taux_pct
FROM par_etab p
JOIN chu.gold.dim_etablissement e ON p.etablissement_sk = e.etablissement_sk;

-- Indicateur 2 : consultations par diagnostic
CREATE OR REPLACE VIEW chu.gold.v_ind2_consultations_diagnostic
COMMENT 'Ind. 2 - consultations par diagnostic et par année'
AS
SELECT t.annee, d.code_diag, d.libelle, d.lettre_cim10,
       sum(f.nb_consultations)                                                   AS consultations,
       sum(sum(f.nb_consultations)) OVER (PARTITION BY t.annee)                  AS total_annee,
       round(100 * sum(f.nb_consultations)
             / sum(sum(f.nb_consultations)) OVER (PARTITION BY t.annee), 4)      AS taux_pct
FROM chu.gold.fait_consultation f
JOIN chu.gold.dim_temps t      ON f.date_sk = t.date_sk
JOIN chu.gold.dim_diagnostic d ON f.diagnostic_sk = d.diagnostic_sk
GROUP BY t.annee, d.code_diag, d.libelle, d.lettre_cim10;

-- Indicateur 3 : taux d'hospitalisation global (patients hospitalisés / patients ayant consulté)
CREATE OR REPLACE VIEW chu.gold.v_ind3_hospitalisation_globale
COMMENT 'Ind. 3 - patients hospitalisés / patients ayant consulté, par année'
AS
WITH hosp AS (
  SELECT t.annee, count(DISTINCT f.patient_sk) AS patients_hospitalises,
         sum(f.nb_hospitalisations)            AS sejours
  FROM chu.gold.fait_hospitalisation f
  JOIN chu.gold.dim_temps t ON f.date_entree_sk = t.date_sk
  WHERE f.patient_sk <> -1
  GROUP BY t.annee
),
cons AS (
  SELECT t.annee, count(DISTINCT f.patient_sk) AS patients_consultants
  FROM chu.gold.fait_consultation f
  JOIN chu.gold.dim_temps t ON f.date_sk = t.date_sk
  WHERE f.patient_sk <> -1
  GROUP BY t.annee
)
SELECT coalesce(h.annee, c.annee)                                   AS annee,
       coalesce(h.patients_hospitalises, 0)                         AS patients_hospitalises,
       coalesce(h.sejours, 0)                                       AS sejours,
       c.patients_consultants,
       round(100 * coalesce(h.patients_hospitalises, 0) / c.patients_consultants, 2) AS taux_pct
FROM hosp h
FULL OUTER JOIN cons c ON h.annee = c.annee;

-- Indicateur 4 : hospitalisations par diagnostic
CREATE OR REPLACE VIEW chu.gold.v_ind4_hospitalisation_diagnostic
COMMENT 'Ind. 4 - séjours par diagnostic et par année'
AS
SELECT t.annee, d.code_diag, d.libelle, d.lettre_cim10,
       sum(f.nb_hospitalisations)                                                AS sejours,
       sum(sum(f.nb_hospitalisations)) OVER (PARTITION BY t.annee)               AS total_annee,
       round(100 * sum(f.nb_hospitalisations)
             / sum(sum(f.nb_hospitalisations)) OVER (PARTITION BY t.annee), 4)   AS taux_pct
FROM chu.gold.fait_hospitalisation f
JOIN chu.gold.dim_temps t      ON f.date_entree_sk = t.date_sk
JOIN chu.gold.dim_diagnostic d ON f.diagnostic_sk = d.diagnostic_sk
GROUP BY t.annee, d.code_diag, d.libelle, d.lettre_cim10;

-- Indicateur 5 : taux d'hospitalisation par sexe et tranche d'âge
-- Dénominateur : patients de la base appartenant au même groupe cette année-là
CREATE OR REPLACE VIEW chu.gold.v_ind5_hospitalisation_sexe_age
COMMENT 'Ind. 5 - patients hospitalisés / patients du même sexe et de la même tranche d''âge, par année'
AS
WITH annees AS (
  SELECT DISTINCT t.annee
  FROM chu.gold.fait_hospitalisation f
  JOIN chu.gold.dim_temps t ON f.date_entree_sk = t.date_sk
),
population AS (
  SELECT a.annee, p.sexe,
         CASE
           WHEN p.annee_naissance IS NULL         THEN 'Inconnu'
           WHEN a.annee - p.annee_naissance < 0   THEN 'Incohérent'
           WHEN a.annee - p.annee_naissance >= 90 THEN '90 ans et +'
           ELSE concat(lpad(CAST(floor((a.annee - p.annee_naissance) / 10) * 10 AS STRING), 2, '0'), '-',
                       lpad(CAST(floor((a.annee - p.annee_naissance) / 10) * 10 + 9 AS STRING), 2, '0'), ' ans')
         END AS tranche_age,
         count(*) AS patients
  FROM annees a
  CROSS JOIN chu.gold.dim_patient p
  WHERE p.patient_sk <> -1
  GROUP BY 1, 2, 3
),
hosp AS (
  SELECT t.annee, p.sexe, f.tranche_age,
         count(DISTINCT f.patient_sk) AS patients_hospitalises,
         sum(f.nb_hospitalisations)   AS sejours
  FROM chu.gold.fait_hospitalisation f
  JOIN chu.gold.dim_temps t   ON f.date_entree_sk = t.date_sk
  JOIN chu.gold.dim_patient p ON f.patient_sk = p.patient_sk
  GROUP BY 1, 2, 3
)
SELECT coalesce(h.annee, o.annee)             AS annee,
       coalesce(h.sexe, o.sexe)               AS sexe,
       coalesce(h.tranche_age, o.tranche_age) AS tranche_age,
       coalesce(h.patients_hospitalises, 0)   AS patients_hospitalises,
       coalesce(h.sejours, 0)                 AS sejours,
       o.patients                             AS patients_du_groupe,
       round(100 * coalesce(h.patients_hospitalises, 0) / o.patients, 2) AS taux_pct
FROM population o
FULL OUTER JOIN hosp h
  ON h.annee = o.annee AND h.sexe = o.sexe AND h.tranche_age = o.tranche_age;

-- Indicateur 6 : consultations par professionnel
CREATE OR REPLACE VIEW chu.gold.v_ind6_consultations_professionnel
COMMENT 'Ind. 6 - consultations par professionnel et par année'
AS
SELECT t.annee, pr.professionnel_sk, pr.type_identifiant, pr.identifiant,
       pr.profession, pr.specialite,
       sum(f.nb_consultations)                                                   AS consultations,
       sum(sum(f.nb_consultations)) OVER (PARTITION BY t.annee)                  AS total_annee,
       round(100 * sum(f.nb_consultations)
             / sum(sum(f.nb_consultations)) OVER (PARTITION BY t.annee), 6)      AS taux_pct
FROM chu.gold.fait_consultation f
JOIN chu.gold.dim_temps t         ON f.date_sk = t.date_sk
JOIN chu.gold.dim_professionnel pr ON f.professionnel_sk = pr.professionnel_sk
GROUP BY t.annee, pr.professionnel_sk, pr.type_identifiant, pr.identifiant,
         pr.profession, pr.specialite;

-- Indicateur 7 : nombre de décès par région (volume, pas un taux : aucune population de référence)
CREATE OR REPLACE VIEW chu.gold.v_ind7_deces_region
COMMENT 'Ind. 7 - nombre de décès par région du lieu de décès et par année'
AS
SELECT t.annee, r.code_region, r.libelle_region, r.type_zone,
       sum(f.nb_deces) AS deces
FROM chu.gold.fait_deces f
JOIN chu.gold.dim_temps t  ON f.date_sk = t.date_sk
JOIN chu.gold.dim_region r ON f.region_sk = r.region_sk
GROUP BY t.annee, r.code_region, r.libelle_region, r.type_zone;

-- Indicateur 8 : satisfaction par région, moyenne pondérée par le nombre de réponses
-- Classes A à D uniquement ; enquêtes et campagnes jamais mélangées ; ligne nationale incluse
CREATE OR REPLACE VIEW chu.gold.v_ind8_satisfaction_region
COMMENT 'Ind. 8 - score e-Satis pondéré par région, enquête et campagne (classes A-D)'
AS
SELECT t.annee                                                   AS campagne,
       q.code_enquete,
       q.libelle                                                 AS enquete,
       CASE WHEN grouping(r.libelle_region) = 1 THEN 'France entière'
            ELSE r.libelle_region END                            AS region,
       grouping(r.libelle_region)                                AS est_total,
       count(*)                                                  AS etablissements,
       sum(f.nb_reponses)                                        AS reponses,
       round(sum(f.score_x_reponses) / sum(f.nb_reponses), 2)    AS score_pondere
FROM chu.gold.fait_satisfaction f
JOIN chu.gold.dim_temps t   ON f.date_sk = t.date_sk
JOIN chu.gold.dim_enquete q ON f.enquete_sk = q.enquete_sk
JOIN chu.gold.dim_region r  ON f.region_sk = r.region_sk
WHERE f.est_classe
GROUP BY GROUPING SETS ((t.annee, q.code_enquete, q.libelle, r.libelle_region),
                        (t.annee, q.code_enquete, q.libelle));