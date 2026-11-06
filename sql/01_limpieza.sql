-- Tabla limpia de contratos: sin duplicados de id_contrato (se deja la ultima actualizacion), con tipos declarados.
-- Reglas que descartan filas (en este orden): id nulo, duplicados, fecha nula, valor <= 0, contrato de prueba.
-- Los contratos de valor simbolico, atipico o extremo NO se borran, solo se marcan con banderas.
-- Nota: el ejecutor parte el archivo por punto y coma, por eso no hay punto y coma dentro de comentarios ni textos.
DROP TABLE IF EXISTS contratos;

DROP TABLE IF EXISTS tmp_ranked;

DROP TABLE IF EXISTS tmp_base;

CREATE TABLE contratos (
    id_contrato         TEXT PRIMARY KEY,
    nit_entidad         TEXT,
    entidad             TEXT,
    ciudad              TEXT,
    sector              TEXT,
    rama                TEXT,
    estado_contrato     TEXT,
    tipo_contrato       TEXT,
    modalidad           TEXT,
    fecha_firma         TEXT,     -- formato YYYY-MM-DD
    mes_firma           TEXT,     -- formato YYYY-MM
    proveedor           TEXT,
    valor               REAL,
    objeto_del_contrato TEXT,
    valor_simbolico     INTEGER,  -- 1 si valor < 1000
    percentil_valor     INTEGER,  -- 1 a 100, calculado sobre la tabla ya filtrada
    valor_atipico       INTEGER,  -- 1 si percentil_valor >= 99
    valor_extremo       INTEGER   -- 1 si valor >= 1e11
);

-- Paso intermedio: filas crudas con numero de fila por id_contrato (1 = la ultima_actualizacion mas reciente)
CREATE TEMP TABLE tmp_ranked AS
SELECT *,
       ROW_NUMBER() OVER (
           PARTITION BY id_contrato
           ORDER BY ultima_actualizacion DESC
       ) AS rn
FROM contratos_raw
WHERE id_contrato IS NOT NULL;

-- Paso intermedio: filas que sobreviven a todas las reglas (antes de normalizar nombres y calcular percentiles)
-- Se excluye el contrato de prueba: tiene PRUEBA DIDACTICA en objeto_del_contrato y no es un contrato real
CREATE TEMP TABLE tmp_base AS
SELECT *
FROM tmp_ranked
WHERE rn = 1
  AND fecha_de_firma IS NOT NULL
  AND CAST(valor_del_contrato AS REAL) > 0
  AND COALESCE(objeto_del_contrato, '') NOT LIKE '%PRUEBA DIDACTICA%';

-- Diagnostico ANTES de normalizar 1: cuantos nombres de entidad cambian
SELECT
    COUNT(DISTINCT nombre_entidad) AS nombres_que_cambian,
    COUNT(*) AS filas_afectadas
FROM tmp_base
WHERE nombre_entidad <> RTRIM(TRIM(nombre_entidad), ' /*+?' || CHAR(9, 10, 13));

-- Diagnostico ANTES de normalizar 2: ejemplos de cambios (nombre original -> nombre normalizado)
SELECT
    nombre_entidad AS nombre_original,
    RTRIM(TRIM(nombre_entidad), ' /*+?' || CHAR(9, 10, 13)) AS nombre_normalizado,
    COUNT(*) AS filas
FROM tmp_base
WHERE nombre_entidad <> RTRIM(TRIM(nombre_entidad), ' /*+?' || CHAR(9, 10, 13))
GROUP BY nombre_entidad
ORDER BY filas DESC
LIMIT 15;

-- Diagnostico ANTES de normalizar 3: nombres distintos vs NITs distintos y NITs nulos
SELECT
    COUNT(DISTINCT TRIM(nombre_entidad)) AS nombres_distintos_antes,
    COUNT(DISTINCT RTRIM(TRIM(nombre_entidad), ' /*+?' || CHAR(9, 10, 13))) AS nombres_distintos_despues,
    COUNT(DISTINCT NULLIF(TRIM(nit_entidad), '')) AS nits_distintos,
    SUM(NULLIF(TRIM(nit_entidad), '') IS NULL) AS filas_con_nit_nulo
FROM tmp_base;

