# Manual de Power BI — E-Commerce Analytics

> **Nivel:** inicial a intermedio · **Proyecto:** E-Commerce Analytics · **Última revisión:** noviembre de 2026  
> **Entorno del proyecto:** Windows 11 + Power BI Desktop; WSL2 + Docker Desktop; PostgreSQL; Python y Pandas.  
> **Objetivo:** entender la teoría y disponer de una referencia práctica para crear, interpretar y mantener informes de análisis comercial.

---

## 1. Qué es Power BI y para qué sirve

**Power BI** es una plataforma de análisis de datos y *Business Intelligence* de Microsoft. Permite conectarse a diferentes orígenes, preparar datos, diseñar modelos analíticos, calcular indicadores y crear informes interactivos.

En una empresa, Power BI ayuda a responder preguntas como:

- **Ventas:** ¿cuánto hemos vendido este mes y cómo ha cambiado respecto al anterior?
- **Clientes:** ¿cuántos clientes compran y cuál es el gasto medio por pedido?
- **Productos:** ¿qué artículos generan más ingresos y cuáles tienen más unidades vendidas?
- **Geografía:** ¿qué países o regiones aportan mayor facturación?
- **Operaciones:** ¿qué indicadores requieren atención?

**Importante:** Power BI no sustituye a una base de datos. Puede conectarse a ella o importar una copia de los datos para analizarlos.

### Elementos principales del ecosistema

| Elemento | Función |
|---|---|
| **Power BI Desktop** | Aplicación de Windows para crear modelos e informes; permite guardar archivos `.pbix`. |
| **Power Query** | Preparación y transformación de datos antes de cargarlos al modelo. |
| **Modelo semántico** | Tablas, relaciones, medidas y reglas de análisis que utiliza un informe. |
| **DAX** | Lenguaje de expresiones para medidas, columnas calculadas y otros objetos del modelo. |
| **Power BI Service** | Servicio web para publicar, consultar, actualizar y compartir contenido, sujeto a permisos y licencias. |
| **Gateway** | Puente necesario en determinadas arquitecturas para acceder desde el servicio a orígenes privados o locales. |

## 2. Cómo encaja Power BI en nuestro proyecto

El flujo que estamos construyendo es:

```text
Online Retail.xlsx
       |
       v
Python + Pandas: inspección, limpieza y transformación
       |
       v
CSV procesado: online_retail_ventas.csv
       |
       v
PostgreSQL: tabla ventas_online_retail
       |
       v
Vistas SQL: vw_facturacion_mensual / vw_facturacion_pais
       |
       v
Power BI: modelo, medidas, gráficos e informe
```

**Pandas:** prepara datos y automatiza tareas complejas.  
**PostgreSQL:** conserva los registros de forma persistente y sirve consultas.  
**SQL:** selecciona y resume información.  
**Power BI:** modela, calcula y comunica resultados de manera interactiva.

No existe una única arquitectura correcta. Algunas organizaciones realizan la mayoría de las transformaciones en SQL y otras utilizan Power Query o procesos ETL externos.

## 3. Qué datos estamos analizando

Nuestro origen es el dataset histórico **Online Retail**, correspondiente a transacciones de una tienda online británica entre diciembre de 2010 y diciembre de 2011.

Después de aplicar las reglas provisionales de la Lección 5, trabajamos con **530.104 líneas** seleccionadas a partir de **541.909 registros originales**. Entre otras condiciones, excluimos facturas identificadas como cancelaciones, cantidades no positivas y precios no positivos.

Resultados registrados en nuestros análisis anteriores:

| Indicador | Resultado aproximado |
|---|---:|
| Importe bruto de líneas seleccionadas | 10.666.684,54 £ |
| Facturas distintas | 19.960 |
| Unidades vendidas | 5.588.376 |
| Facturación de Reino Unido | 9.025.222,08 £ |
| Mayor mes por facturación | Noviembre de 2011: 1.509.496,33 £ |

**Advertencia de interpretación:** no son ventas netas definitivas, beneficios ni datos actuales de una empresa en funcionamiento. El dataset contiene conceptos especiales que requieren revisión y el último mes está incompleto.

## 4. Los objetos que encontramos en Power BI Desktop

