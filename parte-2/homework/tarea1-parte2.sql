- - Crear una vista con el resultado del ejercicio de la Parte 1 - Clase 2 - Ejercicio 10, donde unimos la cantidad de gente que ingresa a tienda usando los dos sistemas.
CREATE OR REPLACE VIEW stg.all_store_counts
AS
SELECT tienda, DATE(fecha::TEXT) as fecha, conteo FROM stg.market_count
UNION ALL
SELECT tienda, DATE(fecha::TEXT) as fecha, conteo FROM stg.super_store_count

-- Recibimos otro archivo con ingresos a tiendas de meses anteriores. Ingestar el archivo y agregarlo a la vista del ejercicio anterior
--(Ejercicio 1 Clase 6). Cual hubiese sido la diferencia si hubiesemos tenido una tabla? (contestar la ultima pregunta con un texto escrito en forma de comentario)
CREATE TABLE stg.super_store_count_september
(
tienda SMALLINT
, fecha DATE
, conteo SMALLINT
);
SELECT * FROM stg.super_store_count_september

CREATE OR REPLACE VIEW stg.all_store_counts
AS
SELECT tienda, DATE(fecha::TEXT) as fecha, conteo FROM stg.market_count
UNION ALL
SELECT tienda, DATE(fecha::TEXT) as fecha, conteo FROM stg.super_store_count
UNION ALL
SELECT tienda, DATE(fecha::TEXT) as fecha, conteo FROM stg.super_store_count_september

-- Crear una vista con el resultado del ejercicio de la Parte 1 - Clase 3 - Ejercicio 10, donde calculamos el margen bruto en dolares.
-- Agregarle la columna de ventas, descuentos, y creditos en dolares para poder reutilizarla en un futuro.

CREATE OR REPLACE VIEW stg.tabla_ventas_usd
AS
SELECT orden, producto, tienda, cantidad,
	costo_promedio_usd,
	CASE WHEN moneda = 'ARS' THEN venta / cotizacion_usd_peso
		WHEN moneda = 'EUR' THEN venta * cotizacion_usd_eur
		ELSE OLS.venta / cotizacion_usd_uru END AS venta_usd,
	CASE WHEN moneda = 'ARS' THEN descuento / r.cotizacion_usd_peso
		WHEN moneda = 'EUR' THEN descuento * r.cotizacion_usd_eur
		ELSE descuento / r.cotizacion_usd_uru END AS descuento_usd,
	CASE WHEN moneda = 'ARS' THEN impuestos / r.cotizacion_usd_peso
		WHEN moneda = 'EUR' THEN impuestos * r.cotizacion_usd_eur
		ELSE impuestos / r.cotizacion_usd_uru END AS impuesto_usd,
	CASE WHEN moneda = 'ARS' THEN creditos / r.cotizacion_usd_peso
		WHEN moneda = 'EUR' THEN creditos * r.cotizacion_usd_eur
		ELSE creditos / r.cotizacion_usd_uru END AS creditos_usd
FROM stg.order_line_sale ols
LEFT JOIN stg.monthly_average_fx_rate r
ON TO_CHAR(ols.fecha, 'YYYY-MM') = TO_CHAR(r.mes, 'YYYY-MM')
LEFT JOIN stg.cost c
ON c.codigo_producto = ols.producto

-- Generar una query que me sirva para verificar que el nivel de agregacion de la tabla de ventas 
--(y de la vista) no se haya afectado. Recordas que es el nivel de agregacion/detalle? Lo vimos en la teoria de la parte 1! 
--Nota: La orden M999000061 parece tener un problema verdad? Lo vamos a solucionar mas adelante.
SELECT line_key, orden, count(1)
FROM stg.order_line_sale
GROUP BY 1, 2
HAVING count(1) > 1

-- Calcular el margen bruto a nivel Subcategoria de producto. Usar la vista creada.

SELECT * FROM stg.tabla_ventas_usd
SELECT * FROM stg.product_master

SELECT subcategoria, SUM(venta_usd) - SUM(costo_promedio_usd) margen
FROM stg.tabla_ventas_usd v 
LEFT JOIN stg.product_master pm
ON pm.codigo_producto = v.producto
GROUP BY 1

-- Calcular la contribucion de las ventas brutas de cada producto al total de la orden. Por esta vez, si necesitas usar una subquery, podes utilizarla.

SELECT 
  producto,
  SUM(venta_usd) venta_bruta,
  SUM(venta_usd) + SUM(impuesto_usd) + SUM(COALESCE(descuento_usd, 0)) + SUM(COALESCE(creditos_usd, 0)) TOTAL,
  SUM(venta_usd) / (SUM(venta_usd) + SUM(impuesto_usd) + SUM(COALESCE(descuento_usd, 0)) + SUM(COALESCE(creditos_usd, 0))) *100 contribucion
