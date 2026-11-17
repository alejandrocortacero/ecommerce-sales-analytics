## Validación automática de calidad de datos

**Proyecto:** E-Commerce Analytics  
**Origen:** UCI Online Retail (2010–2011)  
**Archivo:** `src/validate_retail.py`

## 1. Objetivo

Antes de calcular los KPI o actualizar Power BI, comprobamos que el CSV procesado conserva la estructura esperada y cumple nuestras reglas provisionales de ventas de importe positivo.

**Este validador no limpia, borra ni modifica registros.** Produce un informe para que el analista investigue los problemas detectados.

## 2. Requisitos

- Python 3.12 o compatible.
- `pandas` instalado (ya incluido en `requirements.txt` del proyecto).
- El CSV exportado desde `04_transformacion_online_retail.ipynb` en `data/processed/online_retail_ventas.csv`.

La ejecución se hace desde la carpeta raíz del repositorio.

## 3. Ejecución

```bash
python -m src.validate_retail
```

Especificar otro CSV:

```bash
python -m src.validate_retail --csv data/processed/online_retail_ventas.csv
```

Guardar un informe JSON:

```bash
python -m src.validate_retail --output reports/quality_report.json
```

Utilizar Docker/Jupyter del proyecto si no tienes Python configurado en Ubuntu:

```bash
docker compose exec jupyter python -m src.validate_retail
```

**Nota:** el comando de Docker se ejecuta desde la terminal Ubuntu, no dentro de PostgreSQL (`ecommerce=#`).

## 4. Controles que realiza

| Control | Severidad | Motivo |
|---|---|---|
| Columnas requeridas ausentes | Error | La estructura no corresponde al dataset esperado |
| CSV vacío | Error | No hay datos que analizar |
| `InvoiceNo` ausente | Error | No se puede asociar una línea a su factura |
| Fecha no válida | Error | Impide el análisis temporal |
| Cantidad no numérica o no positiva | Error | Incumple nuestra selección de ventas positivas |
| Precio no numérico o no positivo | Error | Incumple nuestra selección de ventas positivas |
| `ImporteLinea` no numérico | Error | Impide calcular ingresos |
| Importe inconsistente | Error | Diferencia de más de 0,01 £ respecto a `Quantity * UnitPrice` |
| Factura comenzada por `C` | Error | Las cancelaciones se excluyeron en la transformación actual |
| `CustomerID` ausente | Aviso | Puede servir para facturación general, pero no para analizar clientes |
| Filas exactamente duplicadas | Aviso | Revisar el contexto antes de eliminarlas |
| País, código o descripción ausentes | Aviso | Puede limitar análisis por país o producto |

El informe contiene un estado general: `ok`, `warning` o `error`.

El script **no considera automáticamente** que códigos como `POST` o `DOT` sean productos ordinarios. La clasificación comercial queda pendiente de revisión específica.

## 5. Indicadores del informe

- **rows:** líneas del CSV.
- **distinct_invoices:** identificadores de factura diferentes.
- **identified_customers:** clientes distintos si existe `CustomerID`.
- **total_quantity:** suma de las cantidades.
- **gross_selected_amount_gbp:** suma de los importes seleccionados, redondeada a dos decimales para mostrarla.

El total es una **facturación bruta seleccionada**, no ingresos netos auditados. El dataset tratado excluye cancelaciones y determinados movimientos, por lo que no debemos interpretarlo como ventas netas.

## 6. Pruebas automáticas

Las pruebas usan datos **sintéticos**, sin necesidad de subir el Excel original a GitHub.

```bash
python -m unittest discover -s tests -p 'test_*.py' -v
```

Validan casos correctos, columnas ausentes, cancelaciones, cantidades no positivas, clientes anónimos, duplicados, fechas inválidas, importes incoherentes y exportación JSON.

El workflow `.github/workflows/quality-tests.yml` ejecuta estas pruebas automáticamente en GitHub Actions.

## 7. Interpretar los resultados

- **ok:** no se detectaron incidencias dentro de los controles implementados.
- **warning:** hay datos que requieren revisión, pero pueden ser válidos comercialmente.
- **error:** se incumple la estructura o alguna regla de la selección positiva.

Por defecto, el comando devuelve código de salida distinto de cero solo para errores. La opción `--strict` también lo hace cuando hay avisos:

```bash
python -m src.validate_retail --strict
```

**Importante:** obtener `ok` no demuestra que todos los registros sean perfectos: estos controles cubren solo las reglas descritas.

## 8. Integración en el proceso ETL

1. Importar `Online Retail.xlsx` en Pandas.
2. Preparar el conjunto `df_ventas` con las reglas de la Lección 5.
3. Exportar `data/processed/online_retail_ventas.csv`.
4. Ejecutar `python -m src.validate_retail`.
5. Investigar incidencias antes de cargar o actualizar PostgreSQL.
6. Consultar las vistas SQL y actualizar Power BI.

La versión actual es un **primer control de calidad automatizado**. Próximas mejoras posibles: reglas para códigos especiales, control de cobertura temporal, comparación con totales de PostgreSQL y seguimiento histórico de incidencias.