- **Cinta de opciones:** incluye acciones como *Obtener datos*, *Transformar datos*, *Nueva medida* y *Publicar*.
- **Lienzo de informe:** superficie donde colocamos gráficos, tarjetas, tablas y segmentadores.
- **Panel de datos/campos:** lista de tablas, columnas y medidas disponibles.
- **Panel de visualizaciones o experiencia de interacción en el objeto:** elección y formato de gráficos; la interfaz puede variar según la versión.
- **Vista de informe:** construcción de páginas visuales.
- **Vista de datos:** inspección de las tablas cargadas cuando está disponible para el modelo.
- **Vista de modelo:** relaciones entre tablas, dirección de filtro y cardinalidad.
- **Power Query Editor:** ventana independiente para transformar la información antes de cargarla.

**Archivo `.pbix`:** guarda el informe y su modelo; en modo Importación puede incorporar también datos importados. No debe tratarse como un archivo de texto ni publicarse automáticamente sin revisar la información incluida.

## 5. Diferencia entre informe, dashboard y modelo semántico

Aunque coloquialmente llamamos *dashboard* a cualquier página visual, en la terminología de Power BI conviene distinguir:

| Concepto | Significado |
|---|---|
| **Informe (report)** | Una o varias páginas interactivas con visualizaciones, creadas por ejemplo en Desktop. |
| **Dashboard** | Lienzo de una sola página del servicio Power BI donde pueden fijarse mosaicos de uno o varios informes. |
| **Modelo semántico** | Capa de datos y cálculos que alimenta los visuales. |
| **Página de informe** | Cada pestaña de un informe. |
| **Objeto visual** | Gráfico, tarjeta, tabla, matriz, segmentador, etc. |

En nuestro proyecto comenzaremos con una **página de informe de resumen comercial** y podremos describirla informalmente como dashboard.

## 6. Conectarse a datos desde Power BI

Power BI puede obtener datos de Excel, CSV, PostgreSQL, SQL Server, servicios web y otros orígenes.

### Conexión a nuestro PostgreSQL de Docker

**Antes de abrir Power BI:** arranca Docker Desktop en Windows y los servicios desde la terminal Ubuntu:

```bash
cd ~/proyectos/e-commerce-analytics
docker compose up -d
docker compose ps
```

En Power BI Desktop:

1. Ve a **Inicio > Obtener datos > PostgreSQL**; según versión, puede aparecer dentro de *Más...* o *Base de datos*.
2. Indica **Servidor:** `localhost:5432`.
3. Indica **Base de datos:** `ecommerce`.
4. Elige **Importar** para nuestro primer informe.
5. Utiliza autenticación **Base de datos**.
6. Introduce **usuario:** `ecommerce` y la contraseña definida en `POSTGRES_PASSWORD` dentro de `.env`.
7. Selecciona las vistas del esquema `public` en el navegador.
8. Pulsa **Cargar** o **Transformar datos** si necesitas revisar tipos y columnas.

**Por qué `localhost:5432`:** Power BI se ejecuta en Windows y Docker Desktop publica el puerto de PostgreSQL en el equipo. No debes utilizar `postgres` como servidor desde Power BI Desktop: ese nombre resuelve dentro de la red de Docker, no necesariamente en Windows.

**Seguridad:** no copies contraseñas reales al README, a capturas públicas ni al archivo `.md`. Comprueba la configuración de SSL según el servidor. En nuestro laboratorio local puede diferir de una conexión de producción.

### Verificación de las vistas

Desde `psql`:

```sql
\dv

SELECT *
FROM vw_facturacion_mensual
ORDER BY mes
LIMIT 5;

SELECT *
FROM vw_facturacion_pais
ORDER BY facturacion DESC
LIMIT 5;
```

Si no existen las vistas, debes ejecutar el archivo SQL que incluye `CREATE OR REPLACE VIEW`. Crear un archivo `.sql` **no crea automáticamente** las vistas en PostgreSQL.

## 7. Importar frente a DirectQuery

Son dos formas principales de obtener información desde una base de datos compatible.

| Característica | Importar | DirectQuery |
|---|---|---|
| **Dónde se consultan las visualizaciones** | Sobre una copia importada al modelo | Mediante consultas al origen, según funcionamiento del modelo |
| **Rendimiento** | Suele ser bueno para conjuntos adecuados al modelo | Depende también de red, consultas y capacidad del origen |
| **Actualidad** | Requiere actualizar los datos importados | Consulta el origen cuando necesita resultados; puede haber cachés |
| **Dependencia del origen** | No siempre se necesita para ver datos ya cargados | El origen debe estar disponible para responder |
| **Limitaciones** | Tamaño, memoria y actualización | Restricciones de modelado y rendimiento según conector |

**Para E-Commerce Analytics:** comenzamos en modo **Importar** porque nuestras vistas agregadas son pequeñas y la prioridad es aprender a crear un informe.

