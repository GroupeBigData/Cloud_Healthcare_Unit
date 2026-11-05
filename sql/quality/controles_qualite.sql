-- Databricks notebook source
-- Contrôles qualité : volumétrie et cohérence de bout en bout, toutes entités du groupe.
-- À exécuter après l'ensemble des scripts Bronze, Silver et Gold.

-- COMMAND ----------

-- 0. Table des résultats : une ligne par contrôle et par exécution, jamais effacée (historique).
--    Dimensions qualité : completude | unicite | validite | coherence | integrite
--    Gravité : bloquant (un KO arrête la chaîne) | avertissement (un KO est seulement signalé)
CREATE TABLE IF NOT EXISTS chu.quality.resultats_controles (
  id_execution     STRING       NOT NULL COMMENT 'Exécution (yyyyMMdd_HHmmss), commune à tous les contrôles d''un passage',
  date_controle    TIMESTAMP    NOT NULL COMMENT 'Moment du contrôle (UTC)',
  couche           STRING       NOT NULL COMMENT 'bronze, silver, gold ou bout_en_bout',
  entite           STRING       NOT NULL COMMENT 'Table ou entité contrôlée (ex. fait_consultation)',
  controle         STRING       NOT NULL COMMENT 'Code stable du contrôle (ex. pk_unique), pour suivre son évolution',
  dimension        STRING       NOT NULL COMMENT 'completude | unicite | validite | coherence | integrite',
  description      STRING                COMMENT 'Ce que le contrôle vérifie, en clair',
  nb_examinees     BIGINT                COMMENT 'Nombre de lignes examinées',
  nb_anomalies     BIGINT                COMMENT 'Nombre de lignes en défaut',
  taux_conformite  DECIMAL(7,4)          COMMENT '% de lignes conformes ; NULL si aucune ligne examinée',
  seuil_pct        DECIMAL(7,4)          COMMENT 'Taux de conformité minimal attendu',
  gravite          STRING       NOT NULL COMMENT 'bloquant | avertissement',
  statut           STRING       NOT NULL COMMENT 'OK | KO'
) COMMENT 'Résultats des contrôles qualité, historisés - alimentée par sql/quality/controles_qualite.sql';

-- COMMAND ----------

-- Identifiant de l'exécution : calculé une seule fois, partagé par tous les INSERT du script.
DECLARE OR REPLACE VARIABLE id_execution STRING
  DEFAULT date_format(current_timestamp(), 'yyyyMMdd_HHmmss');

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

-- 6. dim_temps : clé unique, calendrier continu, bornes attendues, un seul membre -1, clé = date
INSERT INTO chu.quality.resultats_controles
  (id_execution, date_controle, couche, entite, controle, dimension, description,
   nb_examinees, nb_anomalies, taux_conformite, seuil_pct, gravite, statut)
