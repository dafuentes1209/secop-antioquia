"""Ejecuta un archivo .sql contra la base y muestra los resultados.
Uso: python src/ejecutar_sql.py sql/03_analisis.sql
"""
import sqlite3
import sys
from pathlib import Path

import pandas as pd

DB = Path("data/processed/secop.db")

if __name__ == "__main__":
    script = Path(sys.argv[1]).read_text(encoding="utf-8")
    pd.set_option("display.width", 200)
    pd.set_option("display.max_columns", 20)
    with sqlite3.connect(DB) as con:
        for sentencia in script.split(";"):
            if sentencia.strip().upper().startswith(("SELECT", "WITH")):
                print(pd.read_sql_query(sentencia, con), "\n")
            elif sentencia.strip():
                con.execute(sentencia)
        con.commit()