**Idea clave:** el modo Importar no sincroniza constantemente los datos. Si cambian las tablas o vistas PostgreSQL, debes **Actualizar** en Power BI para traer los cambios.

## 8. Power Query: preparar datos antes del modelo

**Power Query** es la herramienta de preparación y transformación integrada en Power BI. Permite modificar la representación de los datos sin alterar necesariamente las tablas originales de PostgreSQL.

Acceso: **Inicio > Transformar datos**.

Operaciones habituales:

- **Cambiar tipo de datos:** fecha, decimal, entero, texto, etc.
- **Quitar columnas:** reducir información innecesaria.
- **Filtrar filas:** seleccionar datos relevantes.
- **Reemplazar valores:** normalizar categorías.
- **Dividir columnas:** separar valores de texto.
- **Combinar consultas (Merge):** unir tablas por una clave.
- **Anexar consultas (Append):** poner filas de una tabla debajo de otra, con estructura compatible.
- **Agrupar por:** calcular sumas, conteos u otros resúmenes.
- **Quitar duplicados:** solo cuando exista justificación de negocio.
- **Cerrar y aplicar:** incorpora los cambios preparados al modelo.

### Pasos aplicados

Cada transformación suele registrarse como un paso en el panel de **Pasos aplicados**. Puedes revisarlo, cambiar su orden o eliminarlo.

Ejemplo conceptual:

```text
Origen PostgreSQL
  -> Elegir vista
  -> Convertir mes a Fecha
  -> Convertir facturacion a Número decimal
  -> Renombrar columnas si procede
  -> Cerrar y aplicar
```

**No confundas:** transformar datos en Power Query no significa modificar directamente los registros de PostgreSQL.

## 9. Lenguaje M frente a DAX

Power Query emplea el lenguaje **M**, mientras que las fórmulas del modelo analítico utilizan **DAX**.

| Aspecto | Power Query / M | DAX |
|---|---|---|
| **Momento principal** | Preparación y carga/actualización | Evaluación de cálculos en el modelo |
| **Uso típico** | Limpiar, convertir, combinar y estructurar | KPI, porcentajes, medidas y lógica dependiente de filtros |
| **Dónde lo vemos** | Editor de Power Query | Modelado > Nueva medida / columna |

Ejemplo ilustrativo en M:

```powerquery
= Table.TransformColumnTypes(Origen, {{"facturacion", type number}})
```

Ejemplo en DAX:

```dax
Facturación total =
SUM('vw_facturacion_mensual'[facturacion])
```

No hace falta aprender M a fondo para empezar: buena parte de Power Query se maneja desde la interfaz.

## 10. Conceptos esenciales de modelado de datos

Un **modelo de datos** organiza tablas y relaciones para que los gráficos filtren y calculen los indicadores correctamente.

### Granularidad (*grain*)

Es lo que representa **una fila** de una tabla.

- **`ventas_online_retail`:** normalmente, una línea de producto de una factura.
- **`vw_facturacion_mensual`:** un mes.
- **`vw_facturacion_pais`:** un país.

La granularidad importa porque determina qué cálculos son legítimos. Por ejemplo, no puedes deducir el gasto de cada cliente solo desde una vista agregada por mes.

### Tablas de hechos y dimensiones

**Tabla de hechos:** contiene operaciones o medidas cuantitativas, como importe, cantidad y número de pedido.

**Tabla de dimensiones:** ofrece categorías para filtrar y agrupar, como país, producto y calendario.

Diseño habitual en estrella:

```text
                dim_fecha
                    |
                    |
dim_pais ---- fact_ventas ---- dim_producto
                    |
                    |
                dim_cliente
```

Las tablas de dimensiones suelen contener identificadores únicos; la tabla de hechos contiene múltiples filas relacionadas con cada dimensión.

### Cardinalidad y filtros

- **Uno a muchos (1:*):** un país en `dim_pais` puede tener miles de líneas en `fact_ventas`.
- **Uno a uno (1:1):** cada clave se corresponde con una fila al otro lado.
- **Muchos a muchos (*:*):** ambos lados pueden tener claves repetidas; exige especial cuidado.
- **Dirección de filtro:** determina cómo viajan los filtros entre las tablas.

**Recomendación inicial:** favorecer relaciones 1:* desde dimensiones hacia hechos y evitar las bidireccionales salvo necesidad justificada.

## 11. Limitación actual de nuestras dos vistas

Actualmente hemos creado:

- **`vw_facturacion_mensual`:** `mes`, `facturacion`, `pedidos`, `unidades_vendidas`.
- **`vw_facturacion_pais`:** `pais`, `facturacion` (según la versión que hemos ejecutado).

