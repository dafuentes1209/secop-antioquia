"""Descarga contratos SECOP II de Antioquia desde datos.gov.co (API Socrata)."""
from pathlib import Path

import pandas as pd
import requests

URL = "https://www.datos.gov.co/resource/jbjy-vk9h.json"
SALIDA = Path("data/raw/secop_antioquia.csv")
LOTE = 50_000
MAX_FILAS = 50_000  # sube este valor si quieres más datos


def descargar() -> pd.DataFrame:
    filas, offset = [], 0
    while offset < MAX_FILAS:
        params = {
            "departamento": "Antioquia",
            "$limit": min(LOTE, MAX_FILAS - offset),
            "$offset": offset,
            "$order": ":id",
        }
        r = requests.get(URL, params=params, timeout=120)
        r.raise_for_status()
        lote = r.json()
        if not lote:
            break
        filas.extend(lote)
        offset += len(lote)
        print(f"Descargadas {offset} filas")
    return pd.DataFrame(filas)


if __name__ == "__main__":
    df = descargar()
    SALIDA.parent.mkdir(parents=True, exist_ok=True)
    df.to_csv(SALIDA, index=False)
    print(f"Guardado: {SALIDA} ({len(df)} filas, {len(df.columns)} columnas)")
    print("Columnas:", list(df.columns))
