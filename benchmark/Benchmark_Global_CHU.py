# Databricks notebook source
# BENCHMARK GLOBAL CHU — 6 requêtes

requetes = {

    "B1_Consultations": """
        SELECT
            t.annee,
            SUM(c.nb_consultations) AS total_consultations
        FROM chu.gold.fait_consultation c
        JOIN chu.gold.dim_temps t
            ON c.date_sk = t.date_sk
        GROUP BY t.annee
        ORDER BY t.annee
    """,

    "B2_Hospitalisations": """
        SELECT
            d.code_diag,
            d.libelle,
            SUM(h.nb_hospitalisations) AS total_hospitalisations,
            AVG(h.duree_sejour_jours) AS duree_moyenne
        FROM chu.gold.fait_hospitalisation h
        JOIN chu.gold.dim_diagnostic d
            ON h.diagnostic_sk = d.diagnostic_sk
        GROUP BY d.code_diag, d.libelle
        ORDER BY total_hospitalisations DESC
        LIMIT 20
    """,

    "B3_Professionnels": """
        SELECT
            COALESCE(specialite, 'Non renseignée') AS specialite,
            COUNT(DISTINCT professionnel_sk) AS total_professionnels
        FROM chu.gold.dim_professionnel
        GROUP BY COALESCE(specialite, 'Non renseignée')
        ORDER BY total_professionnels DESC
    """,

    "B4_Satisfaction": """
        SELECT
            r.libelle_region,
            ROUND(
                SUM(s.score_x_reponses) /
                NULLIF(SUM(s.nb_reponses), 0),
                2
            ) AS score_moyen_pondere,
            SUM(s.nb_reponses) AS total_reponses
        FROM chu.gold.fait_satisfaction s
        JOIN chu.gold.dim_region r
            ON s.region_sk = r.region_sk
        WHERE s.score_x_reponses IS NOT NULL
          AND s.nb_reponses > 0
        GROUP BY r.libelle_region
        ORDER BY score_moyen_pondere DESC
    """,

    "B5_Deces_Region": """
        SELECT
            r.libelle_region,
            SUM(d.nb_deces) AS total_deces
        FROM chu.gold.fait_deces d
        JOIN chu.gold.dim_region r
            ON d.region_sk = r.region_sk
        GROUP BY r.libelle_region
        ORDER BY total_deces DESC
    """,

    "B6_Deces_Annee_Region": """
        SELECT
            t.annee,
            r.libelle_region,
            SUM(d.nb_deces) AS total_deces
        FROM chu.gold.fait_deces d
        JOIN chu.gold.dim_temps t
            ON d.date_sk = t.date_sk
        JOIN chu.gold.dim_region r
            ON d.region_sk = r.region_sk
        WHERE t.annee BETWEEN 2015 AND 2019
        GROUP BY t.annee, r.libelle_region
        ORDER BY t.annee, r.libelle_region
    """
}

print("Nombre de requêtes :", len(requetes))

# COMMAND ----------

for nom, sql in requetes.items():
    print(f"\n--- {nom} ---")

    try:
        resultat = spark.sql(sql).collect()
        print("OK — Nombre de lignes retournées :", len(resultat))
        print("Exemple :", resultat[:2])
    except Exception as e:
        print("ERREUR :", str(e)[:500])

# COMMAND ----------

import time
import statistics
import pandas as pd

resultats_avant = []

for nom, sql in requetes.items():
    temps = []

    print(f"\nBenchmark : {nom}")

    for i in range(5):
        debut = time.perf_counter()

        lignes = spark.sql(sql).collect()

        duree = time.perf_counter() - debut
        temps.append(duree)

        print(f"  Exécution {i+1} : {duree:.3f} s")

    resultats_avant.append({
        "benchmark": nom,
        "execution_1": temps[0],
        "execution_2": temps[1],
        "execution_3": temps[2],
        "execution_4": temps[3],
        "execution_5": temps[4],
        "moyenne_avant": statistics.mean(temps),
        "mediane_avant": statistics.median(temps),
        "lignes_resultat": len(lignes)
    })

