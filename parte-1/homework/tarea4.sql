-- Crear un backup de la tabla product_master. Utilizar un esquema llamada "bkp" y agregar un prefijo al nombre 
--de la tabla con la fecha del backup en forma de numero entero.
CREATE SCHEMA bkp

SELECT * 
INTO bkp.product_master_04032023
FROM stg.product_master

SELECT * FROM bkp.product_master_04032023

-- Hacer un update a la nueva tabla (creada en el punto anterior) de product_master agregando 
--la leyendo "N/A" para los valores null de material y color. Pueden utilizarse dos sentencias.
UPDATE bkp.product_master_04032023 SET material = 'N/A' WHERE material IS NULL;
UPDATE bkp.product_master_04032023 SET color = 'N/A' WHERE color IS NULL;

-- Hacer un update a la tabla del punto anterior, actualizando la columa "is_active", 
--desactivando todos los productos en la subsubcategoria "Control Remoto".
UPDATE bkp.product_master_04032023
SET is_active = false
WHERE subsubcategoria = 'Control remoto';

-- Agregar una nueva columna a la tabla anterior llamada "is_local" 
--indicando los productos producidos en Argentina y fuera de Argentina.
ALTER TABLE bkp.product_master_04032023 ADD COLUMN is_local boolean;

UPDATE bkp.product_master_04032023
SET is_local = (origen = 'Argentina');

-- Agregar una nueva columna a la tabla de ventas llamada "line_key" que resulte ser
-- la concatenacion de el numero de orden y el codigo de producto.
ALTER TABLE stg.order_line_sale ADD COLUMN line_key text;

UPDATE stg.order_line_sale
SET line_key = CONCAT(orden, producto);

-- Eliminar todos los valores de la tabla "order_line_sale" para el POS 1.
DELETE FROM stg.order_line_sale WHERE tienda = 1;

-- Crear una tabla llamada "employees" (por el momento vacia) que tenga un id 
--(creado de forma incremental), nombre, apellido, fecha de entrada, fecha salida, telefono, pais, provincia, codigo_tienda, posicion. 
--Decidir cual es el tipo de dato mas acorde.
CREATE TABLE employees (
    id serial primary key,
    nombre varchar(255),
    apellido varchar(255),
    fecha_entrada date,
    fecha_salida date,
    telefono varchar(255),
    pais varchar(255),
    provincia varchar(255),
    codigo_tienda smallint,
    posicion varchar(255)
);
-- Insertar nuevos valores a la tabla "employees" para los siguientes 4 empleados:
-- Juan Perez, 2022-01-01, telefono +541113869867, Argentina, Santa Fe, tienda 2, Vendedor.
-- Catalina Garcia, 2022-03-01, Argentina, Buenos Aires, tienda 2, Representante Comercial
-- Ana Valdez, desde 2020-02-21 hasta 2022-03-01, España, Madrid, tienda 8, Jefe Logistica
-- Fernando Moralez, 2022-04-04, España, Valencia, tienda 9, Vendedor.
INSERT INTO employees (nombre, apellido, fecha_entrada, fecha_salida, telefono, pais, provincia, codigo_tienda, posicion)
VALUES 
    ('Juan', 'Perez', '2022-01-01', NULL, 541113869867, 'Argentina', 'Santa Fe', 2, 'Vendedor'),
    ('Catalina', 'Garcia', '2022-03-01', NULL, NULL, 'Argentina', 'Buenos Aires', 2, 'Representante Comercial'),
    ('Ana', 'Valdez', '2020-02-21', '2022-03-01', NULL, 'España', 'Madrid', 8, 'Jefe Logistica'),
    ('Fernando', 'Moralez', '2022-04-04', NULL, NULL, 'España', 'Valencia', 9, 'Vendedor');

SELECT * FROM employees

-- Crear un backup de la tabla "cost" agregandole una columna que se llame "last_updated_ts" que sea el momento exacto 
-- en el cual estemos realizando el backup en formato datetime.
SELECT *, NOW() as last_updated_ts
INTO bkp.cost
FROM stg.cost

SELECT * FROM bkp.cost
-- El cambio en la tabla "order_line_sale" en el punto 6 fue un error y debemos volver la tabla a su estado original, como lo harias?
