-- Databricks notebook source
-- Contrôles qualité : volumétrie et cohérence de bout en bout, toutes entités du groupe.
-- À exécuter après l'ensemble des scripts Bronze, Silver et Gold.

-- COMMAND ----------

-- 1. Volumétrie par couche et par entité
SELECT 'patient'         AS entite, 'bronze' AS couche, count(*) AS nb FROM chu.bronze.patient
UNION ALL SELECT 'patient',         'silver', count(*) FROM chu.silver.patient
UNION ALL SELECT 'patient',         'gold',   count(*) FROM chu.gold.dim_patient
UNION ALL SELECT 'diagnostic',      'bronze', count(*) FROM chu.bronze.diagnostic
UNION ALL SELECT 'diagnostic',      'silver', count(*) FROM chu.silver.diagnostic
UNION ALL SELECT 'diagnostic',      'gold',   count(*) FROM chu.gold.dim_diagnostic
UNION ALL SELECT 'hospitalisation', 'bronze', count(*) FROM chu.bronze.hospitalisation
UNION ALL SELECT 'hospitalisation', 'silver', count(*) FROM chu.silver.hospitalisation
UNION ALL SELECT 'hospitalisation', 'gold',   count(*) FROM chu.gold.fait_hospitalisation
UNION ALL SELECT 'satisfaction',    'silver', count(*) FROM chu.silver.satisfaction_esatis
ORDER BY entite, couche;

-- COMMAND ----------

-- 2. Rejets Silver : vue d'ensemble de la table commune, toutes entités confondues.
--    Une entité absente de ce résultat n'a produit aucun rejet au dernier passage.
SELECT table_cible, table_source, regle, count(*) AS nb,
       count(DISTINCT _id_lot) AS lots, max(date_rejet) AS dernier_rejet
FROM chu.silver.rejets
GROUP BY table_cible, table_source, regle
ORDER BY table_cible, regle;

-- COMMAND ----------

