-- El objetivo no es solo encontrar la query que responda la metrica sino entender que datos necesitamos, que es lo que significa y como armar el KPI General

-- Ventas brutas, netas y margen
--Brutas: suma de ventas
--Netas: menos descuentos, menos creditos, menos impuestos
--Margen: ventas netas - costo

-- Aclaración: tome la cotizacion de la columna cotizacion_usd_eur como cuantos dolares equivalen a un euro, al contrario de como sucede con las otras columnas que es cuantos pesos o 
-- uruguayos equivalen a un dolar
SELECT * FROM stg.order_line_sale
SELECT * FROM stg.cost
SELECT * FROM stg.monthly_average_fx_rate

SELECT 
	TO_CHAR(ols.fecha, 'YYYY-MM'),
	SUM
		(CASE
		 	WHEN moneda = 'ARS' THEN venta / cotizacion_usd_peso
    		WHEN moneda = 'EUR' THEN venta * cotizacion_usd_eur
    		ELSE OLS.venta / cotizacion_usd_uru END) AS venta_bruta_usd,
	SUM((CASE WHEN moneda = 'ARS' THEN venta / cotizacion_usd_peso
    	WHEN moneda = 'EUR' THEN venta * cotizacion_usd_eur
    	ELSE OLS.venta / cotizacion_usd_uru END)) 
	+ 
	(SUM(CASE WHEN moneda = 'ARS' THEN descuento / cotizacion_usd_peso
    	WHEN moneda = 'EUR' THEN descuento * cotizacion_usd_eur
    	ELSE descuento / r.cotizacion_usd_uru END)
	 	+ 
	 	SUM(CASE WHEN moneda = 'ARS' THEN creditos / cotizacion_usd_peso
    	WHEN moneda = 'EUR' THEN creditos * cotizacion_usd_eur
    	ELSE creditos / r.cotizacion_usd_uru END))
	- 
	(SUM(CASE WHEN moneda = 'ARS' THEN impuestos / cotizacion_usd_peso
    	WHEN moneda = 'EUR' THEN impuestos * cotizacion_usd_eur
    	ELSE impuestos / cotizacion_usd_uru END))
	AS venta_neta_usd,
	SUM(costo_promedio_usd) costo,
	SUM(CASE WHEN moneda = 'ARS' THEN venta / cotizacion_usd_peso
    	WHEN moneda = 'EUR' THEN venta * cotizacion_usd_eur
    	ELSE venta / cotizacion_usd_uru END)
	+ 
	SUM(CASE WHEN moneda = 'ARS' THEN descuento / cotizacion_usd_peso
    	WHEN moneda = 'EUR' THEN descuento * cotizacion_usd_eur
    	ELSE descuento / r.cotizacion_usd_uru END)
	 + 
	 SUM(CASE WHEN moneda = 'ARS' THEN creditos / cotizacion_usd_peso
    	WHEN moneda = 'EUR' THEN creditos * cotizacion_usd_eur
    	ELSE creditos / r.cotizacion_usd_uru END)
	- 
	SUM(CASE WHEN moneda = 'ARS' THEN impuestos / cotizacion_usd_peso
    	WHEN moneda = 'EUR' THEN impuestos * cotizacion_usd_eur
    	ELSE impuestos / cotizacion_usd_uru END)
	- SUM(costo_promedio_usd) AS margen_usd
FROM stg.order_line_sale ols
LEFT JOIN stg.monthly_average_fx_rate r
ON TO_CHAR(ols.fecha, 'YYYY-MM') = TO_CHAR(r.mes, 'YYYY-MM')
LEFT JOIN stg.cost c
ON c.codigo_producto = ols.producto
GROUP BY TO_CHAR(ols.fecha, 'YYYY-MM')

--CON TABLAS TEMPORALES
SELECT * FROM stg.order_line_sale
SELECT * FROM stg.cost
SELECT * FROM stg.monthly_average_fx_rate

