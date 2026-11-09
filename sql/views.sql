-- Vista de facturación por país
CREATE OR REPLACE VIEW vw_facturacion_pais AS
SELECT
    pais,
    SUM(importe_linea) AS facturacion
FROM ventas_online_retail
GROUP BY pais
ORDER BY facturacion DESC;


-- Vista de facturación mensual
CREATE OR REPLACE VIEW vw_facturacion_mensual AS
SELECT
    DATE_TRUNC('month', fecha)::date AS mes,
    ROUND(SUM(importe_linea), 2) AS facturacion,
    COUNT(DISTINCT invoice_no) AS pedidos,
    SUM(cantidad) AS unidades_vendidas
FROM ventas_online_retail
GROUP BY DATE_TRUNC('month', fecha)::date;