Estas vistas están **agregadas a distintos niveles**. La primera no contiene país y la segunda no contiene mes.

**Consecuencia:** no podemos crear una relación correcta entre ellas que permita aplicar simultáneamente filtros de país y mes a todos los gráficos.

**Qué no hacer:** relacionarlas artificialmente o sumar ambos importes en una medida: representan la misma facturación resumida de dos maneras y duplicaríamos cifras.

**Solución futura:** importar la tabla de detalle `ventas_online_retail` y construir un modelo de hechos/dimensiones, o diseñar un resumen con las dimensiones que realmente necesita el informe.

## 12. Introducción a DAX

DAX significa **Data Analysis Expressions**. Es un lenguaje de fórmulas empleado en Power BI para definir cálculos dentro de un modelo semántico.

Los ejemplos de este manual utilizan una sintaxis con **comas** como separadores; según la configuración regional y la interfaz, puede que debas utilizar **punto y coma**.

### Medidas

Una **medida** calcula un resultado cuando el informe lo solicita y reacciona al contexto de filtros.

```dax
Facturación total =
SUM('vw_facturacion_mensual'[facturacion])
```

```dax
Unidades vendidas =
SUM('vw_facturacion_mensual'[unidades_vendidas])
```

Para añadirla: **Modelado > Nueva medida**. Después utiliza el nombre de la medida en los objetos visuales.

### Columnas calculadas

Una **columna calculada** añade un valor por fila a la tabla del modelo, calculado cuando corresponde al procesamiento/actualización del modelo, no dinámicamente para cada visual como una medida.

Ejemplo sobre la tabla de detalle si la has importado:

```dax
ImporteLineaCalculado =
'ventas_online_retail'[cantidad] * 'ventas_online_retail'[precio_unitario]
```

**Consejo:** si `importe_linea` ya viene correctamente calculado desde Pandas/SQL, no hace falta duplicarlo como columna DAX.

## 13. Diferencia entre medida y columna calculada

| Característica | Medida | Columna calculada |
|---|---|---|
| **Resultado** | Un valor calculado para el contexto actual | Un valor por fila |
| **Reacciona directamente al filtro de cada visual** | Sí | Sus valores están predefinidos; la visual puede agregarlos o filtrarlos |
| **Uso típico** | Facturación total, margen, ticket medio | Categoría de producto, etiqueta derivada |
| **Memoria** | No almacena los resultados de cada contexto | Añade una columna al modelo |

Para indicadores de negocio como **facturación total** y **ticket medio**, normalmente preferiremos **medidas**.

## 14. Funciones DAX básicas

| Función | Uso principal |
|---|---|
| `SUM()` | Suma una columna numérica. |
| `AVERAGE()` | Calcula la media de una columna. |
| `MIN()` / `MAX()` | Mínimo y máximo. |
| `COUNTROWS()` | Cuenta filas de una tabla. |
| `DISTINCTCOUNT()` | Cuenta valores distintos de una columna. |
| `DIVIDE()` | Divide con gestión del denominador cero. |
| `CALCULATE()` | Evalúa una expresión en un contexto de filtro modificado. |
| `SUMX()` | Evalúa una expresión fila a fila y suma sus resultados. |
| `SELECTEDVALUE()` | Devuelve un único valor seleccionado o alternativa. |
| `COALESCE()` | Devuelve el primer valor no vacío entre expresiones. |

### Ejemplos sobre nuestra tabla de detalle

Los ejemplos siguientes **requieren cargar `ventas_online_retail` en Power BI**, no solo las dos vistas agregadas.

```dax
Facturación detalle =
SUM('ventas_online_retail'[importe_linea])
```

```dax
Pedidos únicos =
DISTINCTCOUNT('ventas_online_retail'[invoice_no])
```

```dax
Unidades =
SUM('ventas_online_retail'[cantidad])
```

```dax
Ticket medio =
DIVIDE([Facturación detalle], [Pedidos únicos])
```

**No confundas ticket medio con importe medio por línea.** `AVERAGE(importe_linea)` responde otra pregunta.

### Porcentaje de la facturación de un país

Cuando la dimensión de país está disponible en el mismo modelo y se filtra desde `ventas_online_retail`:

```dax
% Facturación del total =
DIVIDE(
    [Facturación detalle],
    CALCULATE(
        [Facturación detalle],
        REMOVEFILTERS('ventas_online_retail'[pais])
    )
)
```

