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

-- 3.2 Entidades con megacontratos (PENDIENTE: la escribe el usuario)
-- Objetivo: identificar qué entidades tienen contratos atípicos, en dos niveles:
-- valor_atipico y valor_extremo, agrupando por nit_entidad.

-- 3.3 Municipios por cuartil de valor contratado (PENDIENTE: la escribe el usuario)
-- Objetivo: clasificar los municipios (solo alcaldías) por cuartil de valor contratado
-- y comparar el cuartil más alto con el más bajo.