df_avant = pd.DataFrame(resultats_avant)

display(df_avant.round(3))

# COMMAND ----------

# Sauvegarder les mesures avant optimisation
spark.createDataFrame(df_avant).write \
    .mode("overwrite") \
    .format("delta") \
    .saveAsTable("chu.bench.resultats_avant_optimisation")

print("Résultats AVANT optimisation enregistrés.")

# COMMAND ----------

# Inventaire physique des tables Gold utilisées

tables = [
    "fait_consultation",
    "fait_hospitalisation",
    "dim_professionnel",
    "fait_satisfaction",
    "fait_deces",
    "dim_temps",
    "dim_diagnostic",
    "dim_region"
]

resultats = []

for table in tables:
    detail = spark.sql(
        f"DESCRIBE DETAIL chu.gold.{table}"
    ).first()

    resultats.append({
        "table": table,
        "format": detail["format"],
        "nb_fichiers": detail["numFiles"],
        "taille_Mio": round(
            detail["sizeInBytes"] / (1024**2), 2
        ),
        "partitionnement": str(detail["partitionColumns"]),
        "clustering": str(detail["clusteringColumns"])
    })

display(spark.createDataFrame(resultats))

# COMMAND ----------

# Créer une table de test indépendante
# Ne pas modifier les tables Gold du groupe

spark.sql("""
CREATE TABLE IF NOT EXISTS chu.bench.fait_consultation_test
USING DELTA
AS
SELECT *
FROM chu.gold.fait_consultation
""")

# Vérifier les propriétés physiques
display(
    spark.sql("""
        DESCRIBE DETAIL chu.bench.fait_consultation_test
    """).select(
        "numFiles",
        "sizeInBytes",
        "partitionColumns",
        "clusteringColumns"
    )
)

# COMMAND ----------

import time
import statistics

temps_avant_consultation = []

requete_consultation = """
SELECT
    t.annee,
    SUM(c.nb_consultations) AS total_consultations
FROM chu.bench.fait_consultation_test c
JOIN chu.gold.dim_temps t
    ON c.date_sk = t.date_sk
GROUP BY t.annee
ORDER BY t.annee
"""

for i in range(5):
    debut = time.perf_counter()

    resultat = spark.sql(requete_consultation).collect()

    duree = time.perf_counter() - debut
    temps_avant_consultation.append(duree)

    print(f"Exécution {i+1} : {duree:.3f} s")

print("\nMoyenne AVANT :", round(statistics.mean(temps_avant_consultation), 3), "s")
print("Médiane AVANT :", round(statistics.median(temps_avant_consultation), 3), "s")

# COMMAND ----------

# Configurer le clustering sur la date des consultations
spark.sql("""
    ALTER TABLE chu.bench.fait_consultation_test
    CLUSTER BY (date_sk)
""")

# Demander l'optimisation physique
resultat_optimisation = spark.sql("""
    OPTIMIZE chu.bench.fait_consultation_test
""")

display(resultat_optimisation)

# COMMAND ----------

detail = spark.sql("""
    DESCRIBE DETAIL chu.bench.fait_consultation_test
""")

display(
    detail.select(
        "numFiles",
        "sizeInBytes",
        "partitionColumns",
        "clusteringColumns"
    )
)

# COMMAND ----------

import time
import statistics

temps_apres_consultation = []

# On réutilise exactement la même requête
# définie avant optimisation.
for i in range(5):
    debut = time.perf_counter()

    spark.sql(requete_consultation).collect()

    duree = time.perf_counter() - debut
    temps_apres_consultation.append(duree)

    print(f"Exécution {i+1} : {duree:.3f} s")

moyenne_avant = statistics.mean(temps_avant_consultation)
moyenne_apres = statistics.mean(temps_apres_consultation)

