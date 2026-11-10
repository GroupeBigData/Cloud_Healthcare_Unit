-- Ind. 1 : consultations réparties par établissement (pont pondéré), au grain jour
CREATE OR REPLACE VIEW chu.gold.v_bi_consultation_etablissement AS
SELECT f.date_sk, b.etablissement_sk,
       sum(f.nb_consultations * b.poids) AS consultations_ponderees
FROM chu.gold.fait_consultation f
JOIN chu.gold.pont_professionnel_etablissement b ON f.professionnel_sk = b.professionnel_sk
GROUP BY f.date_sk, b.etablissement_sk;

-- Ind. 7 : décès agrégés à l'année (~quelques dizaines de milliers de lignes au lieu de 24,9 M)
-- date_sk = 1er janvier, même convention que fait_satisfaction
CREATE OR REPLACE VIEW chu.gold.v_bi_deces_annee AS
SELECT (f.date_sk DIV 10000) * 10000 + 101 AS date_sk,
       f.region_sk, f.sexe, f.tranche_age, f.departement_deces,
       sum(f.nb_deces) AS nb_deces
FROM chu.gold.fait_deces f
GROUP BY ALL;

-- Ind. 5 : on garde numérateur et dénominateur (pas le taux) pour pouvoir sommer sur une période
CREATE OR REPLACE VIEW chu.gold.v_bi_hosp_sexe_age AS
SELECT annee * 10000 + 101 AS date_sk, sexe, tranche_age,
       patients_hospitalises, sejours, patients_du_groupe
FROM chu.gold.v_ind5_hospitalisation_sexe_age;