-- 3.0 NIT(s) de la Gobernación
SELECT nit_entidad, entidad, COUNT(*) AS contratos
FROM contratos
WHERE entidad LIKE 'DEPARTAMENTO DE ANTIOQUIA%'
GROUP BY nit_entidad, entidad;

-- 3.1 Los 10 contratos más grandes de la Gobernación
SELECT id_contrato,
       ROUND(valor / 1e6, 1) AS valor_millones,
       proveedor,
       tipo_contrato,
       modalidad,
       SUBSTR(objeto_del_contrato, 1, 120) AS objeto
FROM contratos
WHERE nit_entidad = '890900286'
ORDER BY valor DESC
LIMIT 10;

-- 3.1b Porcentaje del valor total de la Gobernación que concentran esos 10 contratos
SELECT ROUND(SUM(top.valor) / 1e6, 1) AS valor_top10_millones,
       ROUND(tot.total / 1e6, 1) AS valor_total_millones,
       ROUND(100.0 * SUM(top.valor) / tot.total, 2) AS pct_top10
FROM (SELECT valor
      FROM contratos
      WHERE nit_entidad = '890900286'
      ORDER BY valor DESC
      LIMIT 10) AS top,
     (SELECT SUM(valor) AS total
      FROM contratos
      WHERE nit_entidad = '890900286') AS tot;

-- 3.2 Entidades con megacontratos (nombre más frecuente por NIT)
WITH nombres AS (
    SELECT nit_entidad, entidad,
           ROW_NUMBER() OVER (PARTITION BY nit_entidad ORDER BY COUNT(*) DESC) AS puesto
    FROM contratos
    GROUP BY nit_entidad, entidad
)
SELECT c.nit_entidad,
       n.entidad,
       SUM(c.valor_atipico) AS n_atipicos,
       SUM(c.valor_extremo) AS n_extremos,
       ROUND(SUM(CASE WHEN c.valor_atipico = 1 THEN c.valor ELSE 0 END) / 1e6) AS valor_atipicos_millones,
       ROUND(100.0 * SUM(CASE WHEN c.valor_atipico = 1 THEN c.valor ELSE 0 END) / SUM(c.valor), 1) AS pct_del_total_entidad
FROM contratos c
JOIN nombres n ON n.nit_entidad = c.nit_entidad AND n.puesto = 1
GROUP BY c.nit_entidad, n.entidad
HAVING SUM(c.valor_atipico) > 0
ORDER BY valor_atipicos_millones DESC
LIMIT 15;
-- 3.3 Resumen por cuartil de valor contratado (solo alcaldias)
-- Alcaldia = entidad cuyo nombre empieza por MUNICIPIO o ALCALD.
-- Cuartil 1 = los que menos contratan, cuartil 4 = los que mas contratan.
WITH municipios AS (
    SELECT nit_entidad,
           COUNT(*) AS contratos,
           SUM(valor) AS total
    FROM contratos
    WHERE entidad LIKE 'MUNICIPIO%' OR entidad LIKE 'ALCALD%'
    GROUP BY nit_entidad
),
cuartiles AS (
    SELECT *,
           NTILE(4) OVER (ORDER BY total) AS cuartil
    FROM municipios
)
SELECT cuartil,
       COUNT(*) AS municipios,
       SUM(contratos) AS contratos,
       ROUND(AVG(total) / 1e6, 1) AS promedio_millones,
       ROUND(100.0 * SUM(total) / SUM(SUM(total)) OVER (), 1) AS pct_del_valor
FROM cuartiles
GROUP BY cuartil
ORDER BY cuartil;

-- 3.3b Que municipios hay en cada cuartil (de mayor a menor valor contratado)
WITH municipios AS (
    SELECT nit_entidad,
           MAX(entidad) AS entidad,
           COUNT(*) AS contratos,
           SUM(valor) AS total
    FROM contratos
    WHERE entidad LIKE 'MUNICIPIO%' OR entidad LIKE 'ALCALD%'
    GROUP BY nit_entidad
),
cuartiles AS (
    SELECT *,
           NTILE(4) OVER (ORDER BY total) AS cuartil
    FROM municipios
)
SELECT cuartil,
       entidad,
       contratos,
       ROUND(total / 1e6, 1) AS valor_millones
FROM cuartiles
ORDER BY total DESC;