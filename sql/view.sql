CREATE OR REPLACE VIEW vw_facturacion_mensual AS

SELECT
    DATE_TRUNC('month', fecha)::date AS mes,
    SUM(importe_linea) AS facturacion,
    COUNT(DISTINCT invoice_no) AS pedidos,
    SUM(cantidad) AS unidades_vendidas

FROM ventas_online_retail

GROUP BY DATE_TRUNC('month', fecha)::date;

CREATE OR REPLACE VIEW vw_facturacion_pais AS

SELECT
    pais,
    SUM(importe_linea) AS facturacion,
    COUNT(DISTINCT invoice_no) AS pedidos,
    SUM(cantidad) AS unidades_vendidas

FROM ventas_online_retail

GROUP BY pais;