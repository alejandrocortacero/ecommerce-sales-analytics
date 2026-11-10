## Manual de estudio: Pandas y SQL

**Proyecto:** E-Commerce Analytics  
**Nivel:** Fundamentos e introducción al análisis de datos  
**Contenido:** Lecciones 1 a 9, más la conexión conceptual con Power BI de la lección 10  
**Tecnologías:** Python, Pandas, Matplotlib, PostgreSQL, SQL, Docker y JupyterLab

Este documento recopila y ordena la teoría practicada durante el proyecto. Es una guía de consulta y repaso, no un sustituto de resolver ejercicios por cuenta propia.

---

## 1. Visión general: de los archivos a un análisis de negocio

Un flujo de trabajo típico de analítica puede seguir estos pasos:

1. **Extraer:** obtener datos desde Excel, CSV, bases de datos o APIs.
2. **Explorar:** entender columnas, tipos, dimensiones, valores ausentes y anomalías.
3. **Transformar:** corregir formatos, clasificar operaciones y crear variables.
4. **Almacenar:** guardar conjuntos preparados en archivos o en PostgreSQL.
5. **Consultar:** calcular métricas utilizando Pandas o SQL.
6. **Visualizar:** crear gráficos e informes, por ejemplo en Power BI.
7. **Interpretar:** explicar qué significan los resultados y sus limitaciones.

**ETL** significa *Extract, Transform, Load* (extraer, transformar y cargar). Algunas arquitecturas utilizan ELT: primero cargan los datos y después los transforman dentro de la base de datos.

### Nuestro conjunto de datos: Online Retail

Trabajamos con un archivo histórico de transacciones de comercio electrónico, correspondiente a 2010 y 2011, publicado por UCI.

**Fuente:** UCI Machine Learning Repository, Online Retail: https://archive.ics.uci.edu/dataset/352/online+retail

| Columna original | Significado |
|---|---|
| `InvoiceNo` | Identificador de factura. Un valor que empieza por `C` señala una cancelación según la documentación del dataset. |
| `StockCode` | Código del producto o concepto facturado. |
| `Description` | Descripción del producto o concepto. |
| `Quantity` | Cantidad de unidades; puede ser negativa. |
| `InvoiceDate` | Fecha y hora de la transacción. |
| `UnitPrice` | Precio unitario en libras esterlinas. |
| `CustomerID` | Identificador del cliente; puede estar ausente. |
| `Country` | País o categoría geográfica asignada a la transacción. |

**Granularidad:** cada fila es una línea de factura, no necesariamente un pedido completo. Una misma factura puede aparecer en varias filas.

En nuestro proyecto observamos **541.909 filas originales** y generamos una selección provisional de **530.104 líneas** para el análisis de ventas. Las cifras se refieren exclusivamente a este conjunto de datos y a nuestras reglas de filtrado.

---

## 2. Entorno de trabajo del proyecto

**Windows 11:** Docker Desktop y, más adelante, Power BI Desktop.  
**Ubuntu con WSL2:** comandos de terminal y Git.  
**Docker:** contenedores de PostgreSQL y JupyterLab.  
**JupyterLab:** cuadernos de Python para análisis interactivo.  
**PostgreSQL:** almacenamiento persistente y consultas SQL.

Para iniciar los servicios desde **Ubuntu**, con Docker Desktop abierto:

```bash
cd ~/proyectos/e-commerce-analytics
docker compose up -d
docker compose ps
```

JupyterLab está disponible en `http://localhost:8888/lab`, siempre que el servicio esté iniciado.

Para entrar en PostgreSQL desde Ubuntu:

```bash
docker compose exec postgres psql -U ecommerce -d ecommerce
```

**Diferencia de terminales:**

- **Prompt de Ubuntu:** aquí se ejecutan `docker`, `git`, `ls` y otros comandos del sistema.
- **Prompt `ecommerce=#`:** aquí se ejecutan consultas SQL y metacomandos de `psql`.
- **Prompt `ecommerce-#`:** PostgreSQL espera que completes una instrucción. Si fue un error, pulsa `Ctrl+C`.
- **Salir de `psql`:** `\q`.
- **Mostrar vistas:** `\dv`.
- **Desactivar el paginador:** `\pset pager off`.
- **Salir del paginador `less`:** pulsa `q` sin Enter.

**Persistencia:** los datos de PostgreSQL siguen almacenados en el volumen de Docker aunque se detenga el servicio. Evita `docker compose down -v` si quieres conservarlos.

---

## 3. Introducción a Pandas

**Pandas** es una biblioteca de Python para cargar, transformar, explorar y analizar datos tabulares.

```python
import pandas as pd
```

### DataFrame y Series

**DataFrame:** estructura bidimensional de filas y columnas, semejante a una tabla.

```python
ventas = {
    "Pedido": [1001, 1002, 1003],
    "Producto": ["Teclado", "Ratón", "Monitor"],
    "Cantidad": [2, 3, 1],
    "Precio": [25, 15, 180]
}

df = pd.DataFrame(ventas)
```

**Series:** estructura unidimensional que normalmente obtenemos al seleccionar una columna.

```python
precios = df["Precio"]          # Series
columnas = df[["Producto", "Precio"]]  # DataFrame
```

### Importar archivos

```python
# Excel
df_retail = pd.read_excel(
    "../data/raw/Online Retail.xlsx",
    engine="openpyxl"
)

# CSV
df_ventas = pd.read_csv(
    "../data/processed/online_retail_ventas.csv",
    parse_dates=["InvoiceDate"],
    dtype={
        "InvoiceNo": "string",
        "StockCode": "string",
        "CustomerID": "string"
    }
)
```

**Ruta relativa:** `../` sube un directorio desde la carpeta de trabajo actual; la ruta depende del directorio desde el que se ejecuta el notebook, no solo de dónde está guardado.

**`engine="openpyxl"`:** especifica el lector del archivo Excel.

**`parse_dates`:** convierte las columnas indicadas a un tipo de fecha cuando es posible.

**`dtype`:** fija el tipo de datos de algunas columnas. Los identificadores son etiquetas, no cantidades que debamos sumar.

### Exportar datos

```python
df_ventas.to_csv(
    "../data/processed/online_retail_ventas.csv",
    index=False
)
```

**`index=False`:** evita guardar el índice de Pandas como una columna extra.

También existen `to_excel()` y formatos como Parquet, pero en nuestro proyecto hemos utilizado principalmente CSV.

### Datos en memoria frente a datos almacenados

**DataFrame en memoria:** existe mientras se ejecuta el proceso de Python, salvo que lo guardemos en un archivo o base de datos.

