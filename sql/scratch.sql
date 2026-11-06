-- Filas con el carácter de reemplazo en texto
SELECT COUNT(*) AS filas_con_caracter_roto
FROM contratos
WHERE modalidad LIKE '�' || char(65533) || '�'
   OR objeto_del_contrato LIKE '�' || char(65533) || '�';