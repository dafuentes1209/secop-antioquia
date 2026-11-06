-- Q1. Top 10 entidades por valor contratado (millones de COP)
SELECT entidad,
       COUNT(*) AS contratos,
       ROUND(SUM(valor) / 1e6, 1) AS valor_millones
FROM contratos
GROUP BY entidad
ORDER BY SUM(valor) DESC
LIMIT 10;

-- Q2. Entidades con mayor porcentaje de contratacion directa (minimo 50 contratos)
SELECT entidad,
       COUNT(*) AS contratos,
       ROUND(100.0 * SUM(CASE WHEN LOWER(modalidad) LIKE '%directa%' THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_directa
FROM contratos
GROUP BY entidad
HAVING COUNT(*) >= 50
ORDER BY pct_directa DESC
LIMIT 15;

-- Q3. Proveedor principal de cada entidad y su participacion en el valor
WITH por_proveedor AS (
    SELECT entidad, proveedor, SUM(valor) AS total
    FROM contratos
    GROUP BY entidad, proveedor
),
rankeado AS (
    SELECT entidad, proveedor, total,
           RANK() OVER (PARTITION BY entidad ORDER BY total DESC) AS puesto,
           100.0 * total / SUM(total) OVER (PARTITION BY entidad) AS pct_entidad
    FROM por_proveedor
)
SELECT entidad, proveedor,
       ROUND(total / 1e6, 1) AS valor_millones,
       ROUND(pct_entidad, 1) AS pct_de_la_entidad
FROM rankeado
WHERE puesto = 1
ORDER BY total DESC
LIMIT 10;

-- Q4. Valor mensual y acumulado
WITH mensual AS (
    SELECT mes_firma, COUNT(*) AS contratos, SUM(valor) AS total
    FROM contratos
    GROUP BY mes_firma
)
SELECT mes_firma, contratos,
       ROUND(total / 1e6, 1) AS valor_millones,
       ROUND(SUM(total) OVER (ORDER BY mes_firma) / 1e6, 1) AS acumulado_millones
FROM mensual
ORDER BY mes_firma;

-- Q5. Contratos que superan 3 veces el promedio de su entidad (entidades con 30+ contratos)
WITH promedio AS (
    SELECT entidad, AVG(valor) AS prom
    FROM contratos
    GROUP BY entidad
    HAVING COUNT(*) >= 30
)
SELECT c.id_contrato, c.entidad, c.proveedor,
       ROUND(c.valor / 1e6, 1) AS valor_millones,
       ROUND(c.valor / p.prom, 1) AS veces_el_promedio
FROM contratos c
JOIN promedio p ON c.entidad = p.entidad
WHERE c.valor > 3 * p.prom
ORDER BY veces_el_promedio DESC
LIMIT 15;
