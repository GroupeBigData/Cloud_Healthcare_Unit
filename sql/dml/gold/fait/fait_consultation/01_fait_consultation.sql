-- Gold - DML fait_consultation. Prérequis : DDL 11_fait_consultation.sql et les dimensions.
-- Jointures gauches : aucune consultation ne disparaît ; une dimension introuvable donne -1.
INSERT OVERWRITE chu.gold.fait_consultation
SELECT c.num_consultation,
       coalesce(p.patient_sk, -1),
       coalesce(pr.professionnel_sk, -1),
       coalesce(d.diagnostic_sk, -1),
       c.date_sk,
       c.duree_minutes,
       1
FROM chu.silver.consultation c
LEFT JOIN chu.gold.dim_patient p
       ON c.id_patient_pseudo = p.patient_id AND p.patient_sk <> -1
LEFT JOIN chu.gold.dim_professionnel pr
       ON pr.type_identifiant = 'RPPS' AND c.id_prof_sante = pr.identifiant
      AND pr.professionnel_sk <> -1
LEFT JOIN chu.gold.dim_diagnostic d
       ON upper(c.code_diag) = d.code_diag AND d.diagnostic_sk <> -1;