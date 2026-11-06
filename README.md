# ¿Cómo contrata el Estado en Antioquia?

Análisis en SQL de contratos públicos de Antioquia (SECOP II, datos abiertos de Colombia).

## Preguntas
1. Top 10 entidades por valor contratado
2. % de contratación directa por entidad
3. Principales contratistas por entidad
4. Valor mensual y acumulado
5. Contratos atípicos frente al promedio de su entidad
6. Calidad de datos: nulos, duplicados, valores raros

## Cómo reproducirlo
```bash
python -m venv .venv
source .venv/Scripts/activate   # Linux/Mac: source .venv/bin/activate
pip install -r requirements.txt
python src/descargar_datos.py
python src/cargar_db.py
python src/ejecutar_sql.py sql/02_analisis.sql
```

## Fuente
SECOP II - Contratos Electrónicos, Colombia Compra Eficiente (datos.gov.co, dataset jbjy-vk9h).

## Hallazgos
(pendiente)
