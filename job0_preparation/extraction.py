"""
Job 0 – Étape 1 : extraction en liste blanche (minimisation RGPD).

Ne lit, dans chaque source, QUE les colonnes nécessaires aux indicateurs.
Les identifiants directs (nom, prénom, NIR, adresse, e-mail, téléphone)
ne sont jamais lus, donc ne peuvent pas se retrouver dans les fichiers produits.

Usage (PowerShell) :
    $env:PGPASSWORD = "*.*"
    python extraction.py
"""

from pathlib import Path
import csv
import pandas as pd
import psycopg

# ---------------------------------------------------------------------------
# 0. Configuration
# ---------------------------------------------------------------------------
DOSSIER_SOURCES = Path(r"C:\Users\kaout\Downloads\DATA_2024\DATA_2024")
DOSSIER_SORTIE = Path("landing_local")
CONNEXION_PG = "host=localhost port=5432 dbname=chu_source user=postgres"
# ---------------------------------------------------------------------------
# 1. Liste blanche PostgreSQL : les SEULES colonnes extraites
# ---------------------------------------------------------------------------
# nom de sortie -> (table source, colonnes gardées)
TABLES_PG = {
    "patient": ("Patient", ["Id_patient", "Sexe", "Date", "Code_postal", "Pays"]),
    "consultation": ("Consultation", ["Num_consultation", "Id_patient", "Id_prof_sante",
                                      "Code_diag", "Date", "Heure_debut", "Heure_fin"]),
    "diagnostic": ("Diagnostic", ["Code_diag", "Diagnostic"]),
    "specialites": ("Specialites", ["Code_specialite", "Fonction", "Specialite"]),
    "professionnel_de_sante": ("Professionnel_de_sante",
                               ["Identifiant", "Categorie_professionnelle", "Profession",
                                "Type_identifiant", "Code_specialite"]),
}
# ---------------------------------------------------------------------------
# 2. Liste blanche des fichiers CSV : les SEULES colonnes extraites
# ---------------------------------------------------------------------------
# nom de sortie -> (chemin dans DATA_2024, encodage, séparateur, dossier landing, colonnes gardées)
FICHIERS_CSV = {
    "hospitalisations": ("Hospitalisation/Hospitalisations.csv", "utf-8-sig", ";",
                         "hospitalisation",
                         ["Num_Hospitalisation", "Id_patient", "identifiant_organisation",
                          "Code_diagnostic", "Date_Entree", "Jour_Hospitalisation"]),
    "etablissement_sante": ("Etablissement_de_SANTE/etablissement_sante.csv", "utf-8-sig", ";",
                            "etablissements",
                            ["identifiant_organisation", "finess_site",
                             "finess_etablissement_juridique", "raison_sociale_site",
                             "code_commune", "code_postal", "commune"]),
    "activite_professionnel_sante": ("Etablissement_de_SANTE/activite_professionnel_sante.csv",
                                     "utf-8-sig", ";", "etablissements",
                                     ["identifiant", "identifiant_organisation", "mode_exercice"]),
    "deces": ("DECES_EN_FRANCE/deces.csv", "utf-8-sig", ",", "deces",
              ["sexe", "date_naissance", "date_deces", "code_lieu_deces"]),
}
def verifier_prerequis() -> None:
    """Vérifie que les deux sources sont accessibles avant toute extraction."""
    # 1. Le dossier des fichiers sources existe-t-il ?
    if not DOSSIER_SOURCES.is_dir():
        raise SystemExit(f"Dossier introuvable : {DOSSIER_SOURCES}")
    print(f"  OK      dossier sources : {DOSSIER_SOURCES}")

    # 2. PostgreSQL répond-il, et quelles tables voit-on ?
    with psycopg.connect(CONNEXION_PG) as conn:
        tables = conn.execute(
            "SELECT table_name FROM information_schema.tables "
            "WHERE table_schema = 'public' ORDER BY table_name"
        ).fetchall()
    print(f"  OK      PostgreSQL : {len(tables)} tables -> "
          + ", ".join(t[0] for t in tables))

def extraire_table_pg(nom_sortie: str, table: str, colonnes: list[str]) -> int:
    """Exporte en CSV uniquement les colonnes de la liste blanche d'une table PostgreSQL."""
    selection = ", ".join(f'"{c}"' for c in colonnes)
    requete = (f'COPY (SELECT {selection} FROM public."{table}") '
               "TO STDOUT WITH (FORMAT csv, HEADER true, DELIMITER ';')")

    dossier = DOSSIER_SORTIE / "postgres" / nom_sortie
    dossier.mkdir(parents=True, exist_ok=True)
    sortie = dossier / f"{nom_sortie}.csv"

    with psycopg.connect(CONNEXION_PG) as conn:
        conn.execute("SET client_encoding TO 'UTF8'")
        with conn.cursor() as cur, cur.copy(requete) as copie, open(sortie, "wb") as f:
            for bloc in copie:
                f.write(bloc)

    # Comptage des lignes écrites, en-tête exclu
    with open(sortie, encoding="utf-8", newline="") as f:
        return sum(1 for _ in csv.reader(f, delimiter=";")) - 1
