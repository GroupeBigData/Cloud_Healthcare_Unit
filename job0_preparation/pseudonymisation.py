"""
Job 0 – Étape 2 : pseudonymisation de Id_patient (HMAC-SHA256 avec clé secrète).

Remplace la colonne Id_patient par id_patient_pseudo dans les 3 fichiers qui la contiennent.
Même clé et même fonction partout : les jointures entre fichiers restent possibles.

Usage (PowerShell, depuis job0_preparation) :
    $env:CHU_CLE_HMAC = "la_cle_secrete"
    python pseudonymisation.py
"""

import hashlib
import hmac
import os

import pandas as pd

from extraction import DOSSIER_SORTIE

FICHIERS = [
    DOSSIER_SORTIE / "postgres" / "patient" / "patient.csv",
    DOSSIER_SORTIE / "postgres" / "consultation" / "consultation.csv",
    DOSSIER_SORTIE / "hospitalisation" / "hospitalisations" / "hospitalisations.csv",
]
COLONNE_SOURCE = "Id_patient"
COLONNE_PSEUDO = "id_patient_pseudo"


def lire_cle() -> bytes:
    """Lit la clé secrète dans l'environnement ; jamais dans le code."""
    cle = os.environ.get("CHU_CLE_HMAC", "")
    if len(cle) < 32:
        raise SystemExit("CHU_CLE_HMAC absente ou trop courte (32 caractères minimum)")
    return cle.encode("utf-8")


def pseudonymiser(valeur: str, cle: bytes) -> str:
    """Code irréversible sans la clé, et toujours identique pour une même valeur."""
    return hmac.new(cle, valeur.encode("utf-8"), hashlib.sha256).hexdigest()


def traiter(fichier, cle: bytes) -> None:
    """Remplace Id_patient par id_patient_pseudo, à la même place dans le fichier."""
    df = pd.read_csv(fichier, sep=";", dtype=str, keep_default_na=False, na_values=[""])

    if COLONNE_SOURCE not in df.columns:
        if COLONNE_PSEUDO in df.columns:
            print(f"  DÉJÀ    {fichier.name:<25} déjà pseudonymisé, ignoré")
            return
        raise SystemExit(f"{fichier.name} : colonne {COLONNE_SOURCE} introuvable")

    ids = df[COLONNE_SOURCE].str.strip()
    correspondance = {v: pseudonymiser(v, cle) for v in ids.dropna().unique()}

    position = df.columns.get_loc(COLONNE_SOURCE)
    df.insert(position, COLONNE_PSEUDO, ids.map(correspondance))
    df = df.drop(columns=COLONNE_SOURCE)
    df.to_csv(fichier, sep=";", index=False, encoding="utf-8")
    print(f"  OK      {fichier.name:<25} {len(df):>12,} lignes  "
          f"{len(correspondance):>9,} patients distincts")


def lire_ids(fichier) -> pd.Series:
    return pd.read_csv(fichier, sep=";", dtype=str, usecols=[COLONNE_PSEUDO])[COLONNE_PSEUDO]


def verifier_jointures() -> None:
    """Chaque consultation et chaque séjour retrouve-t-il son patient ?"""
    patients = set(lire_ids(FICHIERS[0]))
    for fichier in FICHIERS[1:]:
        taux = lire_ids(fichier).isin(patients).mean() * 100
        print(f"  {fichier.name:<25} {taux:6.2f} % des lignes retrouvent leur patient")


def main() -> None:
    cle = lire_cle()
    print("Pseudonymisation")
    for fichier in FICHIERS:
        traiter(fichier, cle)
    print("\nContrôle des jointures")
    verifier_jointures()


if __name__ == "__main__":
    main()