Esta medida quita el filtro de país, **pero mantiene otros filtros** que puedan existir, como fechas o productos. Por eso hay que comprobar siempre qué denominador queremos utilizar.

## 15. El contexto de filtro

El **contexto de filtro** es el conjunto de restricciones que actúan sobre un cálculo DAX en un momento determinado.

Ejemplo:

- Una tarjeta sin filtros muestra la facturación de todas las filas seleccionadas.
- Un segmentador de país configurado en `Spain` hace que esa medida use únicamente las ventas españolas, **si el modelo dispone de relaciones adecuadas**.
- Un filtro de año en `2011` limita la medida a ese periodo.

El mismo código DAX puede producir valores distintos en diferentes visuales debido al contexto de filtro.

**Idea clave:** en DAX no basta con preguntar *qué fórmula usa*, también debes preguntar *sobre qué datos se está evaluando*.

## 16. CALCULATE y DIVIDE

**`CALCULATE()`** evalúa una expresión con filtros adicionales o modificados.

Ejemplo con tabla de detalle:

```dax
Facturación España =
CALCULATE(
    [Facturación detalle],
    'ventas_online_retail'[pais] = "Spain"
)
```

**`DIVIDE()`** es preferible a la división directa cuando el denominador podría ser cero:

```dax
Ticket medio =
DIVIDE([Facturación detalle], [Pedidos únicos], BLANK())
```

**`BLANK()`** significa ausencia de resultado en DAX y no equivale automáticamente a cero.

## 17. Diferencia entre SUM y SUMX

**`SUM(columna)`** agrega una columna numérica ya existente.

**`SUMX(tabla, expresión)`** evalúa una fórmula sobre cada fila y suma los resultados.

Ejemplo sobre la tabla de detalle:

```dax
Facturación calculada =
SUMX(
    'ventas_online_retail',
    'ventas_online_retail'[cantidad] * 'ventas_online_retail'[precio_unitario]
)
```

Esto es útil cuando no tenemos una columna de importe precomputada, pero debe comprobarse que los tipos de datos y el conjunto de filas son los adecuados.

## 18. KPI comerciales para E-Commerce Analytics

| Indicador | Fórmula conceptual | Precaución |
|---|---|---|
| **Facturación bruta seleccionada** | Suma de `importe_linea` | No equivale necesariamente a facturación neta. |
| **Facturas distintas** | Recuento único de `invoice_no` | Una factura puede contener varias líneas. |
| **Ticket medio** | Facturación / facturas únicas | No usar media de líneas. |
| **Unidades vendidas** | Suma de `cantidad` | Distinguir ventas, devoluciones y ajustes. |
| **Clientes identificados** | Recuento único de `customer_id` | Los valores ausentes deben tratarse explícitamente. |
| **Participación por país** | Facturación país / facturación total | Comprobar qué filtros afectan al denominador. |
| **Crecimiento mensual** | (Mes actual - anterior) / anterior | Los meses incompletos pueden engañar. |

**Precaución:** el dataset incluye códigos especiales como `POST` y `DOT`. No deben describirse indiscriminadamente como *productos físicos más vendidos*.

## 19. Configurar visualizaciones básicas

### Tarjeta (*Card*)

**Uso:** presentar un único KPI importante.

- Insertar una tarjeta.
- Asignar la medida de facturación o unidades.
- Aplicar formato numérico: £, decimales y unidades de visualización coherentes.
- Añadir un título que indique exactamente qué se está midiendo.

### Gráfico de líneas

**Uso:** visualizar la evolución temporal.

Para `vw_facturacion_mensual`:

- **Eje X:** `mes`.
- **Eje Y:** `facturacion`.
- **Título:** *Evolución mensual de la facturación*.
- **Orden:** ascendente por fecha.

Si la herramienta selecciona automáticamente una jerarquía de fechas, revisa que el eje represente el **mes-año** completo, no solo el número de mes.

### Gráfico de barras horizontales

**Uso:** comparar países o categorías.

Para `vw_facturacion_pais`:

- **Eje de categorías:** `pais`.
- **Valores:** `facturacion`.
- **Orden:** descendente.
- **Filtro opcional:** Top 10 por facturación.

### Tabla y matriz

- **Tabla:** listado con columnas y valores.
- **Matriz:** comparación multidimensional con agrupaciones de filas y columnas.

### Segmentador (*Slicer*)

**Uso:** permitir que el usuario filtre los datos por país, año, producto u otra dimensión.

**Requisito:** las relaciones y granularidad deben ser coherentes. Un slicer no podrá filtrar correctamente una vista mensual si esa vista no contiene país ni una relación que permita aplicar ese filtro.