def extraire_csv(nom_sortie: str, chemin: str, encodage: str, sep: str,
                 dossier_landing: str, colonnes: list[str]) -> int:
    """Relit un CSV par morceaux en ne chargeant QUE les colonnes de la liste blanche."""
    dossier = DOSSIER_SORTIE / dossier_landing / nom_sortie
    dossier.mkdir(parents=True, exist_ok=True)
    sortie = dossier / f"{nom_sortie}.csv"

    morceaux = pd.read_csv(DOSSIER_SOURCES / chemin, sep=sep, encoding=encodage,
                           usecols=colonnes, dtype=str,
                           keep_default_na=False, na_values=[""],
                           chunksize=500_000)
    total = 0
    for i, morceau in enumerate(morceaux):
        morceau[colonnes].to_csv(sortie, sep=";", index=False, encoding="utf-8",
                                 mode="w" if i == 0 else "a", header=(i == 0))
        total += len(morceau)
    return total
def extraire_deces(nom_sortie: str, chemin: str, encodage: str, sep: str,
                   dossier_landing: str, colonnes: list[str]) -> int:
    """Décès : dédoublonne sur l'identité complète, puis n'écrit que la liste blanche.
    Les noms et prénoms ne sont utilisés qu'en mémoire, jamais écrits sur disque."""
    cle = ["nom", "prenom", "date_naissance", "date_deces", "code_lieu_deces"]
    source = DOSSIER_SOURCES / chemin
    lecture = dict(sep=sep, encoding=encodage, dtype=str,
                   keep_default_na=False, na_values=[""], chunksize=500_000)

    # Lecture 1 : une empreinte par ligne, calculée sur les colonnes d'identité
    empreintes, lues = [], 0
    for m in pd.read_csv(source, usecols=cle, **lecture):
        empreintes.append(pd.util.hash_pandas_object(m[cle], index=False))
        lues += len(m)
        print(f"\r          lecture 1/2 : {lues:>12,} lignes", end="")
    empreintes = pd.concat(empreintes, ignore_index=True)
    a_garder = (~empreintes.duplicated(keep="first")).to_numpy()
    nb_doublons = len(a_garder) - int(a_garder.sum())

    # Lecture 2 : seulement les colonnes autorisées, seulement les premières occurrences
    dossier = DOSSIER_SORTIE / dossier_landing / nom_sortie
    dossier.mkdir(parents=True, exist_ok=True)
    sortie = dossier / f"{nom_sortie}.csv"
    position, total = 0, 0
    for i, m in enumerate(pd.read_csv(source, usecols=colonnes, **lecture)):
        masque = a_garder[position:position + len(m)]
        position += len(m)
        m.loc[masque, colonnes].to_csv(sortie, sep=";", index=False, encoding="utf-8",
                                       mode="w" if i == 0 else "a", header=(i == 0))
        total += int(masque.sum())
        print(f"\r          lecture 2/2 : {position:>12,} lignes", end="")

    if position != lues:
        raise RuntimeError(f"Les deux lectures diffèrent : {lues:,} puis {position:,} lignes")
    print(f"\r          {nb_doublons:,} doublons retirés sur {lues:,} lignes lues")
    return total
def main() -> None:
    verifier_prerequis()

    print("\nExtraction PostgreSQL")
    for nom, (table, colonnes) in TABLES_PG.items():
        try:
            n = extraire_table_pg(nom, table, colonnes)
            print(f"  OK      {nom:<25} {n:>12,} lignes  {len(colonnes)} colonnes")
        except Exception as e:
            print(f"  ERREUR  {nom:<25} {type(e).__name__} : {e}")
    print("\nExtraction des fichiers CSV")
    for nom, (chemin, encodage, sep, dossier_landing, colonnes) in FICHIERS_CSV.items():
        try:
            fonction = extraire_deces if nom == "deces" else extraire_csv
            n = fonction(nom, chemin, encodage, sep, dossier_landing, colonnes)
            print(f"  OK      {nom:<30} {n:>12,} lignes  {len(colonnes)} colonnes")
        except Exception as e:
            print(f"  ERREUR  {nom:<30} {type(e).__name__} : {e}")


if __name__ == "__main__":
    main()