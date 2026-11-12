-- ============================================================================
-- E-COMMERCE ANALYTICS | CATALOGO DE VISTAS SQL PARA ONLINE RETAIL
-- PostgreSQL | Proyecto: e-commerce-analytics
-- ============================================================================
--
-- PROPOSITO
--   Centralizar las vistas que usamos para analizar facturacion, pedidos,
--   productos, clientes, paises y evolucion temporal, y alimentar Power BI.
--
-- PRERREQUISITOS
--   1. Tener PostgreSQL y la base de datos "ecommerce" en funcionamiento.
--   2. Disponer de la tabla public.ventas_online_retail, importada en la
--      Leccion 7 a partir de nuestro CSV transformado con Pandas.
--   3. Esa tabla contiene, como minimo, las columnas:
--      invoice_no, stock_code, descripcion, cantidad, fecha,
--      precio_unitario, customer_id, pais, importe_linea.
--
-- COMO EJECUTAR ESTE ARCHIVO (desde Ubuntu WSL, en la raiz del proyecto)
--   docker compose exec -T postgres psql -v ON_ERROR_STOP=1 \
--     -U ecommerce -d ecommerce < sql/views_online_retail_completas.sql
--
-- COMO VERIFICARLO (una vez dentro de psql)
--   \dv
--   SELECT * FROM vw_kpis_generales;
--   SELECT * FROM vw_facturacion_mensual ORDER BY mes;
--
-- NOTAS DE CALIDAD E INTERPRETACION
--   * Nuestro CSV de ventas excluyo facturas identificadas como cancelaciones,
--     cantidades no positivas, precios no positivos y fechas invalidas.
--   * Por tanto, estas vistas representan VENTAS POSITIVAS SELECCIONADAS;
--     no equivalen necesariamente a ventas netas, beneficios o datos auditados.
--   * Una fila es una linea de factura, no un pedido completo.
--   * ROUND(..., 2) mejora la presentacion de importes, pero no corrige el
--     origen de eventuales imprecisiones decimales al importar desde CSV.
--   * Los codigos POST, DOT y otros conceptos especiales requieren revision
--     antes de interpretar los rankings como productos fisicos vendidos.
--   * CREATE OR REPLACE VIEW actualiza definiciones compatibles. Si una vista
--     ya existe con columnas del mismo nombre pero tipos distintos,
--     PostgreSQL puede exigir una migracion especifica.
--
-- Este archivo incluye 13 vistas ejecutables y, al final, 4 vistas opcionales
-- comentadas que exigen importar tambien el dataset SIN FILTRAR.
-- ============================================================================

BEGIN;

-- [01] VW_KPIS_GENERALES
-- Una sola fila con los indicadores de la actividad seleccionada:
-- importe acumulado, facturas diferentes, unidades, clientes identificados y
-- ticket medio por factura. Un cliente sin ID no cuenta como cliente unico.
-- Uso en Power BI: tarjetas KPI generales.
CREATE OR REPLACE VIEW vw_kpis_generales AS
SELECT
    ROUND(SUM(importe_linea), 2) AS facturacion_total,
    COUNT(DISTINCT invoice_no) AS pedidos_totales,
    SUM(cantidad) AS unidades_vendidas,
    COUNT(DISTINCT customer_id) AS clientes_identificados,
    ROUND(
        SUM(importe_linea) / NULLIF(COUNT(DISTINCT invoice_no), 0),
        2
    ) AS ticket_medio
FROM ventas_online_retail;


-- [02] VW_FACTURACION_MENSUAL
-- Resume cada mes (anio y mes juntos) en una fila.
-- DATE_TRUNC('month', fecha) lleva cada fecha al primer dia del mes.
-- Uso: grafico de evolucion mensual, pedidos y unidades.
-- Advertencia: diciembre de 2011 es un mes observado parcialmente.
CREATE OR REPLACE VIEW vw_facturacion_mensual AS
SELECT
    DATE_TRUNC('month', fecha)::date AS mes,
    ROUND(SUM(importe_linea), 2) AS facturacion,
    COUNT(DISTINCT invoice_no) AS pedidos,
    SUM(cantidad) AS unidades_vendidas
FROM ventas_online_retail
GROUP BY DATE_TRUNC('month', fecha)::date;


-- [03] VW_FACTURACION_PAIS
-- Resume la facturacion de las lineas seleccionadas por pais.
-- Conserva las columnas originales pais y facturacion y anade dos indicadores:
-- pedidos y unidades_vendidas (compatibilidad con la vista previa de 2 campos).
-- Uso: ranking por pais y KPI geograficos.
CREATE OR REPLACE VIEW vw_facturacion_pais AS
SELECT
    pais,
    ROUND(SUM(importe_linea), 2) AS facturacion,
    COUNT(DISTINCT invoice_no) AS pedidos,
    SUM(cantidad) AS unidades_vendidas