**Archivo CSV o Excel:** guarda datos de forma persistente y puede volver a leerse.

**Tabla PostgreSQL:** guarda datos persistentemente, con soporte para múltiples consultas, usuarios, restricciones y transacciones.

Una consulta `SELECT` no almacena por sí sola un resultado nuevo: simplemente lo devuelve.

---

## 4. Inspección y exploración de DataFrames

| Operación | Qué muestra |
|---|---|
| `df.head()` | Las cinco primeras filas, por defecto. |
| `df.head(10)` | Las primeras diez filas. |
| `df.tail()` | Las cinco últimas filas, por defecto. |
| `df.shape` | Tupla con número de filas y columnas. |
| `df.shape[0]` | Número de filas. |
| `df.shape[1]` | Número de columnas. |
| `df.info()` | Tipos, valores no nulos y memoria aproximada. |
| `df.describe()` | Resumen estadístico de columnas numéricas, por defecto. |
| `df.dtypes` | Tipo de cada columna. |
| `display(df)` | Presentación tabular en Jupyter. |

```python
print("Dimensiones:", df_retail.shape)
print("Número de filas:", df_retail.shape[0])
print("Número de columnas:", df_retail.shape[1])

display(df_retail.head(10))
display(df_retail.tail(5))
df_retail.info()
display(df_retail.describe())
```

**Diferencia entre propiedad y método:** `shape` y `dtypes` no llevan paréntesis. `head()`, `info()` y `describe()` sí.

### Estadísticas de `describe()`

- **`count`:** número de valores no nulos.
- **`mean`:** media aritmética.
- **`std`:** desviación estándar.
- **`min` y `max`:** valores mínimo y máximo.
- **`25%`, `50%`, `75%`:** cuartiles; el 50 % representa la mediana.

**Precaución:** una media o un máximo llamativos pueden indicar valores extremos, errores, ajustes o situaciones válidas del negocio. No deben borrarse sin investigar.

---

## 5. Selección de columnas y filtrado con Pandas

### Seleccionar una o varias columnas

```python
df_retail["Quantity"]
df_retail[["InvoiceNo", "Quantity", "Country"]]
```

### Operadores de comparación

- **`==`:** igual.
- **`!=`:** distinto.
- **`>` y `<`:** mayor y menor.
- **`>=` y `<=`:** mayor o igual, menor o igual.

```python
# Cantidades positivas
ventas_positivas = df_retail[df_retail["Quantity"] > 0]

# Registros de España
ventas_espana = df_retail[df_retail["Country"] == "Spain"]
```

### Varias condiciones

En Pandas, los operadores para combinar condiciones entre Series son:

- **`&`:** Y lógico.
- **`|`:** O lógico.
- **`~`:** negación lógica.

```python
ventas_validas = df_retail[
    (df_retail["Quantity"] > 0) &
    (df_retail["UnitPrice"] > 0)
]

espana_o_francia = df_retail[
    (df_retail["Country"] == "Spain") |
    (df_retail["Country"] == "France")
]
```

**Regla fundamental:** rodea cada comparación con paréntesis cuando combines condiciones.

### Filtros booleanos

Una comparación crea una Serie de `True` y `False`.

```python
cantidad_negativa = df_retail["Quantity"] < 0
numero_negativas = cantidad_negativa.sum()
```

Al sumar booleanos, `True` cuenta como 1 y `False` como 0.

**No confundas:**

```python
(df_retail["Quantity"] < 0).sum()  # Cuenta filas con cantidad negativa

df_retail["Quantity"].sum()        # Suma todas las unidades

df_retail[
    df_retail["Quantity"] < 0
]["Quantity"].sum()                # Suma las cantidades negativas
```

---

## 6. Operaciones estadísticas y recuentos

| Método | Uso principal |
|---|---|
| `.sum()` | Sumar valores. |
| `.mean()` | Calcular la media. |
| `.max()` | Obtener el valor máximo. |
| `.min()` | Obtener el valor mínimo. |
| `.count()` | Contar valores no nulos de una Series. |
| `.nunique()` | Contar valores distintos no nulos, por defecto. |
| `.value_counts()` | Calcular la frecuencia de cada valor. |

```python
unidades = df_ventas["Quantity"].sum()
precio_medio = df_ventas["UnitPrice"].mean()
precio_maximo = df_ventas["UnitPrice"].max()
pedidos = df_ventas["InvoiceNo"].nunique()
registros_por_pais = df_ventas["Country"].value_counts()
```

**Ejemplo:** para las facturas `1001, 1001, 1002, 1003`, `count()` devuelve 4 y `nunique()` devuelve 3.

**`df.shape[0]`:** cuenta todas las filas, incluso aunque una columna tenga valores ausentes.

**`count()`:** omite los valores ausentes de la columna elegida.

**`nunique()`:** cuenta identificadores diferentes; resulta esencial cuando varias filas pertenecen al mismo pedido.

---

## 7. Limpieza y calidad de datos con Pandas

### Detectar valores ausentes

```python
# Por columna
df_retail.isna().sum()

# Total en todo el DataFrame
df_retail.isna().sum().sum()

# Número de CustomerID ausentes
df_retail["CustomerID"].isna().sum()
```

**`isna()`:** devuelve `True` cuando falta un valor.

**`notna()`:** devuelve `True` cuando existe un valor.

### Eliminar o completar valores ausentes

```python
# Eliminar filas sin precio
df_sin_precio_nulo = df_retail.dropna(subset=["UnitPrice"])

# Ejemplo: completar país ausente en un DataFrame de trabajo
df_trabajo["Country"] = df_trabajo["Country"].fillna("Desconocido")
```

**`dropna()`:** elimina valores ausentes según los parámetros utilizados.

**`fillna()`:** reemplaza valores ausentes.

**Advertencia:** eliminar filas sin `CustomerID` puede ser adecuado para analizar clientes únicos, pero no necesariamente para analizar ventas totales.

### Detectar duplicados

```python
duplicados = df_retail.duplicated().sum()
df_sin_duplicados = df_retail.drop_duplicates()
```

**`duplicated()`:** indica si una fila está repetida respecto de una anterior.

**`drop_duplicates()`:** elimina filas repetidas según las columnas consideradas.

**Precaución comercial:** una aparente duplicidad puede ser una operación legítima. No apliques eliminación indiscriminada en datos de ventas reales.

### Copiar un DataFrame o compartir referencia

```python
# Misma referencia: ambos nombres apuntan al mismo objeto
df_trabajo = df_retail

# Nueva copia independiente
df_trabajo = df_retail.copy()
```