WITH t AS (
  SELECT count(*)                                              AS nb_lignes,
         count(DISTINCT date_sk)                               AS cles_distinctes,
         min(date_complete)                                    AS date_min,
         max(date_complete)                                    AS date_max,
         count(DISTINCT date_complete)                         AS jours_presents,
         sum(CASE WHEN date_sk = -1 THEN 1 ELSE 0 END)         AS membres_inconnus,
         sum(CASE WHEN date_sk <> -1
                   AND date_sk <> CAST(date_format(date_complete, 'yyyyMMdd') AS INT)
                  THEN 1 ELSE 0 END)                           AS cles_incoherentes
  FROM chu.gold.dim_temps
),
mesures AS (
  SELECT 'pk_unique' AS controle, 'unicite' AS dimension,
         'Chaque date_sk n''apparaît qu''une fois' AS description,
         nb_lignes AS nb_examinees, nb_lignes - cles_distinctes AS nb_anomalies,
         100 AS seuil_pct, 'bloquant' AS gravite
  FROM t
  UNION ALL
  SELECT 'calendrier_continu', 'completude',
         'Aucun jour manquant entre la première et la dernière date',
         datediff(date_max, date_min) + 1, datediff(date_max, date_min) + 1 - jours_presents,
         100, 'bloquant'
  FROM t
  UNION ALL
  SELECT 'bornes_calendrier', 'validite',
         'Le calendrier va du 1880-01-01 au 2025-12-31',
         2, CASE WHEN date_min = DATE'1880-01-01' THEN 0 ELSE 1 END
          + CASE WHEN date_max = DATE'2025-12-31' THEN 0 ELSE 1 END,
         100, 'bloquant'
  FROM t
  UNION ALL
  SELECT 'membre_inconnu_unique', 'unicite',
         'Le membre -1 « date inconnue » existe une et une seule fois',
         1, CASE WHEN membres_inconnus = 1 THEN 0 ELSE 1 END,
         100, 'bloquant'
  FROM t
  UNION ALL
  SELECT 'cle_egale_date', 'coherence',
         'date_sk correspond à date_complete au format AAAAMMJJ',
         nb_lignes - membres_inconnus, cles_incoherentes,
         100, 'bloquant'
  FROM t
),
calcul AS (
  SELECT *, CAST(100 * try_divide(nb_examinees - nb_anomalies, nb_examinees) AS DECIMAL(7,4)) AS taux
  FROM mesures
)
SELECT id_execution, current_timestamp(), 'gold', 'dim_temps', controle, dimension, description,
       nb_examinees, nb_anomalies, taux, CAST(seuil_pct AS DECIMAL(7,4)), gravite,
       CASE WHEN taux >= seuil_pct THEN 'OK' ELSE 'KO' END
FROM calcul;

-- COMMAND ----------

-- 7. Complétude des faits : part des lignes rattachées à un vrai membre de dimension (et non au -1 « Inconnu »).
--    Seules les clés obtenues par jointure peuvent valoir -1. Les clés de date sont calculées :
--    elles sont contrôlées avec l'intégrité référentielle.
--    Seuils calés sur les taux observés : 100 % là où aucun -1 n'existe (un seul -1 = changement à
--    expliquer) ; 99,9 % pour les régions des décès (environ 11 000 départements non rattachables sur 24,9 M).
INSERT INTO chu.quality.resultats_controles
  (id_execution, date_controle, couche, entite, controle, dimension, description,
   nb_examinees, nb_anomalies, taux_conformite, seuil_pct, gravite, statut)
WITH mesures AS (
  SELECT 'fait_hospitalisation' AS entite, 'patient_sk' AS cle, count(*) AS nb_examinees,
         count_if(patient_sk = -1) AS nb_anomalies, 100 AS seuil_pct, 'avertissement' AS gravite
  FROM chu.gold.fait_hospitalisation
  UNION ALL SELECT 'fait_hospitalisation', 'diagnostic_sk', count(*), count_if(diagnostic_sk = -1), 100, 'avertissement'
  FROM chu.gold.fait_hospitalisation
  UNION ALL SELECT 'fait_hospitalisation', 'etablissement_sk', count(*), count_if(etablissement_sk = -1), 100, 'avertissement'
  FROM chu.gold.fait_hospitalisation
  UNION ALL SELECT 'fait_consultation', 'patient_sk', count(*), count_if(patient_sk = -1), 100, 'avertissement'
  FROM chu.gold.fait_consultation
  UNION ALL SELECT 'fait_consultation', 'diagnostic_sk', count(*), count_if(diagnostic_sk = -1), 100, 'avertissement'
  FROM chu.gold.fait_consultation
  UNION ALL SELECT 'fait_consultation', 'professionnel_sk', count(*), count_if(professionnel_sk = -1), 100, 'bloquant'
  FROM chu.gold.fait_consultation
  UNION ALL SELECT 'fait_deces', 'region_sk', count(*), count_if(region_sk = -1), 99.9, 'avertissement'
  FROM chu.gold.fait_deces
  UNION ALL SELECT 'fait_satisfaction', 'region_sk', count(*), count_if(region_sk = -1), 100, 'avertissement'
  FROM chu.gold.fait_satisfaction
  UNION ALL SELECT 'fait_satisfaction', 'enquete_sk', count(*), count_if(enquete_sk = -1), 100, 'bloquant'
  FROM chu.gold.fait_satisfaction
),
calcul AS (
  SELECT *, CAST(100 * try_divide(nb_examinees - nb_anomalies, nb_examinees) AS DECIMAL(7,4)) AS taux
  FROM mesures
)
SELECT id_execution, current_timestamp(), 'gold', entite, concat('completude_', cle), 'completude',
       concat(cle, ' pointe vers un vrai membre de dimension, et non vers -1 « Inconnu »'),
       nb_examinees, nb_anomalies, taux, CAST(seuil_pct AS DECIMAL(7,4)), gravite,
       CASE WHEN taux >= seuil_pct THEN 'OK' ELSE 'KO' END
