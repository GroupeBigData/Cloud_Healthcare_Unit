
from datetime import datetime

DOSSIER = "/Volumes/chu/bronze/landing/satisfaction/"
ID_LOT = datetime.now().strftime("%Y%m%d_%H%M%S")   # un seul lot pour toute l'exécution

dossiers = sorted(f.name.rstrip("/") for f in dbutils.fs.ls(DOSSIER) if f.isDir())
print(f"{len(dossiers)} dossiers trouvés - lot {ID_LOT}\n")

for nom in dossiers:
    table = f"chu.bronze.{nom}"
    spark.sql(f"""
        CREATE TABLE IF NOT EXISTS {table}
        COMMENT 'Bronze - satisfaction et indicateurs qualité HAS, fichier {nom}, fidèle à la source'
    """)
    resultat = spark.sql(f"""
        COPY INTO {table}
        FROM (
          SELECT *,
                 _metadata.file_path AS _fichier_source,
                 current_timestamp() AS _date_chargement,
                 '{ID_LOT}'          AS _id_lot
          FROM '{DOSSIER}{nom}/'
        )
        FILEFORMAT = CSV
        FORMAT_OPTIONS ('header' = 'true', 'sep' = ';', 'encoding' = 'UTF-8',
                        'inferSchema' = 'false', 'mergeSchema' = 'true')
        COPY_OPTIONS ('mergeSchema' = 'true')
    """).first()
    total = spark.table(table).count()
    print(f"{nom:<55} insérées : {resultat['num_inserted_rows']:>6,}   total : {total:>6,}")