FROM ventas_online_retail
GROUP BY pais;


-- [04] VW_FACTURACION_PAIS_MES
-- Cruza las dos dimensiones: PAIS y MES.
-- Uso: seguir la evolucion de cada pais y construir segmentadores por pais
-- sobre un grafico temporal en Power BI.
CREATE OR REPLACE VIEW vw_facturacion_pais_mes AS
SELECT
    DATE_TRUNC('month', fecha)::date AS mes,
    pais,
    ROUND(SUM(importe_linea), 2) AS facturacion,
    COUNT(DISTINCT invoice_no) AS pedidos,
    SUM(cantidad) AS unidades_vendidas
FROM ventas_online_retail
GROUP BY DATE_TRUNC('month', fecha)::date, pais;


-- [05] VW_PRODUCTOS_RESUMEN
-- Agrupa por codigo de articulo, cuenta unidades, importe y facturas.
-- MIN(descripcion) solo selecciona una descripcion de ejemplo: no corrige
-- inconsistencias ni garantiza el nombre comercial canonico.
-- Uso: top productos por unidades o por facturacion.
-- Precaucion: puede incluir cargos especiales (p. ej. POST/DOT).
CREATE OR REPLACE VIEW vw_productos_resumen AS
SELECT
    stock_code,
    MIN(descripcion) AS descripcion_ejemplo,
    SUM(cantidad) AS unidades_vendidas,
    ROUND(SUM(importe_linea), 2) AS facturacion,
    COUNT(DISTINCT invoice_no) AS pedidos
FROM ventas_online_retail
GROUP BY stock_code;


-- [06] VW_PEDIDOS
-- Cambia la granularidad de LINEA DE FACTURA a FACTURA.
-- Cuenta lineas, codigos distintos, unidades e importe por invoice_no.
-- MIN(fecha) y MIN(pais) dan valores representativos: conviene validar
-- que una factura no agrupa fechas o paises inconsistentes.
-- Uso: importe por pedido, cestas grandes y distribucion del ticket.
CREATE OR REPLACE VIEW vw_pedidos AS
SELECT
    invoice_no,
    MIN(fecha) AS fecha_pedido,
    MIN(pais) AS pais,
    COUNT(*) AS lineas,
    COUNT(DISTINCT stock_code) AS productos_diferentes,
    SUM(cantidad) AS unidades,
    ROUND(SUM(importe_linea), 2) AS importe_pedido
FROM ventas_online_retail
GROUP BY invoice_no;


-- [07] VW_TICKET_MEDIO_PAIS
-- Facturacion / numero de facturas diferentes, para cada pais.
-- NULLIF(..., 0) evita el error de division entre cero.
-- Uso: comparar el valor medio de factura entre paises.
CREATE OR REPLACE VIEW vw_ticket_medio_pais AS
SELECT
    pais,
    ROUND(SUM(importe_linea), 2) AS facturacion,
    COUNT(DISTINCT invoice_no) AS pedidos,
    ROUND(
        SUM(importe_linea) / NULLIF(COUNT(DISTINCT invoice_no), 0),
        2
    ) AS ticket_medio
FROM ventas_online_retail
GROUP BY pais;


-- [08] VW_CLIENTES_RESUMEN
-- Resume solo clientes CON ID conocido. Incluye primera/ultima fecha
-- observada, cantidad de facturas, unidades e importe.
-- No mide toda la vida historica del cliente, solo nuestro dataset 2010-2011.
-- Uso: clientes con mas compras, mayor importe y actividad recurrente.
CREATE OR REPLACE VIEW vw_clientes_resumen AS
SELECT
    customer_id,
    MIN(fecha) AS primera_compra,
    MAX(fecha) AS ultima_compra,
    COUNT(DISTINCT invoice_no) AS pedidos,
    SUM(cantidad) AS unidades,
    ROUND(SUM(importe_linea), 2) AS facturacion
FROM ventas_online_retail
WHERE customer_id IS NOT NULL
GROUP BY customer_id;


-- [09] VW_VENTAS_DIA_SEMANA
-- EXTRACT(ISODOW...) devuelve 1=lunes, ... 7=domingo.
-- Uso: identificar patrones de facturacion y pedidos por dia de semana.
CREATE OR REPLACE VIEW vw_ventas_dia_semana AS
SELECT
    EXTRACT(ISODOW FROM fecha)::integer AS dia_semana,
    ROUND(SUM(importe_linea), 2) AS facturacion,
    COUNT(DISTINCT invoice_no) AS pedidos