WITH sales_usd AS (
SELECT orden, producto, venta, cantidad, moneda, fecha,
CASE WHEN moneda = 'ARS' THEN venta / cotizacion_usd_peso
    WHEN moneda = 'EUR' THEN venta * cotizacion_usd_eur
    ELSE OLS.venta / cotizacion_usd_uru END AS venta_usd,
CASE WHEN moneda = 'ARS' THEN descuento / r.cotizacion_usd_peso
    WHEN moneda = 'EUR' THEN descuento * r.cotizacion_usd_eur
    ELSE descuento / r.cotizacion_usd_uru END AS descuento_usd,
CASE WHEN moneda = 'ARS' THEN impuestos / r.cotizacion_usd_peso
    WHEN moneda = 'EUR' THEN impuestos * r.cotizacion_usd_eur
    ELSE impuestos / r.cotizacion_usd_uru END AS impuestos_usd,
CASE WHEN moneda = 'ARS' THEN creditos / r.cotizacion_usd_peso
    WHEN moneda = 'EUR' THEN creditos * r.cotizacion_usd_eur
    ELSE creditos / r.cotizacion_usd_uru END AS creditos_usd,
	costo_promedio_usd
FROM stg.order_line_sale ols
LEFT JOIN stg.monthly_average_fx_rate r
ON TO_CHAR(ols.fecha, 'YYYY-MM') = TO_CHAR(r.mes, 'YYYY-MM')
LEFT JOIN stg.cost c
ON c.codigo_producto = ols.producto
)
SELECT 
	TO_CHAR(fecha, 'YYYY-MM'),
	SUM(venta_usd) venta_bruta_usd, 
	SUM(venta_usd) - SUM(impuestos_usd) + SUM(descuento_usd) + SUM(creditos_usd) AS venta_neta_usd,
	SUM(costo_promedio_usd) costo,
	SUM(venta_usd) - SUM(impuestos_usd) + SUM(descuento_usd) + SUM(creditos_usd) - SUM(costo_promedio_usd) AS margen
FROM sales_usd 
GROUP BY TO_CHAR(fecha, 'YYYY-MM')

-- Margen bruto y neta por categoria de producto
--bruto
--ventas a dolares - costo x categoria
--neto
-- ventas a dolares 
-- impuestos a dolares
-- descuentos a dolares
-- creditos a dolares

SELECT * FROM stg.order_line_sale
SELECT * FROM stg.product_master

SELECT categoria,
	SUM(
		CASE WHEN moneda = 'ARS' THEN venta / cotizacion_usd_peso
    	WHEN moneda = 'EUR' THEN venta * cotizacion_usd_eur
    	ELSE venta / cotizacion_usd_uru END) AS venta_usd,
	SUM(costo_promedio_usd) cost_category,
	SUM(
		CASE WHEN moneda = 'ARS' THEN venta / cotizacion_usd_peso
    	WHEN moneda = 'EUR' THEN venta * cotizacion_usd_eur
    	ELSE venta / cotizacion_usd_uru END) - SUM(costo_promedio_usd) AS margen_categoria
FROM stg.order_line_sale s
LEFT JOIN stg.product_master pm
ON s.producto = pm.codigo_producto
LEFT JOIN stg.cost c
ON c.codigo_producto = s.producto
LEFT JOIN stg.monthly_average_fx_rate r
ON TO_CHAR(s.fecha, 'YYYY-MM') = TO_CHAR(r.mes, 'YYYY-MM')
GROUP BY 1

-- ROI por categoria de producto. ROI = Valor promedio de inventario (prom de inventario * costo) / ventas netas
SELECT * FROM stg.order_line_sale
SELECT * FROM stg.cost
SELECT * FROM stg.inventory

-- nivel de agrupacion: categoria
SELECT 
  pm.categoria,
  TO_CHAR(s.fecha, 'YYYY-MM') mes,
  SUM(((inv.inicial+inv.final)/ 2) * COALESCE(c.costo_promedio_usd, 0)) / SUM(CASE
		 	WHEN moneda = 'ARS' THEN venta / cotizacion_usd_peso
    		WHEN moneda = 'EUR' THEN venta * cotizacion_usd_eur
    		ELSE venta / cotizacion_usd_uru END)
FROM stg.order_line_sale s
LEFT JOIN stg.monthly_average_fx_rate fx
ON TO_CHAR(s.fecha, 'YYYY-MM') = TO_CHAR(fx.mes, 'YYYY-MM')
LEFT JOIN stg.cost c
ON s.producto = c.codigo_producto
LEFT JOIN stg.inventory inv
ON s.producto = inv.sku
LEFT JOIN stg.product_master pm
ON s.producto = pm.codigo_producto
GROUP BY 1, 2
ORDER BY 1, 2
;

-- AOV (Average order value), valor promedio de la orden.

SELECT SUM(
		CASE WHEN moneda = 'ARS' THEN venta / cotizacion_usd_peso
    		WHEN moneda = 'EUR' THEN venta * cotizacion_usd_eur
    		ELSE venta / cotizacion_usd_uru END) / COUNT(orden) AS AOV
FROM stg.order_line_sale s
LEFT JOIN stg.monthly_average_fx_rate r
ON TO_CHAR(s.fecha, 'YYYY-MM') = TO_CHAR(r.mes, 'YYYY-MM')

-- Contabilidad
-- Impuestos pagados
SELECT SUM(
		CASE 
			WHEN moneda = 'ARS' THEN COALESCE(impuestos, 0) / cotizacion_usd_peso
    		WHEN moneda = 'EUR' THEN COALESCE(impuestos, 0) * cotizacion_usd_eur
    		ELSE COALESCE(impuestos, 0) / cotizacion_usd_uru END)
