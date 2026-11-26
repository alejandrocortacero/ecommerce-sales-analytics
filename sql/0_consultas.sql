SELECT pais, COUNT(DISTINCT invoice_no) AS numero_facturas 
    FROM ventas_online_retail 
    GROUP BY pais HAVING COUNT(DISTINCT invoice_no) > 500 
    ORDER BY numero_facturas DESC;

SELECT invoice_no, importe_linea CASE
    WHEN importe_linea >= 500 THEN "Alta"
    ELSE "Normal"
END AS tipo_venta
FROM ventas_online_retail
LIMIT 10;

SELECT
    v.pais,
    m.mercado,
    v.importe_linea
FROM ventas_online_retail AS v
LEFT JOIN mercados AS m
    ON v.pais = m.pais
LIMIT 10;

SELECT
    m.mercado,
    SUM(v.importe_linea) AS Facturacion
FROM ventas_online_retail AS v
INNER JOIN mercados AS m
    ON v.pais = m.pais
GROUP BY m.mercado
ORDER BY Facturacion DESC
LIMIT 10;
SELECT
    ROUND(SUM(importe_linea), 2) AS facturacion,
    COUNT(DISTINCT invoice_no) AS pedidos,
    ROUND(
        SUM(importe_linea) / COUNT(DISTINCT invoice_no),
        2
    ) AS ticket_medio
FROM ventas_online_retail
WHERE pais = 'Spain';