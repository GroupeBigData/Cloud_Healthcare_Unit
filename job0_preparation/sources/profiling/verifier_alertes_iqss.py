import re

import pandas as pd

NIR = re.compile(r"(?<!\w)[12]\d{12}(?:\d{2})?(?!\w)")

for annee in (2019, 2020):
    nom = f"resultats_iqss_open_data_{annee}"
    df = pd.read_csv(f"landing_local/satisfaction/{nom}/{nom}.csv",
                     sep=";", dtype=str, keep_default_na=False)
    print(f"\n{annee}")
    for col in df.columns:
        touches = df.loc[df[col].str.contains(NIR), col]
        if len(touches):
            print(f"  {col:<25} {len(touches):>5} valeurs, ex. : {', '.join(touches.head(2))}")