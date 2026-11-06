"""Ejecuta un archivo .sql contra la base y muestra los resultados.
Uso: python src/ejecutar_sql.py sql/03_analisis.sql
"""
import sqlite3
import sys
from pathlib import Path

import pandas as pd

DB = Path("data/processed/secop.db")


def separar(bloque):
    """Devuelve (titulo, sql) quitando las lineas de comentario '--'."""
    titulo, sql = [], []
    for linea in bloque.splitlines():
        if linea.strip().startswith("--"):
            titulo.append(linea.strip().lstrip("-").strip())
        else:
            sql.append(linea)
    return " | ".join(t for t in titulo if t), "\n".join(sql).strip()


if __name__ == "__main__":
    script = Path(sys.argv[1]).read_text(encoding="utf-8")
    pd.set_option("display.width", 250)
    pd.set_option("display.max_columns", None)
    pd.set_option("display.max_rows", None)
    pd.set_option("display.max_colwidth", None)
    with sqlite3.connect(DB) as con:
        for bloque in script.split(";"):
            titulo, sql = separar(bloque)
            if sql.upper().startswith(("SELECT", "WITH")):
                if titulo:
                    print(f"=== {titulo} ===")
                print(pd.read_sql_query(sql, con).to_string(index=False), "\n")
            elif sql:
                con.execute(sql)
        con.commit()
