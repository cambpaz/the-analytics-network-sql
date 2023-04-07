-- Mostrar nombre y codigo de producto, categoria y color para todos los productos de la marca Philips y Samsung, mostrando la leyenda 
--"Unknown" cuando no hay un color disponible
SELECT * FROM stg.product_master

SELECT nombre, codigo_producto, categoria, COALESCE(color, 'Unknown') 
FROM stg.product_master 
WHERE UPPER(nombre) LIKE UPPER('%PHILIPS%') OR UPPER(nombre) LIKE UPPER('%SAMSUNG%');

-- Calcular las ventas brutas y los impuestos pagados por pais y provincia en la moneda correspondiente.
SELECT * FROM stg.order_line_sale 
SELECT * FROM stg.store_master 

SELECT pais, provincia, SUM(venta) as ventas_brutas, SUM(COALESCE(impuestos, 0)) AS impuestos, moneda FROM stg.order_line_sale AS ols
LEFT JOIN stg.store_master as sm
ON sm.codigo_tienda = ols.tienda
GROUP BY pais, provincia, moneda

-- Calcular las ventas totales por subcategoria de producto para cada moneda ordenados por subcategoria y moneda.
SELECT * FROM stg.order_line_sale 

SELECT subcategoria, moneda, SUM(venta) as ventas FROM stg.order_line_sale as ols
LEFT JOIN stg.product_master as pm
ON pm.codigo_producto = ols.producto
GROUP BY 1, 2
ORDER BY 1, 2

-- Calcular las unidades vendidas por subcategoria de producto y la concatenacion de pais, provincia; usar 
-- guion como separador y usarla para ordernar el resultado.
SELECT * FROM stg.order_line_sale 
SELECT * FROM stg.store_master
SELECT * FROM stg.product_master

SELECT subcategoria, provincia || '-' || pais AS concat_pp, SUM(venta) as venta FROM stg.order_line_sale ols
LEFT JOIN stg.store_master sm
ON sm.codigo_tienda = ols.tienda
LEFT JOIN stg.product_master pm
ON pm.codigo_producto = ols.producto
GROUP BY concat_pp, subcategoria
ORDER BY subcategoria

-- Mostrar una vista donde sea vea el nombre de tienda y la cantidad de entradas de personas que hubo desde la fecha de apertura para el sistema "super_store".
SELECT * FROM stg.super_store_count
SELECT * FROM stg.store_master

SELECT tienda, nombre, SUM(conteo) AS personas FROM stg.super_store_count ssc
LEFT JOIN stg.store_master sm
ON sm.codigo_tienda = ssc.tienda
GROUP BY 1, 2

-- Cual es el nivel de inventario promedio en cada mes a nivel de codigo de producto y tienda; mostrar el resultado con el nombre de la tienda.
SELECT * FROM stg.inventory
SELECT * FROM stg.store_master

SELECT tienda, nombre, sku, TO_CHAR(fecha, 'YYYY-MM') fecha, AVG(final) FROM stg.inventory i
LEFT JOIN stg.store_master sm
ON i.tienda = sm.codigo_tienda
GROUP BY fecha, tienda, sku, nombre

-- Calcular la cantidad de unidades vendidas por material (nivel de agrupacion). 
--Para los productos que no tengan material usar 'Unknown', homogeneizar los textos si es necesario.
SELECT * FROM stg.product_master
SELECT * FROM stg.order_line_sale 

SELECT UPPER(material) material_hm, SUM(venta) venta FROM stg.order_line_sale s
LEFT JOIN stg.product_master pm
ON pm.codigo_producto = s.producto
GROUP BY material_hm

-- Mostrar la tabla order_line_sales agregando una columna que represente el valor de venta bruta en cada linea 
-- convertido a dolares usando la tabla de tipo de cambio.
SELECT * FROM stg.order_line_sale 
SELECT * FROM stg.monthly_average_fx_rate

SELECT *, 
CASE WHEN moneda = 'ARS' THEN venta / cotizacion_usd_peso
    WHEN moneda = 'EUR' THEN venta * cotizacion_usd_eur
    ELSE OLS.venta / cotizacion_usd_uru END AS venta_usd
FROM stg.order_line_sale ols
LEFT JOIN stg.monthly_average_fx_rate r
ON TO_CHAR(ols.fecha, 'YYYY-MM') = TO_CHAR(r.mes, 'YYYY-MM')

-- Calcular cantidad de ventas totales de la empresa en dolares.
WITH ventas_usd AS(
SELECT *, 
CASE WHEN moneda = 'ARS' THEN venta / cotizacion_usd_peso
    WHEN moneda = 'EUR' THEN venta * cotizacion_usd_eur
    ELSE OLS.venta / cotizacion_usd_uru END AS venta_usd
FROM stg.order_line_sale ols
LEFT JOIN stg.monthly_average_fx_rate r
ON TO_CHAR(ols.fecha, 'YYYY-MM') = TO_CHAR(r.mes, 'YYYY-MM')
)

SELECT SUM (venta_usd) FROM ventas_usd

-- Mostrar en la tabla de ventas el margen de venta por cada linea. Siendo margen = (venta - promociones) - costo expresado en dolares.
SELECT * FROM stg.order_line_sale 
SELECT * FROM stg.cost

WITH ventas_usd AS(
SELECT *, 
CASE WHEN moneda = 'ARS' THEN venta / cotizacion_usd_peso
    WHEN moneda = 'EUR' THEN venta * cotizacion_usd_eur
    ELSE OLS.venta / cotizacion_usd_uru END AS venta_usd,
	CASE WHEN moneda = 'ARS' THEN descuento / r.cotizacion_usd_peso
    WHEN moneda = 'EUR' THEN descuento * r.cotizacion_usd_eur
    ELSE descuento / r.cotizacion_usd_uru END AS descuento_usd
FROM stg.order_line_sale ols
LEFT JOIN stg.monthly_average_fx_rate r
ON TO_CHAR(ols.fecha, 'YYYY-MM') = TO_CHAR(r.mes, 'YYYY-MM')
)
SELECT 
	producto, 
	venta_usd, 
	descuento_usd, 
	costo_promedio_usd,
	(venta_usd + COALESCE(descuento_usd, 0)) - costo_promedio_usd
FROM ventas_usd v
LEFT JOIN stg.cost c
ON c.codigo_producto = v.producto
LEFT JOIN stg.monthly_average_fx_rate r
ON TO_CHAR(v.fecha, 'YYYY-MM') = TO_CHAR(r.mes, 'YYYY-MM')

-- Calcular la cantidad de items distintos de cada subsubcategoria que se llevan por numero de orden.
SELECT * FROM stg.order_line_sale 
SELECT * FROM stg.product_master

SELECT orden, producto, subsubcategoria, SUM(cantidad) cant_vend
FROM stg.order_line_sale s
LEFT JOIN stg.product_master pm
ON pm.codigo_producto = s.producto
GROUP BY 1, 2 ,3
ORDER BY orden