**Recomendación del proyecto:** conservar `df_retail` como origen y realizar las transformaciones sobre `df_trabajo = df_retail.copy()`.

**Matiz:** Pandas dispone de mecanismos de *copy-on-write* en versiones modernas. No obstante, asignar con `=` no crea un objeto DataFrame independiente.

---

## 8. Transformación de texto, fechas y columnas

### Transformaciones de texto

```python
df_trabajo["EsCancelacion"] = (
    df_trabajo["InvoiceNo"]
    .astype("string")
    .str.upper()
    .str.startswith("C", na=False)
)
```

- **`astype("string")`:** convierte la columna a un tipo de texto de Pandas.
- **`.str.upper()`:** pasa caracteres a mayúsculas.
- **`.str.startswith("C")`:** comprueba el prefijo de las cadenas.
- **`na=False`:** considera que el valor ausente no cumple esa condición.

El resultado es una columna booleana que identifica líneas asociadas a facturas marcadas como cancelación.

### Convertir fechas

```python
df_trabajo["InvoiceDate"] = pd.to_datetime(
    df_trabajo["InvoiceDate"],
    errors="coerce"
)
```

**`pd.to_datetime()`:** convierte datos a fecha y hora.

**`errors="coerce"`:** transforma valores no interpretables en `NaT`, el equivalente a un valor temporal ausente.

### Extraer año, mes o periodo

```python
df_trabajo["Anio"] = df_trabajo["InvoiceDate"].dt.year
df_trabajo["Mes"] = df_trabajo["InvoiceDate"].dt.month
df_trabajo["Periodo"] = df_trabajo["InvoiceDate"].dt.to_period("M")
```

**`.dt`:** permite acceder a componentes de columnas temporales.

**`.dt.year`:** año.

**`.dt.month`:** mes.

**`.dt.to_period("M")`:** periodo mensual que mantiene juntos mes y año, por ejemplo `2011-09`.

### Crear columnas calculadas

```python
df_trabajo["ImporteLinea"] = (
    df_trabajo["Quantity"] * df_trabajo["UnitPrice"]
)
```

**Importe por línea:** cantidad por precio unitario. No es necesariamente el total de la factura.

---

## 9. Reglas de selección del conjunto de ventas

En el proyecto definimos una **selección provisional** de líneas de venta positivas:

```python
df_ventas = df_trabajo[
    (~df_trabajo["EsCancelacion"]) &
    (df_trabajo["Quantity"] > 0) &
    (df_trabajo["UnitPrice"] > 0) &
    (df_trabajo["InvoiceDate"].notna())
].copy()

df_ventas["ImporteLinea"] = (
    df_ventas["Quantity"] * df_ventas["UnitPrice"]
)
```

**Interpretación de las reglas:**

- **Sin cancelación marcada:** se excluyen facturas cuyo identificador comienza por `C`.
- **Cantidad positiva:** se excluyen cantidades cero o negativas.
- **Precio positivo:** se excluyen precios cero o negativos.
- **Fecha válida:** se excluyen fechas ausentes o no interpretables.
- **CustomerID:** se permite que esté ausente para no descartar automáticamente ventas útiles para otros análisis.

**Limitación:** las cifras resultantes representan ventas brutas seleccionadas. No son necesariamente facturación neta, beneficio ni una contabilidad auditada.

**Importante:** los grupos excluidos pueden solaparse. No es correcto sumar todas las categorías de anomalías como si fueran conjuntos independientes.

---

## 10. Agrupar y ordenar información con Pandas

### `groupby()`

Agrupa registros en categorías y permite aplicar agregaciones:

```python
ventas_pais = df_ventas.groupby("Country")["ImporteLinea"].sum()
```

### `sort_values()` y `sort_index()`

```python
# Ordenar de mayor a menor facturación
ventas_pais = ventas_pais.sort_values(ascending=False)

# Ordenar por el índice (por ejemplo, periodos mensuales)
ventas_mensuales = ventas_mensuales.sort_index()
```

**`ascending=False`:** orden descendente.

**`sort_index()`:** ordena por los valores del índice, no por los importes.

### `head()` después de ordenar

```python
top_10 = ventas_pais.sort_values(ascending=False).head(10)
```

La secuencia conceptual es **agrupar, calcular, ordenar y seleccionar**.

### Agrupar por varias columnas

```python
lineas_por_mes = df_ventas.groupby(["Anio", "Mes"]).size()
```

**`.size()`:** cuenta las filas que contiene cada grupo, incluidos registros con valores ausentes en columnas distintas de las claves de agrupación.

### `agg()`: varias métricas a la vez

```python
resumen_pais = df_ventas.groupby("Country").agg(
    Facturacion=("ImporteLinea", "sum"),
    Pedidos=("InvoiceNo", "nunique"),
    Unidades=("Quantity", "sum")
)

resumen_pais["TicketMedio"] = (
    resumen_pais["Facturacion"] / resumen_pais["Pedidos"]
)
```

**`agg()`:** permite definir varias agregaciones y nombrar las columnas finales.

**Atención:** en el dataset, el ticket medio por país utiliza facturas distintas dentro de cada país y excluye las cancelaciones filtradas.

---

## 11. Indicadores comerciales (KPI)

**KPI:** *Key Performance Indicator*, indicador utilizado para evaluar un aspecto del negocio.

### Facturación bruta seleccionada

```python
facturacion_total = df_ventas["ImporteLinea"].sum()
```

**Qué mide:** la suma de importes de las líneas que pasaron nuestros filtros.

### Pedidos o facturas únicas

```python
pedidos_unicos = df_ventas["InvoiceNo"].nunique()
```

**Qué mide:** cantidad de identificadores de factura distintos, no número de filas.

### Ticket medio

```python
ticket_medio = facturacion_total / pedidos_unicos
```

**Fórmula:** facturación dividida entre facturas únicas.

**Error habitual:** `df_ventas["ImporteLinea"].mean()` calcula el importe medio por **línea**, no por pedido.

### Unidades vendidas

```python
unidades_vendidas = df_ventas["Quantity"].sum()
```

### Clientes distintos

```python
clientes_unicos = df_ventas["CustomerID"].nunique()
```

**Precaución:** `nunique()` ignora los identificadores ausentes. Un cliente no identificado no debe interpretarse como una persona única.

### Porcentaje de facturación por país

```python
ventas_pais = df_ventas.groupby("Country")["ImporteLinea"].sum()
porcentaje_reino_unido = (
    ventas_pais.loc["United Kingdom"] / facturacion_total * 100
)
```

**Porcentaje:** parte dividida entre total, multiplicada por 100.