FROM ventas_online_retail
GROUP BY EXTRACT(ISODOW FROM fecha)::integer;


-- [10] VW_VENTAS_POR_HORA
-- EXTRACT(HOUR...) extrae la hora registrada en los datos.
-- Uso: analizar concentracion horaria de la actividad.
-- No suponemos que la hora del origen sea la hora local de cada cliente.
CREATE OR REPLACE VIEW vw_ventas_por_hora AS
SELECT
    EXTRACT(HOUR FROM fecha)::integer AS hora,
    COUNT(DISTINCT invoice_no) AS pedidos,
    ROUND(SUM(importe_linea), 2) AS facturacion
FROM ventas_online_retail
GROUP BY EXTRACT(HOUR FROM fecha)::integer;


-- [11] VW_RANKING_PRODUCTOS_PAIS
-- Primero suma la facturacion de cada codigo por pais (CTE).
-- Despues ROW_NUMBER() crea una posicion independiente por pais gracias a
-- PARTITION BY pais. El desempate por stock_code garantiza orden estable.
-- Uso: los 5 o 10 codigos de mayor importe de cada mercado.
CREATE OR REPLACE VIEW vw_ranking_productos_pais AS
WITH ventas_producto_pais AS (
    SELECT
        pais,
        stock_code,
        SUM(importe_linea) AS facturacion
    FROM ventas_online_retail
    GROUP BY pais, stock_code
)
SELECT
    pais,
    stock_code,
    ROUND(facturacion, 2) AS facturacion,
    ROW_NUMBER() OVER (
        PARTITION BY pais
        ORDER BY facturacion DESC, stock_code
    ) AS posicion
FROM ventas_producto_pais;


-- [12] VW_CLIENTES_RECURRENTES
-- Depende de vw_clientes_resumen: por eso la creamos despues.
-- CASE WHEN clasifica a los clientes segun sus facturas distintas.
-- Los umbrales son didacticos y se pueden ajustar a las necesidades reales.
-- Uso: segmentar clientes entre 1, 2-5 y mas de 5 compras observadas.
CREATE OR REPLACE VIEW vw_clientes_recurrentes AS
SELECT
    customer_id,
    pedidos,
    facturacion,
    CASE
        WHEN pedidos = 1 THEN 'Una compra'
        WHEN pedidos BETWEEN 2 AND 5 THEN 'De 2 a 5 compras'
        ELSE 'Mas de 5 compras'
    END AS categoria_cliente
FROM vw_clientes_resumen;


-- [13] VW_DETALLE_POWERBI
-- Conserva la granularidad de linea de factura y anade mes y anio.
-- Es la mejor base para segmentadores dinamicos combinados por pais, fecha,
-- articulo y cliente, porque conserva esas dimensiones en las mismas filas.
-- Importar esta vista en Power BI puede requerir mas memoria que las
-- vistas agregadas, pero mantiene mucha mayor flexibilidad analitica.
CREATE OR REPLACE VIEW vw_detalle_powerbi AS
SELECT
    invoice_no,
    stock_code,
    descripcion,
    cantidad,
    fecha,
    precio_unitario,
    customer_id,
    pais,
    importe_linea,
    DATE_TRUNC('month', fecha)::date AS mes,
    EXTRACT(YEAR FROM fecha)::integer AS anio
FROM ventas_online_retail;

COMMIT;


