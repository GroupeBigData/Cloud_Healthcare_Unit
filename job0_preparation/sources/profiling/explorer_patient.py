import pandas as pd

f = "landing_local/postgres/patient/patient.csv"
df = pd.read_csv(f, sep=";", dtype=str, keep_default_na=False)

print("Sexe :")
print(df["Sexe"].value_counts())

print("\nPays (10 plus fréquents) :")
print(df["Pays"].value_counts().head(10))

print("\nLongueur du code postal :")
print(df["Code_postal"].str.len().value_counts())

print("\nFormes de date (chaque chiffre remplacé par 9) :")
print(df["Date"].str.replace(r"\d", "9", regex=True).value_counts())

annee = df["Date"].str.split("/").str[-1]
print(f"\nAnnée de naissance : de {annee.min()} à {annee.max()}")

taille = df.groupby(["Sexe", "Date", "Code_postal"]).size()
print(f"\nAvant généralisation : {(taille == 1).sum():,} patients uniques "
      f"sur {len(df):,} (sexe + date de naissance + code postal)")