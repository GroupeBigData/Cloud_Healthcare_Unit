-- ============================================================
-- 10_controles_silver.sql
-- Contrôles à lancer après les 3 scripts Silver.
-- Aucun chargement Gold.
-- ============================================================

-- 1. Volumes et équilibre
SELECT 'specialite' AS objet, count(*) AS lignes FROM chu.silver.specialite
UNION ALL
SELECT 'professionnel', count(*) FROM chu.silver.professionnel
UNION ALL
SELECT 'consultation', count(*) FROM chu.silver.consultation
UNION ALL
SELECT 'rejets_specialite', count(*) FROM chu.silver.rejets WHERE table_cible = 'specialite'
UNION ALL
SELECT 'rejets_professionnel', count(*) FROM chu.silver.rejets WHERE table_cible = 'professionnel'
UNION ALL
SELECT 'rejets_consultation', count(*) FROM chu.silver.rejets WHERE table_cible = 'consultation';

-- Attendu :
-- specialite 93 ; professionnel 1 048 575 ; consultation 1 027 157 ; rejets 0 / 0 / 0.

-- 2. Doublons dans les clés naturelles
SELECT 'specialite' AS objet,
       count(*) - count(DISTINCT code_specialite) AS doublons
FROM chu.silver.specialite
UNION ALL
SELECT 'professionnel',
       count(*) - count(DISTINCT concat(type_identifiant, '|', identifiant_normalise))
FROM chu.silver.professionnel
UNION ALL
SELECT 'consultation',
       count(*) - count(DISTINCT num_consultation)
FROM chu.silver.consultation;

-- Attendu : 0 / 0 / 0.

-- 3. Professionnels : types et spécialité manquante
SELECT type_identifiant, count(*) AS lignes
FROM chu.silver.professionnel
GROUP BY type_identifiant
ORDER BY type_identifiant;

SELECT count(*) AS professionnels_sans_specialite
FROM chu.silver.professionnel p
LEFT JOIN chu.silver.specialite s
  ON p.code_specialite = s.code_specialite
WHERE s.code_specialite IS NULL;

-- Attendu : ADELI 690 073 ; RPPS 358 502 ; 1 professionnel sans spécialité.

-- 4. Consultations : durée, nuits, orphelins professionnel
SELECT
  count(*) AS lignes,
  sum(CASE WHEN duree_minutes IS NULL THEN 1 ELSE 0 END) AS duree_null,
  sum(CASE WHEN duree_minutes < 0 THEN 1 ELSE 0 END) AS duree_negative,
  min(duree_minutes) AS duree_min,
  max(duree_minutes) AS duree_max,
  sum(CASE WHEN date(fin_ts) > date(debut_ts) THEN 1 ELSE 0 END) AS nuits_corrigees,
  sum(CASE WHEN fk_prof_ok = false THEN 1 ELSE 0 END) AS professionnels_inconnus
FROM chu.silver.consultation;

-- Attendu : 1 027 157 lignes ; 0 null ; 0 négatif ; 10 nuits ; 0 inconnu.

-- 5. Couverture de dim_temps
SELECT count(*) AS consultations_hors_dim_temps
FROM chu.silver.consultation c
LEFT JOIN chu.gold.dim_temps t
  ON c.date_sk = t.date_sk
WHERE t.date_sk IS NULL;

-- Attendu : 0.

-- 6. Répartition des rejets par règle
SELECT table_cible, regle, count(*) AS lignes
FROM chu.silver.rejets
GROUP BY table_cible, regle
ORDER BY table_cible, regle;