### Análisis temporal

```python
df_ventas["Periodo"] = df_ventas["InvoiceDate"].dt.to_period("M")

ventas_mensuales = (
    df_ventas.groupby("Periodo")["ImporteLinea"]
    .sum()
    .sort_index()
)
```

**Precaución:** diciembre de 2010 y diciembre de 2011 no representan necesariamente meses completos de observación. Deben interpretarse con cuidado.

### Productos: ingresos frente a unidades

```python
# Productos con más ingresos
top_facturacion = (
    df_ventas.groupby("StockCode")["ImporteLinea"]
    .sum()
    .sort_values(ascending=False)
    .head(10)
)

# Productos con más unidades
top_unidades = (
    df_ventas.groupby("StockCode")["Quantity"]
    .sum()
    .sort_values(ascending=False)
    .head(10)
)
```

**Ingresos:** dinero facturado.

**Volumen:** unidades vendidas.

**Beneficio o rentabilidad:** requieren datos de costes, que este dataset no aporta.

**Códigos especiales:** conceptos como `DOT` o `POST` pueden representar cargos u otros conceptos y deben revisarse antes de presentar rankings de productos físicos.

### Cifras que obtuvimos durante el proyecto

Estos resultados son históricos y dependen de nuestra transformación provisional:

| Indicador | Resultado observado |
|---|---:|
| Filas originales | 541.909 |
| Filas seleccionadas | 530.104 |
| Facturación bruta seleccionada | 10.666.684,54 £ |
| Facturas distintas | 19.960 |
| Ticket medio de la selección | 534,40 £ |
| Unidades vendidas | 5.588.376 |
| Clientes identificados diferentes | 4.338 |
| Mes con más facturación | Noviembre de 2011 |

---

## 12. Gráficos básicos con Pandas y Matplotlib

```python
import matplotlib.pyplot as plt
```

### Gráfico de líneas: evolución temporal

```python
ventas_mensuales.plot(
    kind="line",
    figsize=(12, 5),
    marker="o"
)

plt.title("Evolución mensual de la facturación")
plt.xlabel("Mes")
plt.ylabel("Facturación (£)")
plt.grid(True)
plt.show()
```

### Gráfico de barras: comparación de categorías

```python
ventas_pais.sort_values(ascending=False).head(10).plot(
    kind="bar",
    figsize=(12, 5)
)

plt.title("Top 10 países por facturación")
plt.xlabel("País")
plt.ylabel("Facturación (£)")
plt.show()
```

**Regla de elección:**

- **Líneas:** útil para estudiar tendencias a lo largo del tiempo.
- **Barras:** útil para comparar categorías como países o productos.
- **Título y ejes:** deben explicar qué se mide y en qué unidad.
- **Interpretación:** un gráfico debe acompañarse de una conclusión y, si procede, una advertencia sobre los límites de los datos.

---

## 13. Introducción a SQL y PostgreSQL

**SQL** es un lenguaje para trabajar con bases de datos relacionales.

**PostgreSQL** es el sistema de gestión de bases de datos que ejecuta nuestras consultas SQL y almacena las tablas de forma persistente.

**Pandas** no es una base de datos; trabaja principalmente con estructuras en memoria y puede leer o escribir archivos y conectarse a bases de datos.

### Elementos relacionales básicos

- **Base de datos:** conjunto organizado de objetos y datos.
- **Tabla:** conjunto de filas y columnas.
- **Fila o registro:** una observación.
- **Columna o campo:** un atributo.
- **Clave primaria (`PRIMARY KEY`):** identifica de forma única las filas de una tabla.
- **Clave foránea (`FOREIGN KEY`):** referencia una clave de otra tabla y permite establecer integridad entre ellas.
- **Esquema:** espacio de nombres dentro de PostgreSQL, por ejemplo `public`.

### Tipos usados en el proyecto

| Tipo PostgreSQL | Significado |
|---|---|
| `TEXT` | Texto. |
| `INTEGER` | Entero. |
| `NUMERIC` | Número decimal exacto para los valores que almacena. |
| `TIMESTAMP` | Fecha y hora, sin zona horaria en este tipo. |
| `BOOLEAN` | Verdadero o falso. |
| `DATE` | Fecha sin hora. |

**Nota sobre dinero:** si los importes proceden de cálculos previos con números de coma flotante en Python, pueden llegar a PostgreSQL con pequeñas imprecisiones. Guardarlos posteriormente como `NUMERIC` no corrige automáticamente esas cifras de origen. Para presentación se puede utilizar `ROUND(..., 2)`; para cálculos contables rigurosos es preferible decidir la precisión desde la transformación de entrada.

---

## 14. SQL básico: SELECT, FROM, WHERE y LIMIT

### Seleccionar datos

```sql
SELECT invoice_no, pais, cantidad
FROM ventas_online_retail
LIMIT 10;
```

- **`SELECT`:** columnas o expresiones del resultado.
- **`FROM`:** tabla o fuente de los datos.
- **`LIMIT`:** número máximo de filas devueltas.
- **`*`:** todas las columnas.
- **`;`:** termina normalmente una instrucción SQL en `psql`.

```sql
SELECT *
FROM ventas_online_retail
LIMIT 5;
```

**Atención:** `LIMIT` sin `ORDER BY` no garantiza un conjunto de filas en un orden concreto.

### Filtrar con WHERE

```sql
SELECT descripcion, cantidad, precio_unitario
FROM ventas_online_retail
WHERE pais = 'Spain'
LIMIT 10;
```

**Operadores SQL:**

- **`=`:** igual.
- **`<>` o `!=`:** distinto (PostgreSQL admite ambos).
- **`>` y `<`:** mayor y menor.
- **`>=` y `<=`:** comparaciones inclusivas.
- **`AND`:** se cumplen ambas condiciones.
- **`OR`:** se cumple al menos una.
- **`NOT`:** niega una condición.

```sql
SELECT *
FROM ventas_online_retail
WHERE pais = 'Spain'
  AND cantidad > 10
LIMIT 10;
```

**Comillas:** en SQL los valores de texto llevan comillas simples, por ejemplo `'Spain'`.

### Valores ausentes en SQL

Un valor ausente se representa mediante `NULL`.

```sql
SELECT *
FROM ventas_online_retail
WHERE customer_id IS NULL;

SELECT *
FROM ventas_online_retail
WHERE customer_id IS NOT NULL;
```

**No usar `= NULL`:** las comparaciones normales con `NULL` no devuelven verdadero; hay que emplear `IS NULL` o `IS NOT NULL`.

---

