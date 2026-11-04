-- Gold - DML dim_enquete. Prérequis : sql/ddl/gold/07_dim_enquete.sql
-- Lignes écrites ici : il n'existe pas de liste des enquêtes dans les sources.
INSERT OVERWRITE chu.gold.dim_enquete (code_enquete, libelle, perimetre) VALUES
  ('48H_MCO', 'e-Satis +48h MCO',
   'Patients hospitalisés plus de 48 h en médecine, chirurgie ou obstétrique'),
  ('CA_MCO',  'e-Satis chirurgie ambulatoire',
   'Patients opérés en chirurgie ambulatoire, sortis le jour même');

INSERT INTO chu.gold.dim_enquete (enquete_sk, code_enquete, libelle)
VALUES (-1, 'INCONNU', 'Enquête inconnue');