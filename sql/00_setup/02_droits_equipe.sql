-- sql/00_setup/02_droits_equipe.sql
-- Prototype : les 3 membres du groupe sont data engineers sur tout le catalogue.
GRANT ALL PRIVILEGES ON CATALOG chu TO `aya.mohamedfadelduihi@viacesi.fr`;
GRANT ALL PRIVILEGES ON CATALOG chu TO `joachim.farabet@viacesi.fr`;
GRANT ALL PRIVILEGES ON CATALOG chu TO `molka.chergui@viacesi.fr`;


SHOW GRANTS ON CATALOG chu;