## 15. SQL básico: agregaciones y ordenación

### Funciones de agregación

| SQL | Equivalente habitual en Pandas |
|---|---|
| `SUM(columna)` | `.sum()` |
| `AVG(columna)` | `.mean()` |
| `MAX(columna)` | `.max()` |
| `MIN(columna)` | `.min()` |
| `COUNT(*)` | Número de filas. |
| `COUNT(columna)` | `.count()` sobre esa columna. |
| `COUNT(DISTINCT columna)` | `.nunique()` con valores no nulos. |

```sql
SELECT COUNT(*) AS filas
FROM ventas_online_retail;

SELECT COUNT(DISTINCT invoice_no) AS facturas
FROM ventas_online_retail;

SELECT SUM(importe_linea) AS facturacion
FROM ventas_online_retail;
```

**`AS`:** permite asignar un alias a una columna o tabla.

### Agrupar con GROUP BY

```sql
SELECT
    pais,
    SUM(importe_linea) AS facturacion
FROM ventas_online_retail
GROUP BY pais;
```

**`GROUP BY`:** reúne filas que tienen valores iguales en las columnas de agrupación. Permite obtener métricas por país, producto, mes, etc.

### Ordenar con ORDER BY

```sql
SELECT
    pais,
    SUM(importe_linea) AS facturacion
FROM ventas_online_retail
GROUP BY pais
ORDER BY facturacion DESC
LIMIT 5;
```

- **`ASC`:** orden ascendente.
- **`DESC`:** orden descendente.
- **`LIMIT 5`:** devuelve un máximo de cinco filas.

### Diferencia entre DISTINCT y GROUP BY

**`DISTINCT`:** elimina combinaciones duplicadas del resultado seleccionado.

```sql
SELECT DISTINCT pais
FROM ventas_online_retail;
```

**`GROUP BY`:** forma grupos para aplicar cálculos como `SUM()` o `COUNT()`.

---

## 16. SQL intermedio: WHERE y HAVING

**`WHERE`:** filtra filas antes de agruparlas.

**`HAVING`:** filtra grupos después de calcular las agregaciones.

```sql
SELECT
    pais,
    SUM(importe_linea) AS facturacion
FROM ventas_online_retail
WHERE cantidad >= 5
GROUP BY pais
HAVING SUM(importe_linea) > 100000
ORDER BY facturacion DESC;
```

**Orden lógico simplificado:** `FROM`, `WHERE`, `GROUP BY`, `HAVING`, `SELECT`, `ORDER BY`, `LIMIT`.

**Interpretación:** primero se conservan líneas con cinco o más unidades; después se suman por país; finalmente se seleccionan grupos cuya suma supera 100.000 £.

**Error típico:** escribir `WHERE SUM(importe_linea) > 100000`. En esta situación la condición agregada pertenece a `HAVING`.

---

## 17. SQL intermedio: CASE WHEN

**`CASE WHEN`:** genera valores según condiciones, como una clasificación de riesgo, tamaño o segmento.

```sql
SELECT
    invoice_no,
    importe_linea,
    CASE
        WHEN importe_linea >= 500 THEN 'Alta'
        WHEN importe_linea >= 100 THEN 'Media'
        ELSE 'Baja'
    END AS categoria
FROM ventas_online_retail
LIMIT 20;
```

- **`CASE`:** inicia la expresión.
- **`WHEN`:** define una condición.
- **`THEN`:** indica el resultado para esa condición.
- **`ELSE`:** valor cuando ninguna condición anterior se cumple.
- **`END`:** cierra la expresión.

**Orden:** se utiliza el resultado del primer `WHEN` verdadero.

**Importante:** estas categorías clasifican líneas de factura, no pedidos completos. Los umbrales del ejemplo son didácticos.

También se puede agrupar por el resultado de `CASE`:

```sql
SELECT
    CASE
        WHEN importe_linea >= 500 THEN 'Alta'
        WHEN importe_linea >= 100 THEN 'Media'
        ELSE 'Baja'
    END AS categoria,
    COUNT(*) AS lineas
FROM ventas_online_retail
GROUP BY categoria
ORDER BY lineas DESC;
```

---

## 18. SQL intermedio: relaciones y JOIN

Las bases relacionales suelen almacenar los datos en varias tablas. `JOIN` permite combinarlas mediante una condición de relación.

### Tabla auxiliar del curso

```sql
CREATE TABLE IF NOT EXISTS mercados (
    pais TEXT PRIMARY KEY,
    mercado TEXT NOT NULL
);

INSERT INTO mercados (pais, mercado)
VALUES
    ('United Kingdom', 'Nacional'),
    ('Spain', 'Internacional'),
    ('France', 'Internacional'),
    ('Germany', 'Internacional'),
    ('EIRE', 'Internacional')
ON CONFLICT (pais) DO NOTHING;
```

**`PRIMARY KEY`:** evita países repetidos en esta tabla.

**`NOT NULL`:** impide insertar valores ausentes en `mercado`.

**`ON CONFLICT DO NOTHING`:** omite una inserción que infringiría la clave única especificada.

### INNER JOIN

```sql
SELECT
    v.invoice_no,
    v.pais,
    m.mercado,
    v.importe_linea
FROM ventas_online_retail AS v
INNER JOIN mercados AS m
    ON v.pais = m.pais
LIMIT 10;
```

**`INNER JOIN`:** conserva las combinaciones de filas que encuentran coincidencia en ambas tablas.

**`ON`:** especifica cómo se relacionan las columnas.

**Alias `v` y `m`:** simplifican la escritura e identifican de qué tabla proviene cada columna.

### LEFT JOIN

```sql
SELECT
    v.pais,
    m.mercado,
    SUM(v.importe_linea) AS facturacion
FROM ventas_online_retail AS v
LEFT JOIN mercados AS m
    ON v.pais = m.pais
GROUP BY v.pais, m.mercado
ORDER BY facturacion DESC;
```

**`LEFT JOIN`:** conserva todas las filas de la tabla izquierda, aunque no exista coincidencia en la tabla derecha. En ese caso, las columnas de la derecha resultan `NULL`.

### Precaución: duplicar filas accidentalmente

Un `JOIN` puede multiplicar filas si la clave de unión no es única en alguna tabla. Si cada venta coincide con varias filas de una tabla auxiliar, la facturación sumada después puede inflarse.

**Buena práctica:** comprobar la granularidad y la unicidad de la columna usada para relacionar tablas.

---

## 19. Calcular KPI con SQL

### Facturación y pedidos por país