## 20. Interacciones entre objetos visuales

Los visuales pueden influir unos sobre otros al seleccionar elementos de un gráfico o usar filtros.

Funciones habituales:

- **Filtrar:** limita los datos mostrados por otro visual.
- **Resaltar:** destaca una parte de los resultados manteniendo una referencia del total.
- **No interactuar:** evita que un visual afecte a otro.

Estas interacciones se configuran desde las opciones de **Editar interacciones**, si están disponibles en la versión utilizada.

**No des por hecho** que una selección filtra todos los objetos: compruébalo con datos reales y revisa las relaciones del modelo.

## 21. Filtros de visual, página e informe

- **Nivel de visual:** afecta únicamente a un objeto visual.
- **Nivel de página:** afecta a los visuales de una página.
- **Nivel de informe:** afecta a varias páginas del informe.
- **Segmentador:** filtro interactivo elegido por el usuario dentro del informe.

Ejemplo: podríamos limitar el gráfico de países al Top 10, pero mantener la tarjeta de facturación con el total completo. Esto requiere elegir correctamente el ámbito del filtro.

## 22. Crear una página de resumen comercial

Propuesta inicial de diseño para nuestro portfolio:

```text
+--------------------------------------------------------+
| E-COMMERCE ANALYTICS | Periodo: 2010-2011             |
+-----------------------+----------------+---------------+
| Facturación (£)       | Facturas       | Unidades      |
+-----------------------+----------------+---------------+
| Evolución mensual de la facturación                    |
| [línea temporal]                                       |
+--------------------------------+-----------------------+
| Facturación por país           | Indicadores y notas   |
| [barras horizontales]          | metodológicas         |
+--------------------------------+-----------------------+
| Fuente, fecha, reglas de limpieza y limitaciones        |
+--------------------------------------------------------+
```

### Criterios de diseño

- **Jerarquía visual:** primero los KPI, después tendencias y comparativas.
- **Coherencia:** misma moneda, periodos y formatos en todos los visuales.
- **Color:** usarlo para comunicar significado, no para decorar en exceso.
- **Etiquetas:** incluir unidades y títulos informativos.
- **Accesibilidad:** contraste suficiente, tamaño legible y alternativa textual cuando sea necesaria.
- **Contexto:** señalar que es un dataset histórico y que diciembre de 2011 es incompleto.
- **Transparencia:** indicar que el importe es bruto y está calculado sobre las líneas seleccionadas.

## 23. Importancia de los formatos numéricos

Los números deben verse de forma comprensible:

- **Moneda:** `£1.509.496,33` o abreviado `£1,51 M`, según la configuración regional.
- **Unidades:** `754.507`.
- **Porcentaje:** `84,61 %`.
- **Fecha:** `noviembre 2011` en lugar de una fecha/hora con precisión innecesaria.

### Redondear en SQL

```sql
SELECT
    mes,
    ROUND(facturacion, 2) AS facturacion
FROM vw_facturacion_mensual
ORDER BY mes;
```

Si queremos redondear dentro de la definición de la vista:

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

**Nota:** redondear para visualización no sustituye a comprobar la precisión de los datos originales. En nuestro caso, algunos decimales largos procedían de la representación numérica de importes en el flujo anterior.

## 24. Power BI frente a SQL y Pandas

| Necesidad | Herramienta recomendada inicialmente |
|---|---|
| Limpiar diez Excel con formatos diferentes | Python + Pandas o Power Query |
| Conservar datos y gestionar acceso multiusuario | PostgreSQL |
| Consultar millones de registros en el origen | SQL en la base de datos |
| Crear resúmenes reutilizables | Vistas SQL |
| Relacionar tablas en un modelo analítico | Power BI, con modelo de datos adecuado |
| Calcular KPI que respondan a filtros | Medidas DAX |
| Diseñar gráficos interactivos | Power BI |
| Entrenar modelos predictivos | Python y bibliotecas de ciencia de datos |

**Regla práctica:** intenta transformar cada dato una sola vez en la capa más apropiada y evita mantener versiones contradictorias del mismo KPI entre Python, SQL y Power BI.

## 25. Actualización de datos

### Power BI Desktop en modo Importar

1. PostgreSQL debe estar accesible para refrescar el origen.
2. Pulsa **Actualizar** en Desktop.
3. Power BI vuelve a consultar los orígenes conforme a la definición del modelo.
4. Los gráficos muestran los datos de la nueva actualización.
5. Guarda el `.pbix` si deseas conservar el estado local del archivo.

### Power BI Service

