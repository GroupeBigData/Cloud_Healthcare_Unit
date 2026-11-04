-- Gold - DML dim_professionnel. Prérequis : sql/ddl/gold/06_dim_professionnel.sql
INSERT OVERWRITE chu.gold.dim_professionnel
  (type_identifiant, identifiant, categorie_professionnelle, profession,
   code_specialite, fonction, specialite)
SELECT p.type_identifiant, p.identifiant_normalise, p.categorie_professionnelle,
       p.profession, p.code_specialite, s.fonction, s.specialite
FROM chu.silver.professionnel p
LEFT JOIN chu.silver.specialite s ON p.code_specialite = s.code_specialite;

INSERT INTO chu.gold.dim_professionnel
  (professionnel_sk, type_identifiant, identifiant, specialite)
VALUES (-1, '?', 'INCONNU', 'Professionnel inconnu');