```sql
SELECT
    pais,
    SUM(importe_linea) AS facturacion,
    COUNT(DISTINCT invoice_no) AS pedidos,
    SUM(cantidad) AS unidades
FROM ventas_online_retail
GROUP BY pais
ORDER BY facturacion DESC;
```

### Ticket medio por país

```sql
SELECT
    pais,
    SUM(importe_linea) AS facturacion,
    COUNT(DISTINCT invoice_no) AS pedidos,
    ROUND(
        SUM(importe_linea) / NULLIF(COUNT(DISTINCT invoice_no), 0),
        2
    ) AS ticket_medio
FROM ventas_online_retail
GROUP BY pais
ORDER BY facturacion DESC;
```

**`ROUND(valor, 2)`:** redondea a dos decimales.

**`NULLIF(valor, 0)`:** devuelve `NULL` si el valor es cero; evita dividir entre cero.

**No confundir:** ticket medio por país, calculado con facturas de ese país, y ticket medio global. Cada métrica usa el conjunto de facturas correspondiente.

---

## 20. SQL analítico: fechas y CTE

### Agrupar por mes con DATE_TRUNC

```sql
SELECT
    DATE_TRUNC('month', fecha)::date AS mes,
    SUM(importe_linea) AS facturacion
FROM ventas_online_retail
GROUP BY DATE_TRUNC('month', fecha)::date
ORDER BY mes;
```

**`DATE_TRUNC('month', fecha)`:** lleva cada fecha al comienzo del mes.

**`::date`:** convierte el resultado al tipo `DATE`, sin componente de hora.

### CTE con WITH

Una **CTE (Common Table Expression)** es un resultado intermedio, con nombre, que existe durante la ejecución de una consulta.

```sql
WITH ventas_mensuales AS (
    SELECT
        DATE_TRUNC('month', fecha)::date AS mes,
        SUM(importe_linea) AS facturacion
    FROM ventas_online_retail
    GROUP BY DATE_TRUNC('month', fecha)::date
)
SELECT *
FROM ventas_mensuales
ORDER BY facturacion DESC;
```

**`WITH`:** mejora la legibilidad de consultas con varias transformaciones.

**Diferencia respecto a una tabla:** la CTE no almacena de forma permanente una nueva tabla en PostgreSQL.

---

## 21. SQL analítico: funciones de ventana

Las **funciones de ventana** realizan cálculos sobre un conjunto de filas relacionado con cada fila del resultado sin agruparlas todas en una sola fila.

### OVER(): porcentaje del total

```sql
WITH ventas_pais AS (
    SELECT pais, SUM(importe_linea) AS facturacion
    FROM ventas_online_retail
    GROUP BY pais
)
SELECT
    pais,
    facturacion,
    ROUND(
        facturacion * 100 / SUM(facturacion) OVER (),
        2
    ) AS porcentaje_total
FROM ventas_pais
ORDER BY facturacion DESC;
```

**`SUM(facturacion) OVER ()`:** suma todas las filas de la salida de la CTE y conserva cada país como fila individual.

**Diferencia central:** `GROUP BY` reduce filas al nivel de los grupos; una función de ventana permite añadir un cálculo manteniendo la granularidad del resultado que recibe.

### LAG(): valor de la fila anterior

```sql
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
    LAG(facturacion) OVER (ORDER BY mes) AS mes_anterior
FROM ventas_mensuales
ORDER BY mes;
```

**`LAG()`:** recupera un valor de una fila previa según el orden indicado.

**Primera fila:** devuelve `NULL` si no tiene predecesora.

**Precaución:** si falta un mes, `LAG()` busca la fila anterior disponible, que podría no corresponder al mes natural inmediatamente anterior.

### Variación porcentual de un mes a otro

**Fórmula:** `(facturación actual - facturación anterior) / facturación anterior * 100`.

```sql
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
        LAG(facturacion) OVER (ORDER BY mes) AS anterior
    FROM ventas_mensuales
)
SELECT
    mes,
    ROUND(facturacion, 2) AS facturacion,
    ROUND(anterior, 2) AS mes_anterior,
    ROUND(
        (facturacion - anterior) * 100 / NULLIF(anterior, 0),
        2
    ) AS crecimiento_pct
FROM comparacion
ORDER BY mes;
```

### ROW_NUMBER() y RANK()

```sql
WITH ventas_pais AS (
    SELECT pais, SUM(importe_linea) AS facturacion
    FROM ventas_online_retail
    GROUP BY pais
)
SELECT
    ROW_NUMBER() OVER (ORDER BY facturacion DESC) AS posicion,
    pais,
    facturacion
FROM ventas_pais;
```

**`ROW_NUMBER()`:** numera filas consecutivamente. Ante empates, conviene añadir otra columna al `ORDER BY` para lograr un orden estable.

**`RANK()`:** asigna igual posición a empates y puede dejar huecos posteriores.

---

## 22. Crear y gestionar vistas en PostgreSQL

Una **vista (VIEW)** es una consulta almacenada en la base de datos que puede consultarse como si fuera una tabla.

**Vista normal:** guarda la definición de la consulta, no una copia persistente independiente de sus resultados. Al consultarla, utiliza los datos actuales de las tablas de origen.

### Vista de facturación mensual

```sql
CREATE OR REPLACE VIEW vw_facturacion_mensual AS
SELECT
    DATE_TRUNC('month', fecha)::date AS mes,
    ROUND(SUM(importe_linea), 2) AS facturacion,
    COUNT(DISTINCT invoice_no) AS pedidos,
    SUM(cantidad) AS unidades_vendidas
FROM ventas_online_retail
GROUP BY DATE_TRUNC('month', fecha)::date;
```

### Vista de facturación por país

```sql
CREATE OR REPLACE VIEW vw_facturacion_pais AS
SELECT
    pais,
    ROUND(SUM(importe_linea), 2) AS facturacion
FROM ventas_online_retail
GROUP BY pais;
```

**`CREATE VIEW`:** crea la vista.

**`CREATE OR REPLACE VIEW`:** crea o actualiza una vista existente, cuando los cambios son compatibles con la estructura definida.

**`ROUND(SUM(importe_linea), 2)`:** suma y después redondea a dos decimales. No modifica los datos de origen.

### Consultar las vistas

```sql
SELECT *
FROM vw_facturacion_mensual
ORDER BY mes;

SELECT *
FROM vw_facturacion_pais
ORDER BY facturacion DESC
LIMIT 10;
```

### Archivo SQL frente a vista real

**Archivo `sql/views.sql`:** documento de código que podemos editar y versionar con Git.

**Vista en PostgreSQL:** objeto creado al ejecutar el contenido del archivo.

