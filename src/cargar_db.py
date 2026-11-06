"""Carga el CSV crudo a SQLite (tabla contratos_raw, todo como texto)."""
import sqlite3
from pathlib import Path

import pandas as pd

CSV = Path("data/raw/secop_antioquia.csv")
DB = Path("data/processed/secop.db")

if __name__ == "__main__":
    df = pd.read_csv(CSV, dtype=str)
    DB.parent.mkdir(parents=True, exist_ok=True)
    with sqlite3.connect(DB) as con:
        df.to_sql("contratos_raw", con, if_exists="replace", index=False)
    print(f"Tabla contratos_raw creada en {DB} ({len(df)} filas)")
