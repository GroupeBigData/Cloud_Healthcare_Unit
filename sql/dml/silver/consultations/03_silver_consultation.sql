-- ============================================================
-- 03_silver_consultation.sql
-- Source Bronze : chu.bronze.consultation (1 027 157 lignes)
-- Grain         : une consultation
-- Attendu       : 1 027 157 lignes Silver, 0 rejet
-- À exécuter après : 02_silver_professionnel.sql
--
-- Règles validées par le profilage :
--   Date        : yyyy-MM-dd
--   Heures      : HH:mm:ss
--   10 lignes   : 20:00 -> 02:00 = consultation de nuit, +24 h
--   Id_prof_sante : RPPS 11 caractères, clé trim()
--
-- fk_patient_ok / fk_diag_ok seront ajoutés dans un script 04
-- quand les tables patient/diagnostic de A seront disponibles.
-- ============================================================

-- 1. Typer, corriger les nuits, calculer la durée et marquer les rejets
CREATE OR REPLACE TEMPORARY VIEW silver_consultation_marks AS
WITH src AS (
  SELECT
    trim(Num_consultation)                         AS num_consultation,
    NULLIF(trim(id_patient_pseudo), '')            AS id_patient_pseudo,
    NULLIF(trim(Id_prof_sante), '')                AS id_prof_sante,
    NULLIF(trim(Code_diag), '')                    AS code_diag,
    trim(`Date`)                                   AS date_source,
    trim(`Heure_debut`)                            AS heure_debut_source,
    trim(`Heure_fin`)                              AS heure_fin_source,
    try_to_date(`Date`, 'yyyy-MM-dd')              AS date_consultation,
    try_to_timestamp(
      concat(trim(`Date`), ' ', trim(`Heure_debut`)),
      'yyyy-MM-dd HH:mm:ss'
    )                                              AS debut_ts,
    try_to_timestamp(
      concat(trim(`Date`), ' ', trim(`Heure_fin`)),
      'yyyy-MM-dd HH:mm:ss'
    )                                              AS fin_ts,
    _fichier_source,
    _date_chargement,
    _id_lot
  FROM chu.bronze.consultation
),
corrected AS (
  SELECT
    *,
    CASE
      WHEN debut_ts IS NOT NULL
       AND fin_ts IS NOT NULL
       AND fin_ts < debut_ts
        THEN fin_ts + INTERVAL 1 DAY
      ELSE fin_ts
    END AS fin_ts_corrige
  FROM src
),
durations AS (
  SELECT
    *,
    CASE
      WHEN debut_ts IS NOT NULL AND fin_ts_corrige IS NOT NULL
        THEN CAST(
          round(
            (unix_timestamp(fin_ts_corrige) - unix_timestamp(debut_ts)) / 60.0,
            0
          ) AS INT
        )
    END AS duree_minutes
  FROM corrected
),
marks AS (
  SELECT
    *,
    CASE
      WHEN num_consultation IS NULL OR num_consultation = ''
        THEN 'num_consultation_vide'
      WHEN id_prof_sante IS NULL OR id_prof_sante = ''
        THEN 'id_prof_sante_vide'
      WHEN code_diag IS NULL OR code_diag = ''
        THEN 'code_diag_vide'
      WHEN date_consultation IS NULL
        THEN 'date_illisible'
      WHEN debut_ts IS NULL
        THEN 'heure_debut_illisible'
      WHEN fin_ts IS NULL
        THEN 'heure_fin_illisible'
      WHEN duree_minutes IS NULL OR duree_minutes < 0
        THEN 'duree_negative'
    END AS motif_rejet,
    row_number() OVER (
      PARTITION BY num_consultation
      ORDER BY _date_chargement DESC, _fichier_source
    ) AS rn
  FROM durations
)
SELECT * FROM marks;

-- 2. Remplacer les rejets de cette table
DELETE FROM chu.silver.rejets
WHERE table_cible = 'consultation';

