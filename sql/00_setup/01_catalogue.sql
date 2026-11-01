-- sql/00_setup/01_catalogue.sql
-- Structure du projet CHU dans Unity Catalog

CREATE CATALOG IF NOT EXISTS chu
  COMMENT 'Projet Cloud Healthcare Unit - entrepôt de données décisionnel (prototype anonymisé)';

CREATE SCHEMA IF NOT EXISTS chu.bronze  COMMENT 'Données brutes, fidèles à la source, tout en texte';
CREATE SCHEMA IF NOT EXISTS chu.silver  COMMENT 'Données typées, nettoyées, harmonisées ; table des rejets';
CREATE SCHEMA IF NOT EXISTS chu.gold    COMMENT 'Modèle en étoile : dimensions, faits, vues des indicateurs';
CREATE SCHEMA IF NOT EXISTS chu.quality COMMENT 'Résultats des contrôles qualité';
CREATE SCHEMA IF NOT EXISTS chu.bench   COMMENT 'Copies non optimisées pour le benchmark avant/après';

CREATE VOLUME IF NOT EXISTS chu.bronze.landing
  COMMENT 'Zone d''atterrissage des fichiers préparés en local (équivalent du bucket S3 de la cible)';

SHOW SCHEMAS IN chu;