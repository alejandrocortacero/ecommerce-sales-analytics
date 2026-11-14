## Especificación del dashboard — E-Commerce Analytics

**Estado:** diseño inicial · pendiente de validación visual  
**Herramienta:** Power BI Desktop para Windows  
**Origen:** PostgreSQL (`ecommerce`)  
**Periodo observado:** diciembre de 2010 a diciembre de 2011

## 1. Objetivo de negocio

Crear un informe que permita analizar la **facturación bruta seleccionada** del dataset Online Retail por fecha, país, producto y cliente identificado. El informe debe indicar las limitaciones del conjunto preparado, no presentar sus resultados como ventas netas o beneficio.

## 2. Usuarios previstos

- **Responsable comercial:** seguimiento de facturación y pedidos.
- **Analista de datos:** exploración de patrones y verificación de KPI.
- **Responsable de operaciones:** análisis de productos y unidades.

## 3. Fuentes y modelo

| Vista o tabla | Uso propuesto | Observación |
|---|---|---|
| `vw_kpis_generales` | Comprobación de indicadores globales | Resumen sin dimensiones; no usar para tarjetas que deban filtrarse por mes y país. |
| `vw_facturacion_mensual` | Referencia para evolución mensual | Agregada por mes. |
| `vw_facturacion_pais` | Referencia para ranking geográfico | Agregada por país. |
| `vw_facturacion_pais_mes` | Comparación por país y mes | Adecuada para filtros de esas dos dimensiones. |
| `vw_productos_resumen` | Ranking de productos | Revisar códigos de cargos especiales. |
| `vw_detalle_powerbi` | Fuente principal del dashboard interactivo | Permite que los filtros afecten a los gráficos de forma coherente. |

**Decisión de modelado:** para un primer prototipo interactivo, preferir una única tabla de detalle (`vw_detalle_powerbi`) y medidas calculadas sobre ella. **No** relacionar directamente vistas agregadas por mes y por país como si compartieran una clave granular común: podría dar resultados incorrectos.

## 4. Páginas propuestas

### Página 1 — Resumen ejecutivo

**Indicadores:** facturación seleccionada, facturas únicas, unidades vendidas, clientes identificados y ticket medio.

**Visualizaciones:**

- Línea de facturación por mes.
- Barras de facturación por país (top 10).
- Segmentadores de periodo y país si los visuales utilizan una fuente compatible.

**Pregunta de negocio:** ¿cómo evolucionan las ventas y dónde se concentran?

### Página 2 — Productos

**Indicadores:** facturación por código, unidades y número de facturas en que aparece el código.

**Visualizaciones:** top 10 por facturación, top 10 por unidades, tabla de detalle por código.

**Precaución:** `POST`, `DOT` y otros códigos pueden ser cargos; no etiquetar automáticamente todo como productos físicos. **No hay datos de costes para calcular rentabilidad.**

### Página 3 — Clientes

**Indicadores:** clientes identificados, facturas por cliente y facturación por cliente.

**Visualizaciones:** distribución del número de pedidos y ranking de clientes por facturación.

**Precaución:** los registros sin `CustomerID` están fuera de los análisis individualizados; no confundir cliente identificado con persona física.

### Página 4 — Calidad y metodología

Documentar reglas de selección, cobertura temporal, cancelaciones excluidas, campos ausentes y comprobaciones del pipeline. Enlazar el diccionario de datos y las consultas SQL de controles.

## 5. Medidas DAX iniciales

Estas expresiones suponen que se ha importado `vw_detalle_powerbi` y que contiene `importe_linea`, `invoice_no`, `cantidad` y `customer_id`.

```dax
Facturacion seleccionada = SUM('vw_detalle_powerbi'[importe_linea])

Facturas unicas = DISTINCTCOUNT('vw_detalle_powerbi'[invoice_no])

Unidades vendidas = SUM('vw_detalle_powerbi'[cantidad])

Clientes identificados = DISTINCTCOUNTNOBLANK('vw_detalle_powerbi'[customer_id])

Ticket medio = DIVIDE([Facturacion seleccionada], [Facturas unicas])
```

**Nota:** `DISTINCTCOUNTNOBLANK` no cuenta valores en blanco. Comprobar el nombre y tipo de las columnas tras importarlas. Si hay importes con precisión flotante heredada del CSV, configurar dos decimales en la medida o visual sin modificar innecesariamente los datos base.

## 6. Formato y usabilidad

- Moneda: **GBP (£)** en importes monetarios.
- Fechas: orden cronológico de meses, sin mezclar enero de años diferentes.
- Las tarjetas deben indicar con claridad si representan **ventas seleccionadas** y no ventas netas.
- Mostrar unidades en valores enteros.
- Elegir títulos de visualización que describan el dato, no solo el tipo de gráfico.
- Evitar saturar la página con más visuales de los necesarios.
- Mostrar notas cuando el periodo sea parcial o exista una exclusión relevante.

## 7. Verificaciones antes de publicar

- [ ] La conexión con PostgreSQL se realiza desde Power BI Desktop.
- [ ] Las tablas o vistas esperadas aparecen en el Navegador.
- [ ] Facturación y unidades coinciden con los controles de SQL.
- [ ] Facturas únicas no se confunden con número de líneas.
- [ ] Los filtros de mes y país alteran coherentemente los KPI.
- [ ] No se suman dos veces los resultados de vistas agregadas.
- [ ] Noviembre de 2011 se interpreta con cautela y diciembre de 2011 se identifica como incompleto.
- [ ] Los rankings no se presentan como medidas de beneficio.
- [ ] El archivo `.pbix` no contiene credenciales ni datos sensibles no autorizados.
- [ ] El README contiene capturas y explica cómo reproducir el informe.

## 8. Resultados de referencia de las lecciones anteriores

La versión del dataset preparado revisada durante el curso obtuvo aproximadamente:

| Indicador | Valor de referencia |
|---|---:|
| Líneas seleccionadas | 530.104 |
| Facturación seleccionada | £10.666.684,54 |
| Facturas únicas | 19.960 |
| Unidades vendidas | 5.588.376 |
| Clientes identificados | 4.338 |

No dar estas cifras por definitivas si se modifica la limpieza, el origen o el cálculo del indicador.

## 9. Próximas mejoras

- Modelo en estrella: hechos de ventas y dimensiones de fechas, productos, clientes y países.
- Segmentadores que actúen en todas las páginas.
- Cálculo de devoluciones y ventas netas a partir de movimientos originales.
- Automatizar las validaciones del pipeline de datos.
- Capturas y narrativa de hallazgos para el portfolio.