INSERT INTO chu.silver.rejets
  (table_cible, table_source, regle, cle, valeur,
   _fichier_source, _id_lot, date_rejet)
SELECT
  'consultation',
  'consultation',
  COALESCE(motif_rejet, 'doublon_num_consultation'),
  COALESCE(num_consultation, ''),
  concat_ws(' ', date_source, heure_debut_source, heure_fin_source),
  _fichier_source,
  _id_lot,
  current_timestamp()
FROM silver_consultation_marks
WHERE motif_rejet IS NOT NULL OR rn > 1;

-- 3. Table Silver : 1 027 157 lignes attendues
CREATE OR REPLACE TABLE chu.silver.consultation (
  num_consultation   STRING NOT NULL COMMENT 'Num_consultation source, sans espaces',
  id_patient_pseudo  STRING COMMENT 'Identifiant patient pseudonymisé',
  id_prof_sante      STRING NOT NULL COMMENT 'RPPS 11 caractères, normalisé par trim',
  code_diag          STRING COMMENT 'Code diagnostic source, sans espaces',
  date_consultation  DATE NOT NULL COMMENT 'Date de début de la consultation',
  debut_ts           TIMESTAMP NOT NULL COMMENT 'Date + Heure_debut',
  fin_ts             TIMESTAMP NOT NULL COMMENT 'Date + Heure_fin, +24 h si consultation de nuit',
  duree_minutes      INT COMMENT 'Durée en minutes, arrondie à la minute ; NULL si heure illisible',
  date_sk            INT NOT NULL COMMENT 'Clé date AAAAMMJJ pour dim_temps',
  fk_prof_ok         BOOLEAN NOT NULL COMMENT 'Vrai si le RPPS existe dans silver.professionnel',
  _fichier_source    STRING COMMENT 'Fichier Bronze d''origine',
  _date_chargement   TIMESTAMP COMMENT 'Date de chargement Bronze',
  _id_lot            STRING COMMENT 'Lot de chargement Bronze'
) COMMENT 'Consultations nettoyées et typées, une ligne par Num_consultation';

INSERT INTO chu.silver.consultation
SELECT
  m.num_consultation,
  m.id_patient_pseudo,
  m.id_prof_sante,
  m.code_diag,
  m.date_consultation,
  m.debut_ts,
  m.fin_ts_corrige AS fin_ts,
  m.duree_minutes,
  CAST(
    year(m.date_consultation) * 10000
    + month(m.date_consultation) * 100
    + day(m.date_consultation)
    AS INT
  ) AS date_sk,
  (p.identifiant_normalise IS NOT NULL) AS fk_prof_ok,
  m._fichier_source,
  m._date_chargement,
  m._id_lot
FROM silver_consultation_marks m
LEFT JOIN chu.silver.professionnel p
  ON p.type_identifiant = 'RPPS'
 AND p.identifiant_normalise = m.id_prof_sante
WHERE m.motif_rejet IS NULL
  AND m.rn = 1;

-- 4. Contrôles d'équilibre et de qualité
SELECT
  'consultation' AS objet, count(*) AS lignes
FROM chu.silver.consultation
UNION ALL
SELECT
  'rejets_consultation', count(*)
FROM chu.silver.rejets
WHERE table_cible = 'consultation';

SELECT
  count(*) AS lignes,
  sum(CASE WHEN duree_minutes IS NULL THEN 1 ELSE 0 END) AS duree_null,
  sum(CASE WHEN duree_minutes < 0 THEN 1 ELSE 0 END) AS duree_negative,
  min(duree_minutes) AS duree_min,
  max(duree_minutes) AS duree_max,
  sum(CASE WHEN date(fin_ts) > date(debut_ts) THEN 1 ELSE 0 END) AS nuits_corrigees,
  sum(CASE WHEN fk_prof_ok = false THEN 1 ELSE 0 END) AS professionnels_inconnus,
  min(date_sk) AS date_sk_min,
  max(date_sk) AS date_sk_max
FROM chu.silver.consultation;
