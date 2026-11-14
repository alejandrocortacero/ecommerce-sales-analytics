## Diccionario de datos — E-Commerce Analytics

**Proyecto:** E-Commerce Analytics  
**Fuente:** [Online Retail, UCI Machine Learning Repository](https://archive.ics.uci.edu/dataset/352/online+retail)  
**Periodo de origen:** diciembre de 2010 a diciembre de 2011  
**Moneda:** libra esterlina (GBP, £)

## 1. Objetivo

Documentar el significado de las columnas, las transformaciones realizadas y las limitaciones de los datos utilizados en los análisis de Pandas, PostgreSQL y Power BI.

## 2. Dataset original (`data/raw/Online Retail.xlsx`)

El archivo original contiene **541.909 líneas** de transacciones. Una línea corresponde a un artículo o concepto dentro de una factura; **no equivale necesariamente a un pedido completo**.

| Columna original | Significado | Observaciones |
|---|---|---|
| `InvoiceNo` | Identificador de factura | El prefijo `C` indica cancelación en el dataset original. |
| `StockCode` | Código de producto o concepto | Algunos códigos representan cargos o conceptos especiales. |
| `Description` | Descripción del artículo | Puede faltar o variar entre registros. |
| `Quantity` | Unidades registradas | Pueden aparecer cantidades negativas en el original. |
| `InvoiceDate` | Fecha y hora de la operación | El origen no garantiza la zona horaria local de cada cliente. |
| `UnitPrice` | Precio unitario en GBP | Revisar importes cero, negativos o extremos. |
| `CustomerID` | Identificador de cliente | Existen numerosos valores ausentes; es un identificador, no una magnitud. |
| `Country` | País o categoría geográfica | Verificar etiquetas antes de interpretar países distintos. |

## 3. Datos preparados (`data/processed/online_retail_ventas.csv`)

Las reglas aplicadas en la lección 5 seleccionan las líneas que:

- No tienen un `InvoiceNo` que empiece por `C`.
- Tienen `Quantity > 0`.
- Tienen `UnitPrice > 0`.
- Tienen `InvoiceDate` válido.

**No se descartan automáticamente los registros sin `CustomerID`**, porque todavía pueden servir para medir facturación por producto o por país.

En la ejecución documentada de las lecciones anteriores se conservaron **530.104 líneas**. Esta cifra es una referencia para comprobar la consistencia de esa versión de la transformación, no una condición universal del dataset.

### Columnas añadidas durante la transformación

| Columna | Tipo conceptual | Regla / significado |
|---|---|---|
| `EsCancelacion` | Booleano | El identificador de factura empieza por `C`. |
| `CantidadNegativa` | Booleano | `Quantity < 0`. |
| `PrecioNoPositivo` | Booleano | `UnitPrice <= 0`. |
| `Anio` | Entero | Año extraído de `InvoiceDate`. |
| `Mes` | Entero | Mes (1–12) extraído de `InvoiceDate`. |
| `ImporteLinea` | Decimal | `Quantity * UnitPrice`, expresado en GBP. |

## 4. Correspondencia con PostgreSQL

**Tabla:** `ventas_online_retail`

| Columna CSV | Columna PostgreSQL | Tipo SQL |
|---|---|---|
| `InvoiceNo` | `invoice_no` | `TEXT` |
| `StockCode` | `stock_code` | `TEXT` |
| `Description` | `descripcion` | `TEXT` |
| `Quantity` | `cantidad` | `INTEGER` |
| `InvoiceDate` | `fecha` | `TIMESTAMP` |
| `UnitPrice` | `precio_unitario` | `NUMERIC` |
| `CustomerID` | `customer_id` | `TEXT` |
| `Country` | `pais` | `TEXT` |
| `EsCancelacion` | `es_cancelacion` | `BOOLEAN` |
| `CantidadNegativa` | `cantidad_negativa` | `BOOLEAN` |
| `PrecioNoPositivo` | `precio_no_positivo` | `BOOLEAN` |
| `Anio` | `anio` | `INTEGER` |
| `Mes` | `mes` | `INTEGER` |
| `ImporteLinea` | `importe_linea` | `NUMERIC` |

## 5. Definición de indicadores

| Indicador | Definición | Precaución |
|---|---|---|
| Facturación seleccionada | `SUM(importe_linea)` | Importe bruto de las líneas seleccionadas, **no facturación neta**. |
| Facturas únicas | `COUNT(DISTINCT invoice_no)` | Distinguir líneas de factura y facturas completas. |
| Unidades | `SUM(cantidad)` | En esta tabla ya se han excluido cantidades no positivas. |
| Clientes identificados | `COUNT(DISTINCT customer_id)` | No incluye transacciones sin identificador. |
| Ticket medio | Facturación seleccionada / facturas únicas | No es el promedio de `importe_linea`. |

## 6. Decisiones y limitaciones

- **Cancelaciones y devoluciones:** excluidas de la tabla preparada. Para analizar ventas netas será necesario tratar los movimientos originales con reglas comerciales explícitas.
- **Duplicados:** no deben eliminarse automáticamente sin verificar su significado.
- **Códigos especiales:** `POST`, `DOT` y otros conceptos deben revisarse antes de publicar rankings de productos físicos.
- **Rentabilidad:** el dataset no contiene costes de adquisición; facturación no equivale a beneficio.
- **Cobertura temporal:** diciembre de 2011 está incompleto; comparar meses sin revisar cobertura puede inducir conclusiones erróneas.
- **Precisión monetaria:** redondear para presentar resultados, no antes de agregarlos sin necesidad.

## 7. Uso en el proyecto

- **Pandas:** comprobar tipos, nulos y transformaciones.
- **SQL:** validar y agregar registros de `ventas_online_retail`.
- **Power BI:** documentar el origen y significado de cada KPI que aparece en el dashboard.

## 8. Próxima revisión

Actualizar este diccionario si cambian las reglas de limpieza, se importa una tabla de movimientos originales o se crea un modelo dimensional de Power BI.