FROM calcul;

-- COMMAND ----------

-- 8. satisfaction_esatis : millésimes chargés et régions non rattachées au référentiel INSEE
SELECT millesime, enquete, count(*) AS etablissements,
       sum(CASE WHEN code_region IS NULL THEN 1 ELSE 0 END) AS region_non_rattachee,
       sum(CASE WHEN est_classe THEN 1 ELSE 0 END)          AS classes_a_d
FROM chu.silver.satisfaction_esatis
GROUP BY millesime, enquete ORDER BY millesime, enquete;

-- COMMAND ----------

-- 9. Cohérence des FINESS : format, département, unicité, concordance e-Satis, pont pondéré
--    Une ligne par contrôle : conformes / total / taux (en %).
WITH etab AS (
  SELECT * FROM chu.gold.dim_etablissement
  WHERE etablissement_sk <> -1 AND type_structure = 'F'
),
controles AS (
  SELECT '1. Format du FINESS géographique valide' AS controle,
         sum(CASE WHEN finess_geo RLIKE '^([0-9]{2}|2[AB]|9[A-F])[0-9]{7}$' THEN 1 ELSE 0 END) AS conformes,
         count(*) AS total
  FROM etab
  UNION ALL
  SELECT '2. Préfixe FINESS = département de la commune',
         sum(CASE WHEN left(finess_geo, 2) =
                       CASE code_departement
                         WHEN '971' THEN '9A' WHEN '977' THEN '9A' WHEN '978' THEN '9A'
                         WHEN '972' THEN '9B' WHEN '973' THEN '9C' WHEN '974' THEN '9D'
                         WHEN '975' THEN '9E' WHEN '976' THEN '9F'
                         ELSE code_departement
                       END
                  THEN 1 ELSE 0 END),
         count(*)
  FROM etab
  WHERE code_departement IS NOT NULL
  UNION ALL
  SELECT '3. FINESS géographique porté par une seule fiche',
         sum(CASE WHEN nb_fiches = 1 THEN 1 ELSE 0 END), count(*)
  FROM (SELECT finess_geo, count(*) AS nb_fiches FROM etab GROUP BY finess_geo)
  UNION ALL
  SELECT concat('4. e-Satis rattaché au référentiel - ', q.code_enquete, ' ', t.annee),
         sum(CASE WHEN f.etablissement_sk <> -1 THEN 1 ELSE 0 END), count(*)
  FROM chu.gold.fait_satisfaction f
  JOIN chu.gold.dim_enquete q ON f.enquete_sk = q.enquete_sk
  JOIN chu.gold.dim_temps t   ON f.date_sk = t.date_sk
  GROUP BY q.code_enquete, t.annee
  UNION ALL
  SELECT '5. Professionnels dont les poids du pont font 1',
         sum(CASE WHEN abs(somme_poids - 1) < 1e-9 THEN 1 ELSE 0 END), count(*)
  FROM (SELECT professionnel_sk, sum(poids) AS somme_poids
        FROM chu.gold.pont_professionnel_etablissement GROUP BY professionnel_sk)
  UNION ALL
  SELECT '6. Professionnels rattachés à au moins une structure connue',
         sum(a_structure), count(*)
  FROM (SELECT professionnel_sk,
               max(CASE WHEN etablissement_sk <> -1 THEN 1 ELSE 0 END) AS a_structure
        FROM chu.gold.pont_professionnel_etablissement GROUP BY professionnel_sk)
)
SELECT controle, conformes, total,
       round(100 * conformes / total, 2) AS taux_pct
