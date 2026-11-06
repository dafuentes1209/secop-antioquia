-- 3.0 NIT(s) de la Gobernación
SELECT nit_entidad, entidad, COUNT(*) AS contratos
FROM contratos
WHERE entidad LIKE 'DEPARTAMENTO DE ANTIOQUIA%'
GROUP BY nit_entidad, entidad;

-- 3.1 Los 10 contratos más grandes de la Gobernación
SELECT id_contrato, nit_entidad, entidad, SUBSTR(objeto_del_contrato, 1, 120) AS objeto
FROM contratos
WHERE nit_entidad = '890900286'
ORDER BY valor DESC
LIMIT 10;