Crear o editar el archivo no modifica automáticamente las vistas de PostgreSQL.

Desde la terminal de Ubuntu, en la raíz del proyecto, se puede aplicar el archivo:

```bash
docker compose exec -T postgres psql -U ecommerce -d ecommerce < sql/views.sql
```

**Muy importante:** este comando se ejecuta desde **Ubuntu**, no dentro del prompt `ecommerce=#`.

Para comprobar qué vistas existen dentro de `psql`, utiliza `\dv`.

### Vistas y Power BI

Las vistas pueden servir de origen para Power BI. En el modo **Importar**, Power BI conserva una copia de los datos cargados y necesita actualizarse para reflejar cambios en PostgreSQL.

**Limitación de nuestro primer modelo:** una vista resumida por mes y otra por país no permiten, por sí solas, analizar simultáneamente todos los cruces entre mes y país. Para ello hacen falta datos con esas dimensiones conjuntamente o un modelo de hechos y dimensiones.

---

## 23. Cómo se conectan Pandas y PostgreSQL

**Pandas y SQL se complementan**: no es necesario elegir exclusivamente uno.

### ¿Cuándo suele ser más cómodo Pandas?

- **Archivos:** limpieza de Excel y CSV de diferentes fuentes.
- **Transformación:** reglas personalizadas complejas en Python.
- **Exploración:** inspección interactiva en Jupyter.
- **Gráficos y estadística:** integración con Matplotlib y bibliotecas científicas.
- **Automatización:** ejecución repetible de scripts de extracción y limpieza.

### ¿Cuándo suele ser más adecuado SQL/PostgreSQL?

- **Datos centralizados:** tablas persistentes consultadas por varios usuarios.
- **Consultas grandes:** obtener solo las columnas y agregaciones necesarias sin cargar toda la base en RAM de Python.
- **Relaciones:** unir tablas y mantener integridad referencial.
- **Gobierno de datos:** permisos, transacciones, índices y control de concurrencia.
- **Fuentes BI:** ofrecer tablas y vistas listas para dashboards.

**Rendimiento:** ni Pandas ni PostgreSQL son siempre más rápidos. Depende del volumen, el tipo de operación, la configuración, los índices y los recursos disponibles.

### Guardar desde Pandas en PostgreSQL

```python
# Suponemos que ya se ha creado una conexión SQLAlchemy llamada engine.

df_ventas.to_sql(
    "ventas_desde_pandas",
    con=engine,
    if_exists="fail",
    index=False,
    chunksize=5000
)
```

**`to_sql()`:** escribe un DataFrame en una base de datos mediante una conexión compatible.

**`if_exists="fail"`:** no sobreescribe una tabla existente.

**`chunksize=5000`:** organiza la escritura en lotes.

**Advertencia:** una tabla creada automáticamente desde Pandas no sustituye necesariamente a un diseño SQL cuidadoso con tipos exactos, claves, restricciones e índices.

### Recuperar datos SQL en Pandas

```python
consulta = """
SELECT
    pais,
    SUM(importe_linea) AS facturacion
FROM ventas_online_retail
GROUP BY pais
ORDER BY facturacion DESC
"""

# Requiere una conexión SQLAlchemy llamada engine.
df_resultados = pd.read_sql(consulta, con=engine)
display(df_resultados)
```

Con esto, **PostgreSQL calcula el resultado** y **Pandas lo recibe como un DataFrame** para continuar el análisis.

### Seguridad

- **Contraseñas:** almacenar en variables de entorno o configuraciones privadas.
- **`.env`:** no subir al repositorio.
- **Consultas parametrizadas:** utilizar parámetros para valores externos en vez de concatenar directamente texto de usuarios.
- **Volúmenes Docker:** conservar la información persistida.

---

## 24. Equivalencias entre Pandas y SQL

| Necesidad | Pandas | SQL |
|---|---|---|
| Mostrar algunas filas | `df.head(5)` | `SELECT * FROM tabla LIMIT 5;` |
| Seleccionar columnas | `df[["pais", "cantidad"]]` | `SELECT pais, cantidad FROM tabla;` |
| Filtrar | `df[df["cantidad"] > 0]` | `WHERE cantidad > 0` |
| Contar filas | `df.shape[0]` | `COUNT(*)` |
| Sumar | `df["importe"].sum()` | `SUM(importe)` |
| Media | `df["precio"].mean()` | `AVG(precio)` |
| Valores distintos | `df["factura"].nunique()` | `COUNT(DISTINCT factura)` |
| Agrupar | `df.groupby("pais")` | `GROUP BY pais` |
| Ordenar | `.sort_values(ascending=False)` | `ORDER BY valor DESC` |
| Unir tablas | `pd.merge()` | `JOIN ... ON ...` |
| Ausentes | `.isna()` | `IS NULL` |
| Clasificar | Máscaras y columnas calculadas | `CASE WHEN` |
| Guardar datos | `.to_csv()` o `.to_sql()` | Tabla de PostgreSQL |

**No son equivalencias perfectas en todos los casos:** por ejemplo, el tratamiento de `NULL`, los tipos de datos, el orden de ejecución y la gestión de memoria difieren.

---

## 25. Cómo organizar el proyecto y GitHub

Estructura de trabajo que hemos seguido:

```text
e-commerce-analytics/
├── data/
│   ├── raw/
│   │   └── Online Retail.xlsx
│   └── processed/
│       └── online_retail_ventas.csv
├── notebooks/
│   ├── 00_practica_pandas.ipynb
│   ├── 02_limpieza_de_datos.ipynb
│   ├── 03_exploracion_online_retail.ipynb
│   ├── 04_transformacion_online_retail.ipynb
│   └── 05_analisis_comercial.ipynb
├── sql/
│   ├── 01_consultas_basicas.sql
│   ├── 02_consultas_intermedias.sql
│   └── views.sql
├── dashboard/
├── reports/
├── Dockerfile
├── compose.yaml
├── README.md
└── .gitignore
```

**Notebooks `.ipynb`:** código, resultados y explicaciones de análisis interactivo.

**Archivos `.sql`:** consultas y definiciones reproducibles de objetos de la base de datos.

**Archivos `.md`:** documentación y conclusiones del proyecto.

**Dashboard:** presentación visual para comunicar resultados.

### Buenas prácticas

- **Reproducibilidad:** guardar las instrucciones que permiten repetir cada transformación.
- **Datos originales:** no modificar el archivo fuente.
- **Separación de carpetas:** distinguir datos sin procesar y preparados.
- **Código claro:** nombres de variables y columnas consistentes.
- **Documentación:** explicar reglas, KPI, resultados y limitaciones.
- **Git:** subir avances comprensibles, no generar cambios artificiales por volumen.
- **Seguridad:** ignorar `.env`, credenciales y archivos que no deban compartirse.