Si publicamos un informe en el servicio y el origen está en un equipo privado o accesible solo localmente, **normalmente necesitaremos configurar una puerta de enlace (gateway)** y credenciales para actualizarlo desde el servicio.

**Importante:** `localhost` tiene sentido desde el propio Windows que ejecuta PostgreSQL/Docker. Para un servicio o gateway situado en otro equipo, `localhost` identifica ese otro equipo; habrá que diseñar una conexión accesible desde allí.

La capacidad de compartir, actualizar y acceder a contenido depende de la configuración del tenant, del espacio de trabajo y de las licencias correspondientes. Consulta la documentación actual de Microsoft antes de publicar.

## 26. Publicación y colaboración

Secuencia habitual:

1. Crear y probar el informe en Power BI Desktop.
2. Guardar el archivo `.pbix`.
3. Seleccionar **Publicar**, si tienes acceso al servicio y permisos adecuados.
4. Elegir el espacio de trabajo autorizado.
5. Revisar las credenciales del origen y la actualización.
6. Compartir únicamente con personas y permisos apropiados.

**Nunca publiques información privada sin autorización.** Para un portfolio, revisa el contenido incorporado en el `.pbix`; incluso en modo Importación pueden guardarse registros detallados que no quieres distribuir.

## 27. Errores frecuentes y cómo resolverlos

### Error: Power BI no conecta con PostgreSQL

Comprueba:

- **Docker Desktop:** ¿está iniciado?
- **Contenedor:** ¿`docker compose ps` muestra PostgreSQL activo y saludable?
- **Puerto:** ¿el servicio está publicado en `localhost:5432`?
- **Base de datos:** ¿`ecommerce`?
- **Credenciales:** ¿usuario `ecommerce` y contraseña correcta de `.env`?
- **Conector:** ¿la versión actual de Power BI dispone de los componentes necesarios para PostgreSQL?
- **SSL/cifrado:** ¿el servidor y la configuración del conector están alineados?

Desde Ubuntu:

```bash
docker compose ps
docker compose exec postgres psql -U ecommerce -d ecommerce
```

### Error: no aparecen nuestras vistas

Verifica en `psql`:

```sql
\dv
```

**Posible causa:** se escribió `views.sql`, pero no se ejecutó en PostgreSQL. El archivo guarda el código; la vista reside en la base de datos una vez creada.

### Error: el gráfico mensual está desordenado

Comprueba que `mes` tiene tipo Fecha y que el gráfico se ordena cronológicamente. Si usas nombres de meses sin año, puedes mezclarlos incorrectamente.

### Error: aparece una jerarquía de fecha inesperada

Selecciona el campo `mes` como fecha directa cuando quieras ver meses completos, o configura una tabla calendario apropiada.

### Error: un filtro por país no modifica los gráficos mensuales

Nuestras dos vistas están agregadas por dimensiones distintas. Sin un modelo que conecte apropiadamente países y meses a los hechos, **no existe información suficiente para filtrar todos los resultados simultáneamente**.

### Error: los KPI se duplican

Comprueba si estás sumando dos vistas que ya contienen la misma información a distinta granularidad o si una relación produce multiplicación de filas.

### Error: los totales no coinciden con SQL

Comprueba:

- Si la vista y el informe utilizan **el mismo conjunto de registros**.
- Si se excluyeron cancelaciones, ajustes o importes no positivos.
- Si las medidas dependen de filtros de página o informe.
- Si se está calculando **facturación bruta** o **neta**.
- Si se han sumado importes previamente redondeados.
- Si la actualización de Power BI es posterior al último cambio en PostgreSQL.

## 28. Lista de verificación para nuestro primer informe

- [ ] Docker Desktop y PostgreSQL están disponibles.
- [ ] Existen `vw_facturacion_mensual` y `vw_facturacion_pais`.
- [ ] Ambas vistas devuelven resultados válidos en SQL.
- [ ] Power BI Desktop se conecta a `localhost:5432`, base `ecommerce`.
- [ ] Las vistas se cargan en modo Importación.
- [ ] `mes` se interpreta como fecha.
- [ ] `facturacion` se interpreta como número decimal.
- [ ] Existe una tarjeta de facturación total.
- [ ] Existe una tarjeta de unidades vendidas.
- [ ] Existe un gráfico de líneas mensual, ordenado cronológicamente.
- [ ] Existe un gráfico de barras por país.
- [ ] Los resultados coinciden con PostgreSQL, respetando filtros y redondeos.
- [ ] El informe explica sus limitaciones metodológicas.
- [ ] El `.pbix` se guarda en `dashboard/` y se revisa antes de compartir.

