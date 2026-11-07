-- Muestra las primeras 10 filas de la tabla ventas_online_retail.
SELECT * FROM ventas_online_retail LIMIT 10;

-- Muestra las columnas descripcion, cantidad y precio_unitario de los registros cuyo país sea Spain.
SELECT descripcion, cantidad, precio_unitario 
    FROM ventas_online_retail 
    WHERE pais = 'Spain'
    LIMIT 10;

-- Calcula cuántas facturas distintas existen en la tabla.
SELECT COUNT(DISTINCT invoice_no) 
    FROM ventas_online_retail;

-- Calcula el importe total por país y muestra los cinco primeros ordenados de mayor a menor.
SELECT pais, SUM(importe_linea) AS facturacion 
    FROM ventas_online_retail 
    GROUP BY pais 
    ORDER BY facturacion DESC 
    LIMIT 5;