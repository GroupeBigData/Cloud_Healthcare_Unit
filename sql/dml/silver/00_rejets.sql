-- Table des rejets Silver, commune à tout le groupe.
-- À exécuter avant tout script Silver : chaque entité y écrit ses propres rejets.
--
-- Convention de nommage des règles (colonne regle), commune à toutes les entités :
--   <champ>_vide       champ obligatoire absent, nul ou réduit à des espaces
--   <champ>_illisible  valeur présente mais non convertible dans le type cible
--   <champ>_invalide   valeur convertible mais hors du domaine autorisé
--
-- Chaque script Silver efface ses propres rejets avant de les réécrire :
--   DELETE FROM chu.silver.rejets WHERE table_cible = '<son entité>';
-- Les doublons écartés par un dédoublonnage ne sont pas des rejets : ils sont
-- remplacés par une version plus récente de la même clé, pas écartés du périmètre.
CREATE TABLE IF NOT EXISTS chu.silver.rejets (
  table_cible      STRING    COMMENT 'Table Silver que la ligne aurait dû alimenter, sans préfixe de schéma',
  table_source     STRING    COMMENT 'Table Bronze d''origine, sans préfixe de schéma (toutes dans chu.bronze)',
  regle            STRING    COMMENT 'Code de la règle violée (ex. finess_geo_vide)',
  cle              STRING    COMMENT 'Clé naturelle de la ligne rejetée',
  valeur           STRING    COMMENT 'Valeur fautive',
  _fichier_source  STRING    COMMENT 'Fichier d''origine, repris de Bronze',
  _id_lot          STRING    COMMENT 'Lot de chargement Bronze',
  date_rejet       TIMESTAMP COMMENT 'Moment du rejet (UTC)'
) COMMENT 'Lignes écartées par les règles Silver, avec leur motif - commune au groupe';
