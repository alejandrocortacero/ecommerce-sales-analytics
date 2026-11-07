WITH ventas_pais AS (
    SELECT
        pais,
        SUM(importe_linea) AS facturacion
    FROM ventas_online_retail
    GROUP BY pais
)

SELECT
    pais,
    facturacion,
    ROUND(
        facturacion * 100 /
        SUM(facturacion) OVER (),
        2
    ) AS porcentaje_total
FROM ventas_pais
ORDER BY facturacion DESC;



WITH ventas_mensuales AS (
    SELECT
        DATE_TRUNC('month', fecha)::date AS mes,
        SUM(importe_linea) AS facturacion
    FROM ventas_online_retail
    GROUP BY DATE_TRUNC('month', fecha)::date
)

SELECT
    mes,
    facturacion,
    LAG(facturacion) OVER (
        ORDER BY mes
    ) AS mes_anterior
FROM ventas_mensuales
ORDER BY mes;

WITH ventas_mensuales AS (
    SELECT
        DATE_TRUNC('month', fecha)::date AS mes,
        SUM(importe_linea) AS facturacion
    FROM ventas_online_retail
    GROUP BY DATE_TRUNC('month', fecha)::date
),

comparacion AS (
    SELECT
        mes,
        facturacion,
        LAG(facturacion) OVER (
            ORDER BY mes
        ) AS facturacion_anterior
    FROM ventas_mensuales
)

SELECT
    mes,
    ROUND(facturacion, 2) AS facturacion,
    ROUND(facturacion_anterior, 2) AS mes_anterior,
    ROUND(
        (facturacion - facturacion_anterior) * 100 /
        NULLIF(facturacion_anterior, 0),
        2
    ) AS crecimiento_porcentaje
FROM comparacion
ORDER BY mes;