SELECT * FROM stg.order_line_sale

--Cuales son los paises donde la empresa tiene tiendas?
SELECT DISTINCT pais FROM stg.store_master

--Cuantos productos por subcategoria tiene disponible para la venta?
SELECT DISTINCT subcategoria FROM stg.product_master

--Cuales son las ordenes de venta de Argentina de mayor a $100.000?
SELECT DISTINCT orden, venta FROM stg.order_line_sale
WHERE venta > 100000

--Obtener los decuentos otorgados durante Noviembre de 2022 en cada una de las monedas?
SELECT orden, venta, descuento FROM stg.order_line_sale
WHERE fecha BETWEEN '2022-11-01' AND '2022-11-30' AND descuento IS NOT null

--Obtener los impuestos pagados en Europa durante el 2022.
SELECT impuestos FROM stg.order_line_sale
WHERE impuestos IS NOT null and EXTRACT('YEAR' FROM fecha) = 2022

--En cuantas ordenes se utilizaron creditos?
SELECT COUNT(DISTINCT creditos) FROM stg.order_line_sale

--Cual es el % de descuentos otorgados (sobre las ventas) por tienda?
SELECT DISTINCT descuento/venta AS descuento, tienda FROM stg.order_line_sale
WHERE descuento IS NOT null

--Cual es el inventario promedio por dia que tiene cada tienda?
SELECT fecha, tienda, AVG(final) AS promedio FROM stg.inventory
GROUP BY 1, 2
ORDER BY 2, 1

--Obtener las ventas netas y el porcentaje de descuento otorgado por producto en Argentina.
SELECT producto, venta - impuestos AS venta_neta, descuento/venta as por_descuento
FROM stg.order_line_sale
WHERE moneda = 'ARS'
GROUP BY producto, venta_neta, por_descuento

--Las tablas "market_count" y "super_store_count" representan dos sistemas distintos que usa la empresa para contar la cantidad 
--de gente que ingresa a tienda, uno para las tiendas de Latinoamerica y otro para Europa. 
--Obtener en una unica tabla, las entradas a tienda de ambos sistemas.
SELECT tienda, DATE(fecha::TEXT) as fecha, conteo FROM stg.market_count
UNION ALL
SELECT tienda, DATE(fecha::TEXT) as fecha, conteo FROM stg.super_store_count

--Cuales son los productos disponibles para la venta (activos) de la marca Phillips?
SELECT * FROM stg.product_master
WHERE is_active = true AND UPPER(nombre) LIKE UPPER('%PHILIPS%')

--Obtener el monto vendido por tienda y moneda y ordenarlo de mayor a menor por valor nominal.
SELECT tienda, moneda, sum(venta) as monto_vendido FROM stg.order_line_sale
GROUP BY tienda, moneda

--Cual es el precio promedio de venta de cada producto en las distintas monedas? Recorda que los valores de venta, 
--impuesto, descuentos y creditos es por el total de la linea.
SELECT producto, avg(venta/cantidad) as venta_promedio, moneda FROM stg.order_line_sale
GROUP BY producto, moneda
ORDER BY producto

--Cual es la tasa de impuestos que se pago por cada orden de venta?
SELECT impuestos/venta as porc_impuesto, orden, moneda FROM stg.order_line_sale
GROUP BY orden, porc_impuesto, moneda