variation = (
    (moyenne_apres - moyenne_avant)
    / moyenne_avant
) * 100

print("\n--- COMPARAISON B1 ---")
print(f"Avant : {moyenne_avant:.3f} s")
print(f"Après : {moyenne_apres:.3f} s")
print(f"Variation : {variation:+.2f} %")

# COMMAND ----------

import time
import statistics

# Deux nouvelles copies indépendantes
spark.sql("""
CREATE TABLE IF NOT EXISTS chu.bench.b6_temoin
USING DELTA AS
SELECT * FROM chu.gold.fait_deces
""")

spark.sql("""
CREATE TABLE IF NOT EXISTS chu.bench.b6_optimisee
USING DELTA AS
SELECT * FROM chu.gold.fait_deces
""")

def benchmark_b6(table):
    sql = f"""
    SELECT
        t.annee,
        r.libelle_region,
        SUM(d.nb_deces) AS total_deces
    FROM {table} d
    JOIN chu.gold.dim_temps t
        ON d.date_sk = t.date_sk
    JOIN chu.gold.dim_region r
        ON d.region_sk = r.region_sk
    WHERE t.annee BETWEEN 2015 AND 2019
    GROUP BY t.annee, r.libelle_region
    ORDER BY t.annee, r.libelle_region
    """

    temps = []

    for i in range(5):
        debut = time.perf_counter()
        spark.sql(sql).collect()
        temps.append(time.perf_counter() - debut)

    return temps

avant_b6 = benchmark_b6("chu.bench.b6_temoin")

print("B6 AVANT :", [round(x, 3) for x in avant_b6])
print("Moyenne :", round(statistics.mean(avant_b6), 3), "s")

# COMMAND ----------

# Activer le clustering sur la copie optimisée
spark.sql("""
ALTER TABLE chu.bench.b6_optimisee
CLUSTER BY (date_sk, region_sk)
""")

# Demander la réorganisation physique
optimisation = spark.sql("""
OPTIMIZE chu.bench.b6_optimisee
""")

display(optimisation)

# Mesurer les performances après
apres_b6 = benchmark_b6("chu.bench.b6_optimisee")

m_avant = statistics.mean(avant_b6)
m_apres = statistics.mean(apres_b6)

print("\n--- B6 : COMPARAISON ---")
print("Avant :", round(m_avant, 3), "s")
print("Après :", round(m_apres, 3), "s")
print("Variation :", round((m_apres - m_avant) / m_avant * 100, 2), "%")

# COMMAND ----------

import matplotlib.pyplot as plt

# Récupérer les résultats déjà enregistrés
df = spark.table(
    "chu.bench.resultats_avant_optimisation"
).toPandas()

plt.figure(figsize=(10, 5))

plt.bar(df["benchmark"], df["moyenne_avant"])

plt.title("Temps moyens des 6 benchmarks - Avant optimisation")
plt.ylabel("Temps moyen (secondes)")
plt.xlabel("Benchmark")
plt.xticks(rotation=30, ha="right")
plt.ylim(bottom=0)
plt.tight_layout()

plt.show()

# COMMAND ----------

import matplotlib.pyplot as plt
import numpy as np

benchmarks = ["B1 - Consultations", "B6 - Deces"]

avant = [0.962, 1.466]
apres = [0.884, 1.347]

x = np.arange(len(benchmarks))
largeur = 0.35

plt.figure(figsize=(8, 5))

plt.bar(x - largeur / 2, avant, largeur, label="Avant")
plt.bar(x + largeur / 2, apres, largeur, label="Après")

plt.xticks(x, benchmarks)
plt.ylabel("Temps moyen (secondes)")
plt.title("Comparaison avant / apres optimisation")
plt.legend()
plt.ylim(bottom=0)
plt.tight_layout()

plt.show()

# COMMAND ----------

display(spark.sql("""
    SELECT *
    FROM chu.quality.resultats_controles
    LIMIT 30
"""))