## 29. Próximo paso: un modelo de datos mejor

Para que el informe pueda responder correctamente a preguntas como **«¿cuánto facturó España en marzo de 2011?»**, necesitaremos una fuente que preserve ambas dimensiones al mismo tiempo.

Opción recomendada para aprender modelado:

1. Incorporar en Power BI la tabla de detalle `ventas_online_retail`.
2. Definir claramente la granularidad: una línea de factura.
3. Construir una dimensión de fechas con una fila por día y una columna de fecha sin hora en la tabla de hechos.
4. Construir dimensiones de país y, cuando el catálogo esté validado, de producto.
5. Crear relaciones correctas de 1 a muchos.
6. Definir medidas DAX sobre la **tabla de hechos**, evitando duplicar la facturación de las vistas resumen.
7. Construir segmentadores por país y periodo y validar los filtros cruzados.

Las vistas agregadas actuales siguen siendo útiles para comprobar resultados y elaborar un primer informe sencillo, pero no sustituyen a un modelo analítico bien diseñado.

## 30. Glosario rápido

- **Business Intelligence (BI):** utilización de datos para apoyar decisiones de negocio.
- **Dashboard:** panel visual de seguimiento de indicadores; en Power BI Service tiene además un significado específico.
- **DAX:** lenguaje de expresiones del modelo semántico.
- **ETL:** extracción, transformación y carga de datos.
- **Filtro cruzado:** propagación de filtros entre elementos o tablas relacionados.
- **Gateway:** componente que conecta el servicio con determinados orígenes privados.
- **Granularidad:** significado de una fila de una tabla.
- **Importar:** copiar datos al modelo para consultarlos desde él.
- **DirectQuery:** consultar el origen al necesitar resultados, con las particularidades del conector.
- **KPI:** indicador clave de rendimiento.
- **Medida:** cálculo DAX evaluado según el contexto de filtros.
- **Modelo semántico:** estructura de tablas, relaciones y cálculos.
- **Power Query:** editor de preparación y transformación de datos.
- **Query folding:** posibilidad de trasladar al origen algunas transformaciones de Power Query.
- **Relación 1:*:** una fila de dimensión puede relacionarse con muchas filas de hechos.
- **Segmentador:** filtro interactivo en el informe.
- **Tabla de dimensiones:** conjunto de entidades o categorías para segmentar los hechos.
- **Tabla de hechos:** conjunto de operaciones o eventos cuantificables.
- **Vista SQL:** consulta almacenada en la base de datos y accesible por nombre.

## 31. Bibliografía y documentación oficial

Las explicaciones recogen lo trabajado en nuestras lecciones y se amplían con conceptos de la documentación pública de Microsoft. Algunas pantallas y opciones pueden cambiar con las actualizaciones de Power BI.

- [Microsoft Learn — Introducción a Power BI Desktop](https://learn.microsoft.com/es-es/power-bi/fundamentals/desktop-getting-started)
- [Microsoft Learn — Conector PostgreSQL de Power Query](https://learn.microsoft.com/es-es/power-query/connectors/postgresql)
- [Microsoft Learn — Medidas en Power BI Desktop](https://learn.microsoft.com/es-es/power-bi/transform-model/desktop-measures)
- [Microsoft Learn — Relaciones de modelo en Power BI Desktop](https://learn.microsoft.com/es-es/power-bi/transform-model/desktop-relationships-understand)
- [Microsoft Learn — Esquema en estrella en Power BI](https://learn.microsoft.com/es-es/power-bi/guidance/star-schema)
- [Microsoft Learn — Guía de Power BI](https://learn.microsoft.com/es-es/power-bi/guidance)
- [UCI Machine Learning Repository — Online Retail](https://archive.ics.uci.edu/dataset/352/online+retail)

---

## 32. Recomendación para el repositorio

Guarda este documento en:

```text
e-commerce-analytics/
├── docs/
│   ├── Manual_Pandas_SQL_Ecommerce_Analytics.md
│   └── Manual_Power_BI_Ecommerce_Analytics.md
├── dashboard/
│   └── ecommerce_dashboard.pbix
├── notebooks/
├── sql/
└── README.md
```

**Prioridad del proyecto:** terminar la conexión con PostgreSQL, crear un informe básico verificable y después diseñar un modelo de datos con dimensiones, relaciones y medidas DAX. El objetivo no es memorizar todos los menús, sino comprender **de dónde vienen los datos, qué calcula cada indicador y qué filtros pueden modificarlo**.