-- 3. Réconciliation : chaque ligne source est en Silver, ou dans les rejets, ou retirée comme doublon ;
--    puis chaque ligne Silver est en Gold. Dimensions comptées sans le membre -1.
--    ecart_bronze_silver > 0 : lignes retirées sans rejet (doublons attendus seulement)
--    ecart_silver_gold  <> 0 : lignes perdues ou multipliées par les jointures Gold (attendu : 0)
WITH n AS (
  SELECT 'patient' AS entite,
         (SELECT count(*) FROM chu.bronze.patient)                                       AS bronze,
         (SELECT count(*) FROM chu.silver.patient)                                       AS silver,
         (SELECT count(*) FROM chu.silver.rejets WHERE table_cible = 'patient')          AS rejets,
         (SELECT count(*) FROM chu.gold.dim_patient WHERE patient_sk <> -1)              AS gold
  UNION ALL SELECT 'diagnostic',
         (SELECT count(*) FROM chu.bronze.diagnostic),
         (SELECT count(*) FROM chu.silver.diagnostic),
         (SELECT count(*) FROM chu.silver.rejets WHERE table_cible = 'diagnostic'),
         (SELECT count(*) FROM chu.gold.dim_diagnostic WHERE diagnostic_sk <> -1)
  UNION ALL SELECT 'etablissement',
         (SELECT count(*) FROM chu.bronze.etablissement_sante),
         (SELECT count(*) FROM chu.silver.etablissement),
         (SELECT count(*) FROM chu.silver.rejets WHERE table_cible = 'etablissement'),
         (SELECT count(*) FROM chu.gold.dim_etablissement WHERE etablissement_sk <> -1)
  UNION ALL SELECT 'professionnel',
         (SELECT count(*) FROM chu.bronze.professionnel_de_sante),
         (SELECT count(*) FROM chu.silver.professionnel),
         (SELECT count(*) FROM chu.silver.rejets WHERE table_cible = 'professionnel'),
         (SELECT count(*) FROM chu.gold.dim_professionnel WHERE professionnel_sk <> -1)
  UNION ALL SELECT 'specialite',
         (SELECT count(*) FROM chu.bronze.specialites),
         (SELECT count(*) FROM chu.silver.specialite),
         (SELECT count(*) FROM chu.silver.rejets WHERE table_cible = 'specialite'),
         CAST(NULL AS BIGINT)                                   -- dénormalisée dans dim_professionnel
  UNION ALL SELECT 'consultation',
         (SELECT count(*) FROM chu.bronze.consultation),
         (SELECT count(*) FROM chu.silver.consultation),
         (SELECT count(*) FROM chu.silver.rejets WHERE table_cible = 'consultation'),
         (SELECT count(*) FROM chu.gold.fait_consultation)
  UNION ALL SELECT 'hospitalisation',
         (SELECT count(*) FROM chu.bronze.hospitalisation),
         (SELECT count(*) FROM chu.silver.hospitalisation),
         (SELECT count(*) FROM chu.silver.rejets WHERE table_cible = 'hospitalisation'),
         (SELECT count(*) FROM chu.gold.fait_hospitalisation)
  UNION ALL SELECT 'deces',
         (SELECT count(*) FROM chu.bronze.deces),
         (SELECT count(*) FROM chu.silver.deces),
         (SELECT count(*) FROM chu.silver.rejets WHERE table_cible = 'deces'),
         (SELECT count(*) FROM chu.gold.fait_deces)
  UNION ALL SELECT 'satisfaction_esatis',
         (SELECT count(*) FROM chu.bronze.esatis48h_mco_recueil2017_donnees)
           + (SELECT count(*) FROM chu.bronze.resultats_esatis48h_mco_open_data_2019)
           + (SELECT count(*) FROM chu.bronze.resultats_esatis48h_mco_open_data_2020)
           + (SELECT count(*) FROM chu.bronze.resultats_esatisca_mco_open_data_2019)
           + (SELECT count(*) FROM chu.bronze.resultats_esatisca_mco_open_data_2020),
         (SELECT count(*) FROM chu.silver.satisfaction_esatis),
         (SELECT count(*) FROM chu.silver.rejets WHERE table_cible = 'satisfaction_esatis'),
         (SELECT count(*) FROM chu.gold.fait_satisfaction)
)
SELECT entite, bronze, silver, rejets,
       bronze - silver - rejets AS ecart_bronze_silver,
       gold,
       silver - gold            AS ecart_silver_gold
FROM n
ORDER BY entite;

-- COMMAND ----------

-- 4. Patient : répartition du sexe et bornes des années de naissance
SELECT sexe, count(*) AS nb, min(annee_naissance) AS annee_min, max(annee_naissance) AS annee_max,
       sum(CASE WHEN annee_naissance IS NULL THEN 1 ELSE 0 END) AS annee_nulle
FROM chu.silver.patient GROUP BY sexe ORDER BY sexe;

-- COMMAND ----------

-- 5. Diagnostic : libellés vides et codes au format CIM-10 inattendu (membre -1 exclu)
SELECT count(*) AS nb,
       sum(CASE WHEN libelle IS NULL OR trim(libelle) = '' THEN 1 ELSE 0 END) AS libelle_vide,
       sum(CASE WHEN NOT code_diag RLIKE '^[A-Z][0-9]{2,3}[A-Z0-9]*$' THEN 1 ELSE 0 END) AS format_invalide
FROM chu.gold.dim_diagnostic
WHERE diagnostic_sk <> -1;

-- COMMAND ----------

-- 6. dim_temps : couverture du calendrier, sans trou, avec un seul membre -1
--    Attendu : 53327 / 53327 / 1880-01-01 / 2025-12-31 / 0 / 1
SELECT count(*)                                                          AS nb_lignes,
       count(DISTINCT date_sk)                                           AS cles_uniques,
       min(date_complete)                                                AS date_min,
       max(date_complete)                                                AS date_max,
       datediff(max(date_complete), min(date_complete)) + 1
         - count(date_complete)                                          AS jours_manquants,
       sum(CASE WHEN date_sk = -1 THEN 1 ELSE 0 END)                     AS membre_inconnu
FROM chu.gold.dim_temps;

-- COMMAND ----------