-- ============================================================================
-- BLOQUE OPCIONAL: ANALISIS DE CANCELACIONES / DEVOLUCIONES / VENTAS NETAS
-- ============================================================================
-- Las siguientes cuatro vistas NO se ejecutan con el modelo actual.
-- Por que: ventas_online_retail procede de un CSV filtrado que EXCLUYE
-- cancelaciones y cantidades negativas. No podemos reconstruir esos casos
-- desde la tabla filtrada sin perder informacion ni inventar datos.
--
-- Para habilitarlas en el futuro:
--   1. Importa el Excel ORIGINAL, sin eliminar sus movimientos, en una tabla
--      llamada ventas_online_retail_raw, con estas columnas como minimo:
--      invoice_no TEXT, stock_code TEXT, descripcion TEXT,
--      cantidad INTEGER, fecha TIMESTAMP, precio_unitario NUMERIC,
--      customer_id TEXT, pais TEXT.
--   2. Descomenta las definiciones de abajo y vuelve a ejecutar el archivo.
--   3. Valida los codigos especiales, impuestos, ajustes y posibles
--      cancelaciones sin correspondencia antes de reportar cifras netas.
--
-- [14] VW_CANCELACIONES
-- Identifica las lineas de facturas cuyo codigo empieza por C.
-- El prefijo C se documenta como cancelacion en el origen Online Retail.
--
-- CREATE OR REPLACE VIEW vw_cancelaciones AS
-- SELECT
--     invoice_no,
--     stock_code,
--     descripcion,
--     cantidad,
--     precio_unitario,
--     fecha,
--     pais,
--     cantidad * precio_unitario AS importe_movimiento
-- FROM ventas_online_retail_raw
-- WHERE UPPER(invoice_no) LIKE 'C%';
--
-- [15] VW_IMPORTE_CANCELACIONES
-- Resume importe y lineas identificadas como cancelaciones por mes.
-- Importes negativos pueden indicar correcciones; no se interpretan de
-- forma aislada como devoluciones efectivas de dinero.
--
-- CREATE OR REPLACE VIEW vw_importe_cancelaciones AS
-- SELECT
--     DATE_TRUNC('month', fecha)::date AS mes,
--     COUNT(*) AS lineas_cancelacion,
--     COUNT(DISTINCT invoice_no) AS facturas_cancelacion,
--     ROUND(SUM(cantidad * precio_unitario), 2) AS importe_movimientos
-- FROM vw_cancelaciones
-- GROUP BY DATE_TRUNC('month', fecha)::date;
--
-- [16] VW_DEVOLUCIONES_PRODUCTO
-- Resume movimientos con cantidad negativa por codigo. No todas las
-- cantidades negativas son necesariamente devoluciones comerciales.
--
-- CREATE OR REPLACE VIEW vw_devoluciones_producto AS
-- SELECT
--     stock_code,
--     MIN(descripcion) AS descripcion_ejemplo,
--     COUNT(*) AS lineas_negativas,
--     SUM(-cantidad) AS unidades_negativas,
--     ROUND(SUM(cantidad * precio_unitario), 2) AS importe_movimientos
-- FROM ventas_online_retail_raw
-- WHERE cantidad < 0
-- GROUP BY stock_code;
--
-- [17] VW_VENTAS_NETAS
-- SOLO UN BALANCE CONTABLE APROXIMADO DE MOVIMIENTOS DEL ORIGEN:
-- suma importes positivos y negativos sin conciliar devoluciones con ventas
-- ni separar tasas y otros ajustes. El nombre no implica dato auditado.
--
-- CREATE OR REPLACE VIEW vw_ventas_netas AS
-- SELECT
--     DATE_TRUNC('month', fecha)::date AS mes,
--     ROUND(SUM(CASE WHEN cantidad > 0 AND precio_unitario > 0
--                    THEN cantidad * precio_unitario ELSE 0 END), 2)
--         AS importe_positivo,
--     ROUND(SUM(CASE WHEN cantidad < 0 AND precio_unitario >= 0
--                    THEN cantidad * precio_unitario ELSE 0 END), 2)
--         AS importe_negativo,
--     ROUND(SUM(cantidad * precio_unitario), 2) AS saldo_movimientos_estimado
-- FROM ventas_online_retail_raw
-- GROUP BY DATE_TRUNC('month', fecha)::date;


-- ============================================================================
-- EJEMPLOS DE CONSULTAS (comentados: no se ejecutan al cargar este archivo)
-- ============================================================================
-- SELECT * FROM vw_kpis_generales;
-- SELECT * FROM vw_facturacion_mensual ORDER BY mes;
-- SELECT * FROM vw_facturacion_pais ORDER BY facturacion DESC LIMIT 10;
-- SELECT * FROM vw_facturacion_pais_mes WHERE pais = 'Spain' ORDER BY mes;
-- SELECT * FROM vw_productos_resumen ORDER BY unidades_vendidas DESC LIMIT 10;
-- SELECT * FROM vw_pedidos ORDER BY importe_pedido DESC LIMIT 10;
-- SELECT * FROM vw_ticket_medio_pais ORDER BY facturacion DESC LIMIT 10;
-- SELECT * FROM vw_clientes_resumen ORDER BY facturacion DESC LIMIT 10;
-- SELECT * FROM vw_ventas_dia_semana ORDER BY dia_semana;
-- SELECT * FROM vw_ventas_por_hora ORDER BY hora;
-- SELECT * FROM vw_ranking_productos_pais
-- WHERE pais = 'Spain' AND posicion <= 5 ORDER BY posicion;
-- SELECT * FROM vw_clientes_recurrentes LIMIT 10;
-- SELECT * FROM vw_detalle_powerbi LIMIT 10;
-- ============================================================================
