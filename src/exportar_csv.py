"""Exporta la tabla contratos a CSV (UTF-8 con BOM, para que Power BI lea bien las tildes).
Agrega es_alcaldia: 1 si la entidad empieza por MUNICIPIO o ALCALD (mismo criterio de la consulta 3.3).
Uso: python src/exportar_csv.py
"""
import sqlite3
from pathlib import Path

import pandas as pd

DB = Path("data/processed/secop.db")
CSV = Path("data/processed/contratos.csv")

if __name__ == "__main__":
    with sqlite3.connect(DB) as con:
        df = pd.read_sql_query("SELECT * FROM contratos", con)
    entidad = df["entidad"].fillna("").str.upper()
    df["es_alcaldia"] = entidad.str.startswith(("MUNICIPIO", "ALCALD")).astype(int)
    df.to_csv(CSV, index=False, encoding="utf-8-sig")
    print(f"Exportadas {len(df)} filas a {CSV}")