-- Llenado de la tabla contratos
-- Se quitan espacios y simbolos sobrantes al final del nombre (//, **, +, ?) sin unir nombres distintos
-- Los guiones y puntos finales se conservan porque son parte de nombres legitimos (SAPIENCIA-, S.A.)
INSERT INTO contratos (
    id_contrato, nit_entidad, entidad, ciudad, sector, rama, estado_contrato,
    tipo_contrato, modalidad, fecha_firma, mes_firma, proveedor, valor,
    objeto_del_contrato, valor_simbolico, percentil_valor, valor_atipico, valor_extremo
)
WITH base AS (
    SELECT
        id_contrato,
        NULLIF(TRIM(nit_entidad), '')                                              AS nit_entidad,
        RTRIM(TRIM(nombre_entidad), ' /*+?' || CHAR(9, 10, 13))                    AS entidad,
        ciudad,
        sector,
        rama,
        estado_contrato,
        tipo_de_contrato                      AS tipo_contrato,
        modalidad_de_contratacion             AS modalidad,
        DATE(SUBSTR(fecha_de_firma, 1, 10))   AS fecha_firma,
        SUBSTR(fecha_de_firma, 1, 7)          AS mes_firma,
        UPPER(TRIM(proveedor_adjudicado))     AS proveedor,
        CAST(valor_del_contrato AS REAL)      AS valor,
        objeto_del_contrato
    FROM tmp_base
),
con_percentil AS (
    SELECT *,
           NTILE(100) OVER (ORDER BY valor) AS percentil_valor
    FROM base
)
SELECT
    id_contrato, nit_entidad, entidad, ciudad, sector, rama, estado_contrato,
    tipo_contrato, modalidad, fecha_firma, mes_firma, proveedor, valor,
    objeto_del_contrato,
    CASE WHEN valor < 1000 THEN 1 ELSE 0 END          AS valor_simbolico,
    percentil_valor,
    CASE WHEN percentil_valor >= 99 THEN 1 ELSE 0 END AS valor_atipico,
    CASE WHEN valor >= 1e11 THEN 1 ELSE 0 END         AS valor_extremo
FROM con_percentil;

-- Control de calidad 1: filas crudas vs limpias
SELECT
    (SELECT COUNT(*) FROM contratos_raw) AS filas_crudas,
    (SELECT COUNT(DISTINCT id_contrato) FROM contratos_raw) AS ids_distintos,
    (SELECT COUNT(*) FROM contratos) AS filas_limpias;

-- Control de calidad 2: nulos por columna clave en la tabla limpia
SELECT
    SUM(entidad IS NULL) AS entidad_nula,
    SUM(nit_entidad IS NULL) AS nit_nulo,
    SUM(proveedor IS NULL) AS proveedor_nulo,
    SUM(modalidad IS NULL) AS modalidad_nula,
    SUM(tipo_contrato IS NULL) AS tipo_nulo,
    SUM(fecha_firma IS NULL) AS fecha_firma_nula
FROM contratos;

-- Control de calidad 3: rango de fechas y de valores
SELECT
    MIN(fecha_firma) AS primera_firma,
    MAX(fecha_firma) AS ultima_firma,
    MIN(valor) AS valor_minimo,
    ROUND(AVG(valor)) AS valor_promedio,
    MAX(valor) AS valor_maximo
FROM contratos;

-- Control de calidad 4: filas que descarta cada regla (en orden) y cuadre contra la tabla final
SELECT
    (SELECT COUNT(*) FROM contratos_raw WHERE id_contrato IS NULL) AS id_nulo,
    (SELECT COUNT(*) FROM tmp_ranked WHERE rn > 1) AS duplicados,
    (SELECT COUNT(*) FROM tmp_ranked WHERE rn = 1 AND fecha_de_firma IS NULL) AS fecha_nula,
    (SELECT COUNT(*) FROM tmp_ranked WHERE rn = 1 AND fecha_de_firma IS NOT NULL
        AND NOT (CAST(valor_del_contrato AS REAL) > 0)) AS valor_menor_o_igual_cero,
    (SELECT COUNT(*) FROM tmp_ranked WHERE rn = 1 AND fecha_de_firma IS NOT NULL
        AND CAST(valor_del_contrato AS REAL) > 0
        AND COALESCE(objeto_del_contrato, '') LIKE '%PRUEBA DIDACTICA%') AS contrato_de_prueba,
    (SELECT COUNT(*) FROM contratos) AS filas_finales,
    (SELECT COUNT(*) FROM contratos_raw) AS filas_crudas;

-- Control de calidad 5: contratos marcados (no se eliminan)
SELECT
    SUM(valor_simbolico) AS valor_simbolico,
    SUM(valor_atipico) AS valor_atipico,
    SUM(valor_extremo) AS valor_extremo
FROM contratos;

-- Control de calidad 6: nombres de entidad distintos vs NITs distintos DESPUES de normalizar
SELECT
    COUNT(DISTINCT entidad) AS nombres_distintos,
    COUNT(DISTINCT nit_entidad) AS nits_distintos,
    SUM(nit_entidad IS NULL) AS filas_con_nit_nulo
FROM contratos;

-- Modalidades presentes (para validar la pregunta 2)
SELECT modalidad, COUNT(*) AS contratos
FROM contratos
GROUP BY modalidad
ORDER BY contratos DESC;

DROP TABLE IF EXISTS tmp_ranked;

DROP TABLE IF EXISTS tmp_base;
