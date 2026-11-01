import pandas as pd

f = "landing_local/etablissements/etablissement_sante/etablissement_sante.csv"
df = pd.read_csv(f, sep=";", dtype=str, keep_default_na=False)
prefixe = df["identifiant_organisation"].str[0]

print("Lignes :", len(df))
print("finess_site rempli :", (df["finess_site"] != "").sum())
print("finess_etablissement_juridique rempli :", (df["finess_etablissement_juridique"] != "").sum())

print("\nPréfixes de identifiant_organisation :")
print(prefixe.value_counts())

print("\nLongueur après le préfixe, par préfixe :")
longueur = df["identifiant_organisation"].str.len() - 1
print(pd.crosstab(prefixe, longueur))

avec_site = df[df["finess_site"] != ""]
egal = (avec_site["finess_site"] == avec_site["identifiant_organisation"].str[1:]).sum()
print(f"\nfiness_site = identifiant sans sa lettre : {egal} / {len(avec_site)}")
colonnes_vues = ["identifiant_organisation", "finess_site",
                 "finess_etablissement_juridique", "raison_sociale_site"]

print("\nExemples F + 17 caractères :")
f17 = df[(prefixe == "F") & (longueur == 17)]
print(f17[colonnes_vues].head(5).to_string(index=False))

print("\nExemples où finess_site est rempli :")
print(avec_site[colonnes_vues].head(5).to_string(index=False))

f9 = df[(prefixe == "F") & (longueur == 9)]
egal_jur = (f9["identifiant_organisation"].str[1:] == f9["finess_etablissement_juridique"]).sum()
print(f"\nF + 9 : identifiant sans lettre = FINESS juridique : {egal_jur} / {len(f9)}")