-- 7. Complétude des faits : part des lignes rattachées à un vrai membre (et non au -1 « Inconnu »)
--    Avec le contrat Gold, une clé introuvable devient -1 : on compte donc les -1, clé par clé.
WITH comptes AS (
  SELECT 'fait_hospitalisation' AS fait, 'patient_sk' AS cle, count(*) AS lignes,
         sum(CASE WHEN patient_sk = -1 THEN 1 ELSE 0 END) AS inconnus FROM chu.gold.fait_hospitalisation
  UNION ALL SELECT 'fait_hospitalisation', 'diagnostic_sk', count(*),
         sum(CASE WHEN diagnostic_sk = -1 THEN 1 ELSE 0 END) FROM chu.gold.fait_hospitalisation
  UNION ALL SELECT 'fait_hospitalisation', 'etablissement_sk', count(*),
         sum(CASE WHEN etablissement_sk = -1 THEN 1 ELSE 0 END) FROM chu.gold.fait_hospitalisation
  UNION ALL SELECT 'fait_hospitalisation', 'date_entree_sk', count(*),
         sum(CASE WHEN date_entree_sk = -1 THEN 1 ELSE 0 END) FROM chu.gold.fait_hospitalisation
  UNION ALL SELECT 'fait_hospitalisation', 'date_sortie_sk', count(*),
         sum(CASE WHEN date_sortie_sk = -1 THEN 1 ELSE 0 END) FROM chu.gold.fait_hospitalisation
  UNION ALL SELECT 'fait_consultation', 'patient_sk', count(*),
         sum(CASE WHEN patient_sk = -1 THEN 1 ELSE 0 END) FROM chu.gold.fait_consultation
  UNION ALL SELECT 'fait_consultation', 'diagnostic_sk', count(*),
         sum(CASE WHEN diagnostic_sk = -1 THEN 1 ELSE 0 END) FROM chu.gold.fait_consultation
  UNION ALL SELECT 'fait_consultation', 'professionnel_sk', count(*),
         sum(CASE WHEN professionnel_sk = -1 THEN 1 ELSE 0 END) FROM chu.gold.fait_consultation
  UNION ALL SELECT 'fait_consultation', 'date_sk', count(*),
         sum(CASE WHEN date_sk = -1 THEN 1 ELSE 0 END) FROM chu.gold.fait_consultation
  UNION ALL SELECT 'fait_deces', 'date_sk', count(*),
         sum(CASE WHEN date_sk = -1 THEN 1 ELSE 0 END) FROM chu.gold.fait_deces
  UNION ALL SELECT 'fait_deces', 'region_sk', count(*),
         sum(CASE WHEN region_sk = -1 THEN 1 ELSE 0 END) FROM chu.gold.fait_deces
  UNION ALL SELECT 'fait_satisfaction', 'enquete_sk', count(*),
         sum(CASE WHEN enquete_sk = -1 THEN 1 ELSE 0 END) FROM chu.gold.fait_satisfaction
  UNION ALL SELECT 'fait_satisfaction', 'date_sk', count(*),
         sum(CASE WHEN date_sk = -1 THEN 1 ELSE 0 END) FROM chu.gold.fait_satisfaction
  UNION ALL SELECT 'fait_satisfaction', 'region_sk', count(*),
         sum(CASE WHEN region_sk = -1 THEN 1 ELSE 0 END) FROM chu.gold.fait_satisfaction
)
SELECT fait, cle, lignes, inconnus,
       round(100 * (lignes - inconnus) / lignes, 2) AS completude_pct
FROM comptes
ORDER BY fait, cle;

-- COMMAND ----------

-- 8. satisfaction_esatis : millésimes chargés et régions non rattachées au référentiel INSEE
SELECT millesime, enquete, count(*) AS etablissements,
       sum(CASE WHEN code_region IS NULL THEN 1 ELSE 0 END) AS region_non_rattachee,
       sum(CASE WHEN est_classe THEN 1 ELSE 0 END)          AS classes_a_d
FROM chu.silver.satisfaction_esatis
GROUP BY millesime, enquete ORDER BY millesime, enquete;