FROM stg.tabla_ventas_usd
GROUP BY 1

-- Calcular las ventas por proveedor, para eso cargar la tabla de proveedores por producto. Agregar el nombre el proveedor en la vista del punto 3.
DROP TABLE stg.suppliers 

CREATE TABLE stg.suppliers 
(
codigo_producto VARCHAR(255),
	nombre VARCHAR(255), 
	is_primary boolean
);

SELECT * FROM stg.suppliers

CREATE OR REPLACE VIEW stg.tabla_ventas_usd
AS
SELECT orden, producto, tienda, cantidad,
	costo_promedio_usd,
	CASE WHEN moneda = 'ARS' THEN venta / cotizacion_usd_peso
		WHEN moneda = 'EUR' THEN venta * cotizacion_usd_eur
		ELSE OLS.venta / cotizacion_usd_uru END AS venta_usd,
	CASE WHEN moneda = 'ARS' THEN descuento / r.cotizacion_usd_peso
		WHEN moneda = 'EUR' THEN descuento * r.cotizacion_usd_eur
		ELSE descuento / r.cotizacion_usd_uru END AS descuento_usd,
	CASE WHEN moneda = 'ARS' THEN impuestos / r.cotizacion_usd_peso
		WHEN moneda = 'EUR' THEN impuestos * r.cotizacion_usd_eur
		ELSE impuestos / r.cotizacion_usd_uru END AS impuesto_usd,
	CASE WHEN moneda = 'ARS' THEN creditos / r.cotizacion_usd_peso
		WHEN moneda = 'EUR' THEN creditos * r.cotizacion_usd_eur
		ELSE creditos / r.cotizacion_usd_uru END AS creditos_usd, nombre, line_key
FROM stg.order_line_sale ols
LEFT JOIN stg.monthly_average_fx_rate r
ON TO_CHAR(ols.fecha, 'YYYY-MM') = TO_CHAR(r.mes, 'YYYY-MM')
LEFT JOIN stg.cost c
ON c.codigo_producto = ols.producto
LEFT JOIN stg.suppliers s
ON s.codigo_producto = ols.producto


-- Verificar que el nivel de detalle de la vista anterior no se haya modificado, en caso contrario que se deberia ajustar? 
--Que decision tomarias para que no se genereren duplicados?

-- Se pide correr la query de validacion.
SELECT line_key, orden, count(1)
FROM stg.tabla_ventas_usd
GROUP BY 1, 2
HAVING count(1) > 1

-- Crear una nueva query que no genere duplicacion.
CREATE OR REPLACE VIEW stg.tabla_ventas_usd
AS
SELECT orden, producto, tienda, cantidad,
	costo_promedio_usd,
	CASE WHEN moneda = 'ARS' THEN venta / cotizacion_usd_peso
		WHEN moneda = 'EUR' THEN venta * cotizacion_usd_eur
		ELSE OLS.venta / cotizacion_usd_uru END AS venta_usd,
	CASE WHEN moneda = 'ARS' THEN descuento / r.cotizacion_usd_peso
		WHEN moneda = 'EUR' THEN descuento * r.cotizacion_usd_eur
		ELSE descuento / r.cotizacion_usd_uru END AS descuento_usd,
	CASE WHEN moneda = 'ARS' THEN impuestos / r.cotizacion_usd_peso
		WHEN moneda = 'EUR' THEN impuestos * r.cotizacion_usd_eur
		ELSE impuestos / r.cotizacion_usd_uru END AS impuesto_usd,
	CASE WHEN moneda = 'ARS' THEN creditos / r.cotizacion_usd_peso
		WHEN moneda = 'EUR' THEN creditos * r.cotizacion_usd_eur
		ELSE creditos / r.cotizacion_usd_uru END AS creditos_usd, nombre, line_key
FROM stg.order_line_sale ols
LEFT JOIN stg.monthly_average_fx_rate r
ON TO_CHAR(ols.fecha, 'YYYY-MM') = TO_CHAR(r.mes, 'YYYY-MM')
LEFT JOIN stg.cost c
ON c.codigo_producto = ols.producto
LEFT JOIN stg.suppliers s
ON s.codigo_producto = ols.producto AND s.is_primary = true

SELECT line_key, orden, count(1)
FROM stg.tabla_ventas_usd
GROUP BY 1, 2
HAVING count(1) > 1
-- Explicar brevemente (con palabras escrito tipo comentario) que es lo que sucedia.

--Algunos productos tenian varios proveedores, pero solo uno es el primario, por lo que se puede suponer que los otros proveedores no estan activos. Se cambio
-- la query para que el primary sea true