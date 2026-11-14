-- ================================================================
-- E-COMMERCE ANALYTICS | CONTROLES DE CALIDAD
-- Tabla: public.ventas_online_retail
--
-- Consultas de SOLO LECTURA: no modifican datos ni crean objetos.
-- Ejecutar una vez importado el CSV preparado en PostgreSQL.
-- No asumir que una anomalía representa automáticamente un error.
-- ================================================================

-- 1. INVENTARIO GENERAL
-- Comprobar volumen, fechas y cobertura. Contrastar con el notebook
-- de transformación antes de interpretar diferencias de recuentos.
SELECT
    COUNT(*) AS total_lineas,
    COUNT(DISTINCT invoice_no) AS facturas_unicas,
    COUNT(DISTINCT customer_id) AS clientes_identificados,
    MIN(fecha) AS fecha_minima,
    MAX(fecha) AS fecha_maxima,
    ROUND(SUM(importe_linea), 2) AS facturacion_seleccionada_gbp
FROM ventas_online_retail;

-- 2. VALORES AUSENTES EN CAMPOS IMPORTANTES
-- CustomerID puede faltar legítimamente en nuestro subconjunto.
SELECT
    COUNT(*) FILTER (WHERE invoice_no IS NULL) AS sin_factura,
    COUNT(*) FILTER (WHERE stock_code IS NULL) AS sin_codigo,
    COUNT(*) FILTER (WHERE descripcion IS NULL) AS sin_descripcion,
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS sin_cliente,
    COUNT(*) FILTER (WHERE pais IS NULL) AS sin_pais,
    COUNT(*) FILTER (WHERE fecha IS NULL) AS sin_fecha
FROM ventas_online_retail;

-- 3. VERIFICAR LAS REGLAS PROVISIONALES DE SELECCION
-- Se espera cero en estos recuentos si el CSV mantiene las reglas
-- acordadas. Los recuentos no deben mezclarse sumándolos directamente
-- porque una misma fila podría incumplir varias reglas.
SELECT
    COUNT(*) FILTER (WHERE cantidad <= 0 OR cantidad IS NULL) AS cantidad_invalida,
    COUNT(*) FILTER (WHERE precio_unitario <= 0 OR precio_unitario IS NULL) AS precio_invalido,
    COUNT(*) FILTER (WHERE fecha IS NULL) AS fecha_invalida,
    COUNT(*) FILTER (
        WHERE UPPER(COALESCE(invoice_no, '')) LIKE 'C%'
    ) AS cancelaciones_en_seleccion
FROM ventas_online_retail;

-- 4. VALIDAR LA COLUMNA CALCULADA IMPORTE_LINEA
-- Detecta líneas que no coinciden con cantidad * precio_unitario.
-- Se usa tolerancia de 0.01 GBP para evitar pequeñas diferencias
-- numéricas derivadas de las conversiones previas.
SELECT
    COUNT(*) AS lineas_con_diferencia_superior_a_un_penique
FROM ventas_online_retail
WHERE importe_linea IS NULL
   OR ABS(importe_linea - cantidad * precio_unitario) > 0.01;

-- 5. DETECTAR DUPLICADOS EXACTOS DE CAMPOS DE NEGOCIO
-- Solo es una señal para revisar, NO una instrucción para borrar.
-- Puede ser más costosa que las consultas anteriores.
WITH agrupadas AS (
    SELECT
        invoice_no, stock_code, descripcion, cantidad, fecha,
        precio_unitario, customer_id, pais, importe_linea,
        COUNT(*) AS repeticiones
    FROM ventas_online_retail
    GROUP BY
        invoice_no, stock_code, descripcion, cantidad, fecha,
        precio_unitario, customer_id, pais, importe_linea
    HAVING COUNT(*) > 1
)
SELECT
    COUNT(*) AS grupos_duplicados,
    COALESCE(SUM(repeticiones - 1), 0) AS filas_adicionales_duplicadas
FROM agrupadas;

-- 6. COMPROBAR CONSISTENCIA DE PAIS POR FACTURA
-- Algunas facturas con paises distintos requieren investigacion.
SELECT
    invoice_no,
    COUNT(DISTINCT pais) AS paises_distintos
FROM ventas_online_retail
GROUP BY invoice_no
HAVING COUNT(DISTINCT pais) > 1
ORDER BY paises_distintos DESC, invoice_no
LIMIT 20;

-- 7. COBERTURA MENSUAL Y VOLUMEN
-- El último mes de 2011 está parcialmente cubierto en el original.
SELECT
    DATE_TRUNC('month', fecha)::date AS mes,
    COUNT(*) AS lineas,
    COUNT(DISTINCT invoice_no) AS facturas,
    ROUND(SUM(importe_linea), 2) AS facturacion_gbp
FROM ventas_online_retail
GROUP BY DATE_TRUNC('month', fecha)::date
ORDER BY mes;

-- 8. CODIGOS QUE CONVIENE REVISAR ANTES DEL RANKING DE PRODUCTOS
-- Son conceptos o cargos conocidos en este dataset; verificar
-- significados antes de excluirlos de un análisis comercial.
SELECT
    stock_code,
    MIN(descripcion) AS descripcion_ejemplo,
    COUNT(*) AS lineas,
    ROUND(SUM(importe_linea), 2) AS importe_gbp
FROM ventas_online_retail
WHERE stock_code IN ('POST', 'DOT')
GROUP BY stock_code
ORDER BY importe_gbp DESC;

-- 9. EXTREMOS DE PRECIO UNITARIO
-- Permite inspeccionar registros especiales o valores atipicos.
SELECT
    invoice_no, stock_code, descripcion, cantidad,
    precio_unitario, importe_linea, fecha
FROM ventas_online_retail
ORDER BY precio_unitario DESC NULLS LAST
LIMIT 20;

-- 10. CONTROL DE REFERENCIA (OPCIONAL)
-- La versión inicial del proyecto produjo 530104 líneas y
-- 10666684.54 GBP. NO convertir estas cifras en reglas fijas:
-- cambiarán si se corrige la transformación o el dataset.
-- SELECT COUNT(*), ROUND(SUM(importe_linea), 2)
-- FROM ventas_online_retail;