FROM stg.order_line_sale s
LEFT JOIN stg.monthly_average_fx_rate r
ON TO_CHAR(s.fecha, 'YYYY-MM') = TO_CHAR(r.mes, 'YYYY-MM')

-- Tasa de impuesto. Impuestos / Ventas netas
SELECT 
		TO_CHAR(s.fecha, 'YYYY-MM') mes,
		SUM(
			CASE 
			WHEN moneda = 'ARS' THEN COALESCE(impuestos, 0) / cotizacion_usd_peso
			WHEN moneda = 'EUR' THEN COALESCE(impuestos, 0) * cotizacion_usd_eur
			ELSE COALESCE(impuestos, 0) / cotizacion_usd_uru END)
		/ SUM
		(CASE
		 WHEN moneda = 'ARS' THEN venta / cotizacion_usd_peso
    	 WHEN moneda = 'EUR' THEN venta * cotizacion_usd_eur
    	 ELSE venta / cotizacion_usd_uru END) *100 AS tasa_de_impuesto
FROM stg.order_line_sale s
LEFT JOIN stg.monthly_average_fx_rate r
ON TO_CHAR(s.fecha, 'YYYY-MM') = TO_CHAR(r.mes, 'YYYY-MM')
GROUP BY 1

-- Cantidad de creditos otorgados
SELECT TO_CHAR(s.fecha, 'YYYY-MM') mes, SUM(CASE WHEN moneda = 'ARS' THEN creditos / cotizacion_usd_peso
    	WHEN moneda = 'EUR' THEN creditos * cotizacion_usd_eur
    	ELSE creditos / r.cotizacion_usd_uru END)
FROM stg.order_line_sale s
LEFT JOIN stg.monthly_average_fx_rate r
ON TO_CHAR(s.fecha, 'YYYY-MM') = TO_CHAR(r.mes, 'YYYY-MM')
GROUP BY 1

-- Valor pagado final por order de linea. Valor pagado: Venta - descuento + impuesto - credito
SELECT * FROM stg.order_line_sale

SELECT orden,  moneda, SUM(venta + COALESCE(descuento, 0) + COALESCE(creditos, 0) + COALESCE(impuestos, 0)) valor_pagado
FROM stg.order_line_sale s
GROUP BY 1, 2

-- Supply Chain
-- Costo de inventario promedio por tienda
SELECT * FROM stg.cost;
SELECT * FROM stg.inventory

SELECT 
	i.tienda,
	TO_CHAR(i.fecha, 'YYYY-MM') mes,
	SUM((inicial+final) / 2 * costo_promedio_usd)
FROM stg.inventory i
LEFT JOIN stg.cost c
ON i.sku = c.codigo_producto
GROUP BY 1, 2
ORDER BY 1, 2

-- Costo del stock de productos que no se vendieron por tienda
SELECT 
	i.tienda,
	TO_CHAR(i.fecha, 'YYYY-MM') mes,
	SUM( final * costo_promedio_usd) costo
FROM stg.inventory i
LEFT JOIN stg.cost c
ON i.sku = c.codigo_producto
GROUP BY 1, 2
ORDER BY 1, 2

-- Cantidad y costo de devoluciones
CREATE TABLE stg.return_movements(
	orden_venta    VARCHAR(255)
	,envio         VARCHAR(255)
	,item          VARCHAR(255)
	,cantidad      INT
	,id_movimiento INT
	,desde         VARCHAR(255)
	,hasta         VARCHAR(255)
	,recibido_por  VARCHAR(255)
	,fecha         DATE);

SELECT 
	TO_CHAR(fecha, 'YYYY-MM') mes,
	item,
	SUM(cantidad) cantidad,
	SUM(cantidad * costo_promedio_usd)
FROM stg.return_movements m
LEFT JOIN stg.cost c
on c.codigo_producto = m.item
GROUP BY 1, 2
	
-- Tiendas
-- Ratio de conversion. Cantidad de ordenes generadas / Cantidad de gente que entra
SELECT * FROM stg.order_line_sale
SELECT * FROM stg.market_count
SELECT * FROM stg.super_store_count

WITH all_stores_count AS (
SELECT tienda, DATE(fecha::TEXT) as fecha, conteo FROM stg.market_count
UNION ALL
SELECT tienda, DATE(fecha::TEXT) as fecha, conteo FROM stg.super_store_count
)

SELECT 
	s.tienda,
	TO_CHAR(s.fecha, 'YYYY-MM') mes,
	COUNT(orden) cant_ordenes,
	SUM(COALESCE(conteo, 0)) personas,
	CAST(COUNT(orden)/(SUM(COALESCE(conteo, 0))+0.0001)*100 AS decimal(6,2)) ratio_porc
FROM stg.order_line_sale s
LEFT JOIN all_stores_count co
ON s.tienda = co.tienda
GROUP BY 1, 2