FROM controles
ORDER BY controle;

-- COMMAND ----------

-- 10. Unicité des clés : Databricks applique NOT NULL, mais ni PRIMARY KEY ni FOREIGN KEY.
--     Faits et pont : clé primaire. Dimensions : clé naturelle (en double, elle multiplierait
--     les faits à la jointure Gold ; le membre -1 est inclus). fait_deces n'a pas de clé.
--     nb_anomalies = lignes en trop (3 lignes pour une même clé = 2 anomalies).
INSERT INTO chu.quality.resultats_controles
  (id_execution, date_controle, couche, entite, controle, dimension, description,
   nb_examinees, nb_anomalies, taux_conformite, seuil_pct, gravite, statut)
WITH mesures AS (
  SELECT 'fait_hospitalisation' AS entite, 'hospitalisation_id' AS cle,
         count(*) AS nb_examinees, count(*) - count(DISTINCT hospitalisation_id) AS nb_anomalies
  FROM chu.gold.fait_hospitalisation
  UNION ALL SELECT 'fait_consultation', 'consultation_id',
         count(*), count(*) - count(DISTINCT consultation_id)
  FROM chu.gold.fait_consultation
  UNION ALL SELECT 'fait_satisfaction', 'finess_geo, enquete_sk, date_sk',
         count(*), count(*) - count(DISTINCT finess_geo, enquete_sk, date_sk)
  FROM chu.gold.fait_satisfaction
  UNION ALL SELECT 'pont_professionnel_etablissement', 'professionnel_sk, etablissement_sk',
         count(*), count(*) - count(DISTINCT professionnel_sk, etablissement_sk)
  FROM chu.gold.pont_professionnel_etablissement
  UNION ALL SELECT 'dim_patient', 'patient_id',
         count(*), count(*) - count(DISTINCT patient_id)
  FROM chu.gold.dim_patient
  UNION ALL SELECT 'dim_diagnostic', 'code_diag',
         count(*), count(*) - count(DISTINCT code_diag)
  FROM chu.gold.dim_diagnostic
  UNION ALL SELECT 'dim_etablissement', 'identifiant_organisation',
         count(*), count(*) - count(DISTINCT identifiant_organisation)
  FROM chu.gold.dim_etablissement
  UNION ALL SELECT 'dim_professionnel', 'type_identifiant, identifiant',
         count(*), count(*) - count(DISTINCT type_identifiant, identifiant)
  FROM chu.gold.dim_professionnel
  UNION ALL SELECT 'dim_region', 'code_region',
         count(*), count(*) - count(DISTINCT code_region)
  FROM chu.gold.dim_region
  UNION ALL SELECT 'dim_enquete', 'code_enquete',
         count(*), count(*) - count(DISTINCT code_enquete)
  FROM chu.gold.dim_enquete
),
calcul AS (
  SELECT *, 100 * try_divide(nb_examinees - nb_anomalies, nb_examinees) AS taux_exact
  FROM mesures
)
SELECT id_execution, current_timestamp(), 'gold', entite,
       CASE WHEN entite LIKE 'dim%' THEN 'cle_naturelle_unique' ELSE 'pk_unique' END,
       'unicite',
       concat('Aucune ligne en double sur (', cle, ')'),
       nb_examinees, nb_anomalies, CAST(taux_exact AS DECIMAL(7,4)), CAST(100 AS DECIMAL(7,4)), 'bloquant',
       CASE WHEN taux_exact >= 100 THEN 'OK' ELSE 'KO' END
