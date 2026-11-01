"""
Job 0 – Étape 5 : fichiers de satisfaction et d'indicateurs qualité (e-Satis, IPAQSS, IQSS).

Ces fichiers ne contiennent aucune donnée personnelle : leur contenu n'est pas modifié.
On les met seulement au format commun du dossier landing (CSV UTF-8, séparateur ;),
un dossier par fichier. Les lexiques et les PDF n'y vont pas : c'est de la documentation.

Usage (PowerShell, depuis job0_preparation) :
    python satisfaction.py
"""

import pandas as pd

from extraction import DOSSIER_SORTIE, DOSSIER_SOURCES

DOSSIER_SATISFACTION = DOSSIER_SOURCES / "Satisfaction"

# Fichiers écartés volontairement, avec leur raison (tracée dans la sortie)
EXCLUS = {
    "dpa_had_recueil2016_donnee2015_donnees.xlsx":
        "doublon du CSV du même nom, en-tête collé dans une seule cellule",
}


def lister_fichiers() -> list:
    """Tous les CSV et Excel du dossier Satisfaction, sauf lexiques et exclusions."""
    fichiers = []
    for f in sorted(DOSSIER_SATISFACTION.rglob("*")):
        if f.name.startswith("~$"):
            continue
        if f.suffix.lower() not in (".csv", ".xlsx"):
            continue
        if "lexique" in f.stem.lower():
            continue
        if f.name in EXCLUS:
            print(f"  EXCLU   {f.name} : {EXCLUS[f.name]}")
            continue
        fichiers.append(f)
    return fichiers


def lire_csv(f) -> pd.DataFrame:
    """Essaie l'UTF-8 puis le Windows-1252 ; le séparateur est détecté automatiquement."""
    for encodage in ("utf-8-sig", "cp1252"):
        try:
            return pd.read_csv(f, sep=None, engine="python", encoding=encodage,
                               dtype=str, keep_default_na=False, na_values=[""])
        except UnicodeDecodeError:
            continue
    raise ValueError("encodage non reconnu")


def lire_excel(f) -> pd.DataFrame:
    """Lit la première feuille, en texte, et retire les lignes entièrement vides."""
    feuilles = pd.read_excel(f, sheet_name=None, dtype=str,
                             keep_default_na=False, na_values=[""])
    if len(feuilles) > 1:
        print(f"          attention : {len(feuilles)} feuilles, seule la première est prise")
    df = next(iter(feuilles.values()))
    return df.dropna(how="all")


def convertir(f) -> tuple[int, int]:
    """Réécrit le fichier en CSV UTF-8 ; dans landing_local/satisfaction/<nom>/."""
    nom = f.stem.lower().replace("-", "_")
    df = lire_excel(f) if f.suffix.lower() == ".xlsx" else lire_csv(f)
    dossier = DOSSIER_SORTIE / "satisfaction" / nom
    dossier.mkdir(parents=True, exist_ok=True)
    df.to_csv(dossier / f"{nom}.csv", sep=";", index=False, encoding="utf-8")
    return len(df), len(df.columns)


def main() -> None:
    print("Satisfaction")
    for f in lister_fichiers():
        try:
            lignes, colonnes = convertir(f)
            print(f"  OK      {f.name:<52} {lignes:>7,} lignes  {colonnes:>3} colonnes")
        except Exception as e:
            print(f"  ERREUR  {f.name:<52} {type(e).__name__} : {e}")


if __name__ == "__main__":
    main()