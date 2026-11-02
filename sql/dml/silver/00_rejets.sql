-- Table des rejets Silver, commune à tout le groupe.
CREATE TABLE IF NOT EXISTS chu.silver.rejets (
  table_cible      STRING    COMMENT 'Table Silver que la ligne aurait dû alimenter',
  table_source     STRING    COMMENT 'Table Bronze d''origine',
  regle            STRING    COMMENT 'Code de la règle violée (ex. finess_vide)',
  cle              STRING    COMMENT 'Clé naturelle de la ligne rejetée',
  valeur           STRING    COMMENT 'Valeur fautive',
  _fichier_source  STRING    COMMENT 'Fichier d''origine, repris de Bronze',
  _id_lot          STRING    COMMENT 'Lot de chargement Bronze',
  date_rejet       TIMESTAMP COMMENT 'Moment du rejet (UTC)'
) COMMENT 'Lignes écartées par les règles Silver, avec leur motif - commune au groupe';