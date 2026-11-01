"""
Job 0 – Étape 7 : contrôles avant envoi dans Databricks.

Pour chaque fichier de landing_local/ : nombre de lignes et de colonnes, colonnes au nom suspect,
valeurs ressemblant à un e-mail, un téléphone ou un NIR. Aucun fichier n'est modifié.
Résultat : rapport_extraction.csv (trace pour le Livrable 2).

Usage (PowerShell, depuis job0_preparation) :
    python controle_landing.py
"""

import csv
import re

import pandas as pd

from extraction import DOSSIER_SORTIE

RAPPORT = "rapport_extraction.csv"

# Morceaux de noms de colonnes qui ne devraient jamais apparaître...
NOMS_INTERDITS = ["nom", "prenom", "adresse", "mail", "tel", "secu", "nir", "id_patient"]
# ...sauf ces colonnes, vérifiées et légitimes
COLONNES_AUTORISEES = {"id_patient_pseudo", "nom_es"}

# Un seul motif avec trois alternatives nommées : une seule recherche par ligne
MOTIF = re.compile(
    r"(?P<email>[\w.+-]+@[\w-]+\.[\w.-]+)"
    r"|(?P<telephone>(?<![\w.,])(?:\+33\s?|0)[1-9](?:[ .-]?\d{2}){4}(?![\w.,]))"
    r"|(?P<nir>(?<![\w.,])[12]\d{12}(?:\d{2})?(?![\w.,]))"
)


def controler(fichier) -> dict:
    compte = {"email": 0, "telephone": 0, "nir": 0}
    exemples = []
    lignes = 0
    with open(fichier, encoding="utf-8", newline="") as f:
        lecteur = csv.reader(f, delimiter=";")
        entete = next(lecteur)
        for ligne in lecteur:
            lignes += 1
            trouve = MOTIF.search(";".join(ligne))
            if trouve:
                compte[trouve.lastgroup] += 1
                if len(exemples) < 3:
                    # Valeur masquée : le rapport ne doit pas recopier une donnée personnelle
                    exemples.append(f"{trouve.lastgroup}:{trouve.group()[:4]}…")

    suspectes = [c for c in entete
                 if c.lower() not in COLONNES_AUTORISEES
                 and any(mot in c.lower() for mot in NOMS_INTERDITS)]

    return {"fichier": str(fichier.relative_to(DOSSIER_SORTIE)), "lignes": lignes,
            "colonnes": len(entete), "liste_colonnes": "|".join(entete),
            "colonnes_suspectes": "|".join(suspectes), **compte,
            "exemples": " ; ".join(exemples)}


def main() -> None:
    print("Contrôles avant envoi")
    resultats = []
    for fichier in sorted(DOSSIER_SORTIE.rglob("*.csv")):
        r = controler(fichier)
        resultats.append(r)
        alerte = r["colonnes_suspectes"] or r["email"] or r["telephone"] or r["nir"]
        print(f"  {'ALERTE' if alerte else 'OK':<7} {r['fichier']:<72} {r['lignes']:>12,} lignes")
        if alerte:
            print(f"          colonnes : {r['colonnes_suspectes'] or '-'}  |  {r['exemples']}")

    pd.DataFrame(resultats).to_csv(RAPPORT, sep=";", index=False, encoding="utf-8")
    nb_alertes = sum(1 for r in resultats
                     if r["colonnes_suspectes"] or r["email"] or r["telephone"] or r["nir"])
    print(f"\n{len(resultats)} fichiers contrôlés, {nb_alertes} en alerte -> {RAPPORT}")


if __name__ == "__main__":
    main()