---

## 26. Errores frecuentes que hemos aprendido a resolver

### `FileNotFoundError` al leer un CSV

**Causa habitual:** el CSV todavía no se ha exportado o la ruta relativa es incorrecta.

```python
from pathlib import Path
import os

print(os.getcwd())
print(Path("../data/processed/online_retail_ventas.csv").exists())
```

**Solución:** ejecutar el notebook de transformación y guardar primero el CSV con `to_csv()`.

### Contar filas cuando se pide sumar cantidades

**Ejemplo:** `(df["Quantity"] < 0).sum()` cuenta registros negativos, mientras que `df["Quantity"].sum()` suma unidades.

### Calcular el importe medio por línea en lugar del ticket medio

**Error conceptual:** `mean()` sobre `ImporteLinea` no equivale a facturación dividida entre facturas únicas.

### Ordenar antes de agregar

**Incorrecto:** intentar `sort_values()` directamente sobre el objeto agrupado sin calcular primero su suma.

**Correcto:** `groupby()`, `sum()`, `sort_values()`, `head()`.

### Confundir Ubuntu con el prompt de PostgreSQL

**Error:** ejecutar `docker compose ...` dentro de `ecommerce=#`.

**Solución:** salir con `\q` y ejecutar Docker en la terminal de Ubuntu.

### Paginador de resultados en psql

**Síntoma:** aparece `(END)` al mostrar muchas filas.

**Solución:** pulsar `q` o desactivar el paginador con `\pset pager off`.

### Decimales excesivamente largos

**Causa posible:** las operaciones previas de coma flotante han introducido pequeñas aproximaciones.

**Para mostrar:** `ROUND(SUM(importe_linea), 2)`.

**Para datos financieros fiables:** revisar también la precisión utilizada desde la fuente y durante las transformaciones.

### Vistas que aparecen en el archivo pero no en la base de datos

**Causa:** crear `views.sql` no ejecuta su contenido.

**Solución:** ejecutar el archivo desde Ubuntu con `psql` y después verificar las vistas en PostgreSQL.

---

## 27. Glosario de conceptos

- **Análisis exploratorio (EDA):** inspección inicial para comprender el contenido y la calidad de los datos.
- **DataFrame:** tabla de datos en Pandas.
- **Series:** estructura unidimensional de Pandas.
- **Valor ausente:** dato que no está disponible (`NaN`, `None`, `NaT` o `NULL`, según el contexto).
- **Duplicado:** registro igual a otro según las columnas que se comparen.
- **Outlier:** valor atípico respecto a la distribución observada.
- **Granularidad:** qué representa exactamente una fila: línea, pedido, cliente, mes, etc.
- **Agregación:** cálculo que resume varios valores, como suma o media.
- **KPI:** indicador clave del negocio.
- **Facturación:** importe asociado a ventas, cuya definición depende de qué operaciones incluyamos.
- **Ticket medio:** importe de los pedidos dividido por el número de pedidos.
- **CTE:** resultado intermedio con nombre definido mediante `WITH`.
- **Función de ventana:** cálculo sobre una ventana de filas con `OVER()`.
- **JOIN:** combinación de filas de varias tablas según una condición.
- **Vista:** consulta guardada dentro de una base de datos.
- **DAX:** lenguaje de medidas y cálculos utilizado en Power BI.
- **ETL:** extracción, transformación y carga de datos.

---

## 28. Ruta de repaso recomendada

Para consolidar lo aprendido, conviene practicar en este orden:

1. **Pandas fundamental:** cargar datos, seleccionar columnas, filtrar y contar.
2. **Pandas analítico:** `groupby()`, agregaciones, fechas y KPI.
3. **Calidad:** ausentes, duplicados, cancelaciones y criterios de exclusión.
4. **SQL básico:** `SELECT`, `WHERE`, `GROUP BY`, agregaciones y `ORDER BY`.
5. **SQL intermedio:** `HAVING`, `CASE WHEN` y `JOIN`.
6. **SQL analítico:** CTE, funciones de ventana y vistas.
7. **Integración:** extraer con SQL, transformar con Python y presentar los resultados.

### Ejercicios que dejamos pendientes

**Lección 6 — Pandas:**

- **Producto con más unidades:** agrupar por `StockCode`, sumar `Quantity`, ordenar y seleccionar el primero.
- **Ticket medio por país:** combinar suma de importes y facturas distintas con `agg()`.

**Lección 8 — SQL:**

- **HAVING:** países con más de 500 facturas distintas.
- **CASE WHEN:** clasificar líneas por importe.
- **LEFT JOIN:** relacionar ventas y mercados.
- **INNER JOIN:** facturación de mercados incluidos en la tabla auxiliar.
- **Ticket medio de España:** calcular importe, facturas distintas y ratio.

### Qué debes saber explicar sin mirar apuntes

- **Fila frente a pedido:** una factura puede contener varias líneas.
- **`count()` frente a `nunique()`:** valores presentes frente a valores únicos.
- **`WHERE` frente a `HAVING`:** filtrar filas frente a filtrar grupos.
- **`GROUP BY` frente a `OVER()`:** resumir grupos frente a calcular manteniendo filas.
- **`INNER JOIN` frente a `LEFT JOIN`:** coincidencias exclusivamente frente a conservar la tabla izquierda.
- **`.copy()` frente a `=`:** copia independiente frente a referencia al mismo objeto.
- **Tabla frente a vista frente a archivo `.sql`:** datos persistidos, consulta persistida y código fuente.
- **Facturación frente a beneficio:** vender más no implica necesariamente obtener más margen.

---

## 29. Referencias y alcance

**Material principal:** teoría, ejemplos y ejercicios de las lecciones 1 a 9 del proyecto E-Commerce Analytics. La lección 10 introduce la conexión de las vistas con Power BI.

**Dataset:** UCI Machine Learning Repository, *Online Retail* — https://archive.ics.uci.edu/dataset/352/online+retail

**Documentación de consulta adicional:**

- Pandas: https://pandas.pydata.org/docs/
- PostgreSQL: https://www.postgresql.org/docs/
- Matplotlib: https://matplotlib.org/stable/
- Power BI: https://learn.microsoft.com/power-bi/

Este manual organiza los conceptos efectivamente introducidos durante el curso. Algunas advertencias técnicas y matices de precisión se han ampliado para evitar errores habituales al reutilizar el código en un proyecto profesional.
