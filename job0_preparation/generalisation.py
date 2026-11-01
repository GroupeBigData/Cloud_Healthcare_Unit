"""
Job 0 – Étape 4 : généralisation des quasi-identifiants des patients + test de k-anonymat.

patient.csv : Date (naissance complète) -> annee_naissance ; Sexe -> sexe (M/F) ;
Code_postal et Pays supprimés (aucun indicateur ne s'en sert).
Toute combinaison (sexe, année) partagée par moins de K patients voit son année vidée.

Usage (PowerShell, depuis job0_preparation) :
    python generalisation.py
"""

import pandas as pd

from extraction import DOSSIER_SORTIE

FICHIER_PATIENT = DOSSIER_SORTIE / "postgres" / "patient" / "patient.csv"
K = 5
FICHIER_DECES = DOSSIER_SORTIE / "deces" / "deces" / "deces.csv"
QUASI_IDENTIFIANTS = ["Sexe", "annee_naissance"]

def generaliser_patients() -> None:
    df = pd.read_csv(FICHIER_PATIENT, sep=";", dtype=str, keep_default_na=False, na_values=[""])
    if "Date" not in df.columns:
        print("  DÉJÀ    patient.csv déjà généralisé, ignoré")
        return

    sortie = pd.DataFrame({
        "id_patient_pseudo": df["id_patient_pseudo"],
        "Sexe": df["Sexe"],
        "annee_naissance": df["Date"].str.split("/").str[-1],
    })
    if sortie["Sexe"].isna().any():
        raise SystemExit("Valeur de sexe inattendue : à examiner avant de continuer")

    # Test de k-anonymat : taille du groupe (sexe, année) de chaque patient
    taille = sortie.groupby(QUASI_IDENTIFIANTS)["id_patient_pseudo"].transform("size")
    a_risque = taille < K
    sortie.loc[a_risque, "annee_naissance"] = None

    reste = sortie.dropna(subset=["annee_naissance"])
    plus_petit = reste.groupby(QUASI_IDENTIFIANTS).size().min()

    sortie.to_csv(FICHIER_PATIENT, sep=";", index=False, encoding="utf-8")
    print(f"  OK      patient.csv {len(sortie):>9,} lignes")
    print(f"          {a_risque.sum():,} patients dans un groupe de moins de {K} : année vidée")
    print(f"          plus petit groupe restant : {plus_petit} patients (k = {plus_petit})")
def generaliser_deces() -> None:
    entete = pd.read_csv(FICHIER_DECES, sep=";", nrows=0).columns
    if "date_naissance" not in entete:
        print("  DÉJÀ    deces.csv déjà généralisé, ignoré")
        return

    temporaire = FICHIER_DECES.with_suffix(".tmp")
    lecture = pd.read_csv(FICHIER_DECES, sep=";", dtype=str, keep_default_na=False,
                          na_values=[""], chunksize=500_000)
    total = 0
    departements = pd.Series(dtype="int64")

    for i, m in enumerate(lecture):
        code = m["code_lieu_deces"].str.strip()
        dep = code.str[:2].where(~code.str.startswith("97", na=False), code.str[:3])

        sortie = pd.DataFrame({
            "sexe": m["sexe"],
            "annee_naissance": m["date_naissance"].str[:4],
            "date_deces": m["date_deces"],
            "departement_deces": dep,
        })
        sortie.to_csv(temporaire, sep=";", index=False, encoding="utf-8",
                      mode="w" if i == 0 else "a", header=(i == 0))

        total += len(sortie)
        departements = departements.add(dep.value_counts(dropna=False), fill_value=0)
        print(f"\r          {total:>12,} lignes", end="")

    temporaire.replace(FICHIER_DECES)
    print(f"\r  OK      deces.csv {total:>12,} lignes")
    print(f"          {len(departements)} codes de département distincts :")
    print("          " + ", ".join(sorted(map(str, departements.index))))

def main() -> None:
    print("Généralisation")
    generaliser_patients()
    generaliser_deces()


if __name__ == "__main__":
    main()