FROM calcul;

-- COMMAND ----------

-- 11. Intégrité référentielle : chaque clé étrangère d'un fait existe dans sa dimension.
--     Databricks n'applique pas les FOREIGN KEY. Une clé orpheline disparaît en silence des vues
--     d'indicateurs (jointures internes). Le -1 n'est pas orphelin : il existe dans chaque dimension.
--     Méthode : jointure gauche sur la dimension ; aucune correspondance = clé orpheline.
INSERT INTO chu.quality.resultats_controles
  (id_execution, date_controle, couche, entite, controle, dimension, description,
   nb_examinees, nb_anomalies, taux_conformite, seuil_pct, gravite, statut)
WITH mesures AS (
  SELECT 'fait_hospitalisation' AS entite, 'patient_sk' AS cle, 'dim_patient' AS dimension_cible,
         count(*) AS nb_examinees, count_if(d.patient_sk IS NULL) AS nb_anomalies
  FROM chu.gold.fait_hospitalisation f
  LEFT JOIN chu.gold.dim_patient d ON f.patient_sk = d.patient_sk
  UNION ALL
  SELECT 'fait_hospitalisation', 'diagnostic_sk', 'dim_diagnostic', count(*), count_if(d.diagnostic_sk IS NULL)
  FROM chu.gold.fait_hospitalisation f
  LEFT JOIN chu.gold.dim_diagnostic d ON f.diagnostic_sk = d.diagnostic_sk
  UNION ALL
  SELECT 'fait_hospitalisation', 'etablissement_sk', 'dim_etablissement', count(*), count_if(d.etablissement_sk IS NULL)
  FROM chu.gold.fait_hospitalisation f
  LEFT JOIN chu.gold.dim_etablissement d ON f.etablissement_sk = d.etablissement_sk
  UNION ALL
  SELECT 'fait_hospitalisation', 'date_entree_sk', 'dim_temps', count(*), count_if(d.date_sk IS NULL)
  FROM chu.gold.fait_hospitalisation f
  LEFT JOIN chu.gold.dim_temps d ON f.date_entree_sk = d.date_sk
  UNION ALL
  SELECT 'fait_hospitalisation', 'date_sortie_sk', 'dim_temps', count(*), count_if(d.date_sk IS NULL)
  FROM chu.gold.fait_hospitalisation f
  LEFT JOIN chu.gold.dim_temps d ON f.date_sortie_sk = d.date_sk
  UNION ALL
  SELECT 'fait_consultation', 'patient_sk', 'dim_patient', count(*), count_if(d.patient_sk IS NULL)
  FROM chu.gold.fait_consultation f
  LEFT JOIN chu.gold.dim_patient d ON f.patient_sk = d.patient_sk
  UNION ALL
  SELECT 'fait_consultation', 'professionnel_sk', 'dim_professionnel', count(*), count_if(d.professionnel_sk IS NULL)
  FROM chu.gold.fait_consultation f
  LEFT JOIN chu.gold.dim_professionnel d ON f.professionnel_sk = d.professionnel_sk
  UNION ALL
  SELECT 'fait_consultation', 'diagnostic_sk', 'dim_diagnostic', count(*), count_if(d.diagnostic_sk IS NULL)
  FROM chu.gold.fait_consultation f
  LEFT JOIN chu.gold.dim_diagnostic d ON f.diagnostic_sk = d.diagnostic_sk
  UNION ALL
  SELECT 'fait_consultation', 'date_sk', 'dim_temps', count(*), count_if(d.date_sk IS NULL)
  FROM chu.gold.fait_consultation f
  LEFT JOIN chu.gold.dim_temps d ON f.date_sk = d.date_sk
  UNION ALL
  SELECT 'fait_deces', 'date_sk', 'dim_temps', count(*), count_if(d.date_sk IS NULL)
  FROM chu.gold.fait_deces f
  LEFT JOIN chu.gold.dim_temps d ON f.date_sk = d.date_sk
  UNION ALL
  SELECT 'fait_deces', 'region_sk', 'dim_region', count(*), count_if(d.region_sk IS NULL)
  FROM chu.gold.fait_deces f
  LEFT JOIN chu.gold.dim_region d ON f.region_sk = d.region_sk
  UNION ALL
  SELECT 'fait_satisfaction', 'etablissement_sk', 'dim_etablissement', count(*), count_if(d.etablissement_sk IS NULL)
  FROM chu.gold.fait_satisfaction f
  LEFT JOIN chu.gold.dim_etablissement d ON f.etablissement_sk = d.etablissement_sk
  UNION ALL
  SELECT 'fait_satisfaction', 'region_sk', 'dim_region', count(*), count_if(d.region_sk IS NULL)
  FROM chu.gold.fait_satisfaction f
  LEFT JOIN chu.gold.dim_region d ON f.region_sk = d.region_sk
  UNION ALL
  SELECT 'fait_satisfaction', 'enquete_sk', 'dim_enquete', count(*), count_if(d.enquete_sk IS NULL)
  FROM chu.gold.fait_satisfaction f
  LEFT JOIN chu.gold.dim_enquete d ON f.enquete_sk = d.enquete_sk
  UNION ALL
  SELECT 'fait_satisfaction', 'date_sk', 'dim_temps', count(*), count_if(d.date_sk IS NULL)
  FROM chu.gold.fait_satisfaction f
  LEFT JOIN chu.gold.dim_temps d ON f.date_sk = d.date_sk
  UNION ALL
  SELECT 'pont_professionnel_etablissement', 'professionnel_sk', 'dim_professionnel', count(*), count_if(d.professionnel_sk IS NULL)
  FROM chu.gold.pont_professionnel_etablissement f
  LEFT JOIN chu.gold.dim_professionnel d ON f.professionnel_sk = d.professionnel_sk
  UNION ALL
  SELECT 'pont_professionnel_etablissement', 'etablissement_sk', 'dim_etablissement', count(*), count_if(d.etablissement_sk IS NULL)
  FROM chu.gold.pont_professionnel_etablissement f
  LEFT JOIN chu.gold.dim_etablissement d ON f.etablissement_sk = d.etablissement_sk
),
calcul AS (
  SELECT *, 100 * try_divide(nb_examinees - nb_anomalies, nb_examinees) AS taux_exact
  FROM mesures
)
SELECT id_execution, current_timestamp(), 'gold', entite, concat('fk_', cle), 'integrite',
       concat(cle, ' existe dans ', dimension_cible),
       nb_examinees, nb_anomalies, CAST(taux_exact AS DECIMAL(7,4)), CAST(100 AS DECIMAL(7,4)), 'bloquant',
       CASE WHEN taux_exact >= 100 THEN 'OK' ELSE 'KO' END
FROM calcul;

-- COMMAND ----------

-- 12. Bilan de l'exécution : tous les contrôles de ce passage, les KO bloquants en premier.
--     session.id_execution désigne la variable (sans préfixe, c'est la colonne qui serait lue).
SELECT statut, gravite, dimension, entite, controle,
       nb_examinees, nb_anomalies, taux_conformite, seuil_pct, description
FROM chu.quality.resultats_controles
WHERE id_execution = session.id_execution
ORDER BY CASE statut  WHEN 'KO'       THEN 0 ELSE 1 END,
         CASE gravite WHEN 'bloquant' THEN 0 ELSE 1 END,
         dimension, entite, controle;