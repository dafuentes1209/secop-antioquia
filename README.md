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
En la muestra analizada (las primeras 50.000 filas por id), 10 de los 901 contratos de la Gobernación de Antioquia (cerca del 1 %) concentran el 57 % del valor contratado (1,29 de 2,26 billones de pesos). El mayor, de unos 712.569 millones de pesos, corresponde a la construcción de las vías de acceso al proyecto Túnel Guillermo Gaviria Echeverri (Túnel del Toyo). Los demás se reparten entre obras viales y convenios o contratos de administración de recursos, en los que la Gobernación transfiere dinero a otras entidades para que lo ejecuten, como el convenio con el IDEA o la modernización del alumbrado público.
