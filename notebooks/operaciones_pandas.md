# OPERACIONES PANDAS
```
pd.DataFrame(diccionario)
```
transforma un diccionario en una tabla, lo suyo es insertar el resultado en una variable y luego mostrar la variable:
```python
import pandas as pd

# Datos de ejemplo de nuestra tienda
ventas = {
    "Pedido": [1001, 1002, 1003, 1004, 1005, 1006],
    "Producto": ["Teclado", "Ratón", "Monitor",
                 "Ratón", "Teclado", "Auriculares"],
    "Cantidad": [2, 3, 1, 1, 1, 2],
    "Precio": [25, 15, 180, 15, 25, 45],
    "Pais": ["España", "España", "Francia",
             "España", "Portugal", "Francia"]
}

df = pd.DataFrame(ventas)

df
```
el resultado que muestra seria este:
```
Pedido 	Producto 	Cantidad 	Precio 	Pais
0 	1001 	Teclado 	2 	    25 	España
1 	1002 	Ratón 	    3 	    15 	España
2 	1003 	Monitor 	1 	    180 Francia
3 	1004 	Ratón 	    1 	    15 	España
4 	1005 	Teclado 	1 	    25 	Portugal
5 	1006 	Auriculares 2 	    45 	Francia
```
otras operaciones utiles:
 - `df.head()`: muestra las 5 primeras filas del dataframe, si insertamos un numero en el parentesis podemos determinar cuantas filas mostrar, por ejemplo `df.head(3)` mostraria las 3 primeras filas.
 - `df.shape`: se usa para conocer las dimensiones de una tabla, el resultado seria `(6, 5)`, 6 filas 5 columnas.
 - `df.dtypes`: permite saber si una columna contiene números enteros, decimales, texto, etc.
 ```
Pedido       int64
Producto    object
Cantidad     int64
Precio       int64
Pais        object
dtype: object
 ```
 - `df["Producto"]`: devuelve únicamente los nombres de los productos
 ```
0        Teclado
1          Ratón
2        Monitor
3          Ratón
4        Teclado
5    Auriculares
Name: Producto, dtype: object
 ```

Podemos añadir una nueva columna despues de generar la tabla, por ejemplo vamos a añadir una columna "facturación":
```
df["Facturación"] = df["Precio"] * df["Cantidad"]

df

#Resultado:
 	Pedido 	Producto 	Cantidad 	Precio 	Pais 	 Facturación
0 	1001 	Teclado 	2 	        25 	    España 	 50
1 	1002 	Ratón 	    3 	        15 	    España 	 45
2 	1003 	Monitor 	1 	        180 	Francia  180
3 	1004 	Ratón 	    1 	        15 	    España 	 15
4 	1005 	Teclado 	1 	        25 	    Portugal 25
5 	1006 	Auriculares 2 	        45 	    Francia  90
```
Como se puede observar no tenemos que utilizar un bucle for para hacer la multiplicacion por filas, pandas puede realizar estas multiplicaciones automaticamente. Esto se conoce como una operación vectorizada. Ahora calculamos cuanto ha facturado la tienda en total:
```
facturacion_total = df["Facturación"].sum()

print(f"Facturación total: {facturacion_total} €")

#Resultado: Facturación total: 405 €
```
## FILTRAR DATOS EN PANDAS
¿Que ventas generan mas de 50€?
```
ventas_superiores_50 = df[df["Facturación"] > 50]

ventas_superiores_50

#Resultado:
        Pedido 	Producto 	Cantidad 	Precio 	Pais 	    Facturación
2 	    1003 	Monitor 	1 	        180 	Francia 	180
5 	    1006 	Auriculares 2 	        45 	    Francia 	90
```
Primero se evalúa `df["Facturación"] > 50`. Esto produce una Serie de valores booleanos, es decir, True y False.
Pedido	Facturación	¿Mayor que 50?
1001	50 €	    False
1002	45 €	    False
1003	180 €	    True
1004	15 €	    False
1005	25 €	    False
1006	90 €	    True

Si queremos filtrar por texto:
```
ventas_espana = df[df["Pais"] == "España"]

ventas_espana
```
Obtendremos tres registros: los pedidos 1001, 1002 y 1004. Pero lo que queremos conocer realmente es cuánto hemos facturado en España. Podemos combinar el filtro anterior con .sum():
```
facturacion_espana = ventas_espana["Facturación"].sum()

print(f"Facturación en España: {facturacion_espana} €")

#Resultado: Facturación en España: 110 €
```
Supongamos que ahora queremos encontrar los pedidos realizados en España donde se hayan vendido al menos dos unidades. Necesitamos dos condiciones:
```
filtro = (df["Pais"] == "España") & (df["Cantidad"] >= 2)

df[filtro]
```
El resultado serán los pedidos 1001 y 1002. En Pandas utilizaremos estos operadores para combinar condiciones:
 - &	Y: ambas condiciones deben cumplirse
 - \|	O: basta con que se cumpla una
 - ~	NO: invierte una condición

¿Cuáles han sido nuestras ventas de mayor importe? Para responder utilizamos sort_values().
```
ventas_ordenadas = df.sort_values(
    by="Facturación",
    ascending=False
)

ventas_ordenadas
```

Ahora vamos a dar un salto importante. Agruparemos información con groupby(). Hasta aquí hemos analizado ventas individuales, pero una empresa suele querer conocer información agregada. Por ejemplo: ¿Qué producto ha generado más facturación acumulada? Tenemos varios pedidos de teclados y ratones. Necesitamos sumar su facturación por producto.
```
facturacion_productos = df.groupby("Producto")["Facturación"].sum()

facturacion_productos
```
Y podemos ordenar ese resultado:
```
facturacion_productos = facturacion_productos.sort_values(
    ascending=False
)

facturacion_productos
```
Observa la diferencia: anteriormente el teclado aparecía en dos ventas distintas, mientras que ahora hemos sumado ambas para obtener 75 €. Esto es precisamente lo que queremos hacer con nuestro dataset real, pero con miles de operaciones comerciales.

Ahora vamos a detectar valores ausentes. En los datos reales encontraremos registros incompletos. Por ejemplo, un cliente puede no tener identificado su país o su código de cliente. Pandas nos permite localizar estos problemas:
```
df.isna().sum()
```
isna() comprueba qué valores están ausentes y .sum() cuenta cuántos faltan en cada columna. En nuestro DataFrame actual deberían aparecer cero valores ausentes en todas las columnas. Más adelante aprenderemos a decidir si conviene eliminar, conservar o completar esos registros. No siempre es correcto eliminarlos.

## Limpieza y calidad de datos
```
import pandas as pd

ventas = {
    "Pedido": [1001, 1002, 1003, 1004, 1005, 1005, 1006, 1007, 1008],
    "Producto": [
        "Teclado", "Ratón", "Monitor", "Ratón",
        "Teclado", "Teclado", "Auriculares",
        "Webcam", "Cable USB"
    ],
    "Cantidad": [2, 3, 1, -1, 1, 1, 2, 0, 1],
    "Precio": [25, 15, 180, 15, 25, 25, 45, 60, None],
    "Pais": [
        "España", "España", "Francia", "España",
        "Portugal", "Portugal", None,
        "España", "Francia"
    ]
}

df_sucio = pd.DataFrame(ventas)

df_sucio

#Resultado:
Pedido	Producto	Cantidad	Precio	Pais
1001	Teclado	    2	        25	    España
1002	Ratón	    3	        15	    España
1003	Monitor	    1	        180	    Francia
1004	Ratón	    -1	        15	    España
1005	Teclado	    1	        25	    Portugal
1005	Teclado	    1	        25	    Portugal
1006	Auriculares	2	        45	    None
1007	Webcam	    0	        60	    España
1008	Cable USB	1	        NaN	    Francia
```
Fijate en los errores:
 - Dos filas idénticas con el pedido 1005.
 - Un cliente sin país identificado.
 - Un producto sin precio.
 - Una cantidad negativa.
 - Una cantidad igual a cero.
No todos tienen por qué ser errores, pero todos merecen una revisión.

#### Detectar valores ausentes con isna()
Un valor ausente es un dato que no se encuentra disponible. Pandas utiliza representaciones como NaN, None o pd.NA para expresar información ausente, dependiendo del tipo de dato. Primer método: isna():
```
df_sucio.isna()

#Resultado
    Pedido 	Producto 	Cantidad 	Precio 	Pais
0 	False 	False 	    False 	    False 	False
1 	False 	False 	    False 	    False 	False
2 	False 	False 	    False 	    False 	False
3 	False 	False 	    False 	    False 	False
4 	False 	False 	    False 	    False 	False
5 	False 	False 	    False 	    False 	False
6 	False 	False 	    False 	    False 	True
7 	False 	False 	    False 	    False 	False
8 	False 	False 	    False 	    True 	False
```
Este método devuelve un DataFrame con valores booleanos.
- True: el dato está ausente.
- False: el dato está presente.
Pero con miles de filas no sería práctico revisar todos esos resultados manualmente. Por eso normalmente combinamos isna() con sum():
```
df_sucio.isna().sum()

#Resultado
Pedido      0
Producto    0
Cantidad    0
Precio      1
Pais        1
dtype: int64
```
¿Por qué funciona .sum()? Porque al sumar valores booleanos, Pandas puede contar los True como 1 y los False como 0. Por tanto, obtenemos cuántos valores faltan en cada columna.

#### Eliminar o sustituir valores ausentes
Tenemos dos posibilidades, aunque la decisión depende del significado de los datos.
 - Opción A. Eliminar registros. Podemos eliminar filas que tengan un precio ausente:
```
ventas_con_precio = df_sucio.dropna(subset=["Precio"])

ventas_con_precio

# Resultado
    Pedido 	Producto 	Cantidad 	Precio 	Pais
0 	1001 	Teclado 	2 	        25.0 	España
1 	1002 	Ratón 	    3 	        15.0 	España
2 	1003 	Monitor 	1 	        180.0 	Francia
3 	1004 	Ratón 	    -1 	        15.0 	España
4 	1005 	Teclado 	1 	        25.0 	Portugal
5 	1005 	Teclado 	1 	        25.0 	Portugal
6 	1006 	Auriculares 2 	        45.0 	None
7 	1007 	Webcam 	    0 	        60.0 	España
```
Aquí estamos indicando que queremos excluir las filas cuyo valor Precio sea nulo. Observa que no hemos eliminado filas por tener otros campos ausentes.

 - Opción B. Sustituir valores ausentes. Podemos crear una copia y marcar los países desconocidos:
```
ventas_revisadas = df_sucio.copy()

ventas_revisadas["Pais"] = ventas_revisadas["Pais"].fillna("Desconocido")

ventas_revisadas

# Resultado
 	Pedido 	Producto 	Cantidad 	Precio 	Pais
0 	1001 	Teclado 	2 	        25.0 	España
1 	1002 	Ratón 	    3 	        15.0 	España
2 	1003 	Monitor 	1 	        180.0 	Francia
3 	1004 	Ratón 	    -1 	        15.0 	España
4 	1005 	Teclado 	1 	        25.0 	Portugal
5 	1005 	Teclado 	1 	        25.0 	Portugal
6 	1006 	Auriculares 2 	        45.0 	Desconocido
7 	1007 	Webcam 	    0 	        60.0 	España
8 	1008 	Cable USB 	1 	        NaN 	Francia
```
Ahora el pedido 1006 tendrá el país Desconocido. Esto es diferente de inventar que el cliente pertenece a España o Francia.

Una regla importante: no sustituyas automáticamente un precio desconocido por cero. Un precio no registrado y un producto gratuito no significan lo mismo.

#### Detectar registros duplicados
Imagina que una tienda registra accidentalmente la misma transacción dos veces. Si sumamos ambas, podríamos estar sobreestimando la facturación. Para buscar filas idénticas, utilizamos:
```
df_sucio.duplicated()

# Resultado
0    False
1    False
2    False
3    False
4    False
5     True
6    False
7    False
8    False
dtype: bool
```
Obtendremos una Serie booleana que identifica las repeticiones, marcando por defecto las apariciones posteriores a la primera. Para contar cuántas filas repetidas detectamos:
```
df_sucio.duplicated().sum()

# Resultado: np.int64(1)
```
Y para mostrar todas las filas involucradas en esa duplicación:
```
df_sucio[df_sucio.duplicated(keep=False)]

# Resultado
 	Pedido 	Producto 	Cantidad 	Precio 	Pais
4 	1005 	Teclado 	1 	        25.0 	Portugal
5 	1005 	Teclado 	1 	        25.0 	Portugal
```
Aparecerán las dos filas del pedido 1005.

#### ¿Cómo eliminar duplicados?
```
df_sin_duplicados = df_sucio.drop_duplicates()

df_sin_duplicados

# Resultado
    Pedido 	Producto 	Cantidad 	Precio 	Pais
0 	1001 	Teclado 	2 	        25.0 	España
1 	1002 	Ratón 	    3 	        15.0 	España
2 	1003 	Monitor 	1 	        180.0 	Francia
3 	1004 	Ratón 	    -1 	        15.0 	España
4 	1005 	Teclado 	1 	        25.0 	Portugal
6 	1006 	Auriculares 2 	        45.0 	None
7 	1007 	Webcam  	0 	        60.0 	España
8 	1008 	Cable USB 	1 	        NaN 	Francia
```
Conservamos ocho filas en lugar de nueve. Pero hay una advertencia importante: dos filas idénticas no siempre significan que una sea un error.

Un cliente podría haber comprado dos unidades idénticas registradas en líneas diferentes. Antes de eliminar una fila en un proyecto real, necesitamos comprender cómo registra las operaciones la empresa. Por ahora estamos practicando la herramienta, no afirmando que uno de los dos registros sea necesariamente incorrecto.

#### Detectar valores sospechosos
Aquí encontramos algo especialmente interesante. El pedido 1004 tiene una cantidad negativa y el 1007 tiene una cantidad igual a cero. Podemos identificarlos mediante filtros:
```
ventas_sospechosas = df_sucio[
    df_sucio["Cantidad"] <= 0
]

ventas_sospechosas

# Resultado
 	Pedido 	Producto 	Cantidad 	Precio 	Pais
3 	1004 	Ratón 	    -1 	        15.0 	España
7 	1007 	Webcam 	    0 	        60.0 	España
```
¿Debemos eliminarlos? No necesariamente.

Una cantidad negativa puede representar una devolución o cancelación. Una cantidad cero puede reflejar un registro pendiente, una operación incorrecta u otro evento comercial. De hecho, cuando trabajemos con nuestro dataset real de Online Retail, encontraremos transacciones que requieren distinguir ventas y cancelaciones. Por eso un analista debe investigar el significado de los valores antes de decidir cómo tratarlos.

#### Examinar los tipos de datos
Finalmente, vamos a inspeccionar la estructura de nuestra tabla:
```python
df_sucio.info()

# Resultado
<class 'pandas.core.frame.DataFrame'>
RangeIndex: 9 entries, 0 to 8
Data columns (total 5 columns):
 #   Column    Non-Null Count  Dtype  
---  ------    --------------  -----  
 0   Pedido    9 non-null      int64  
 1   Producto  9 non-null      object 
 2   Cantidad  9 non-null      int64  
 3   Precio    8 non-null      float64
 4   Pais      8 non-null      object 
dtypes: float64(1), int64(2), object(2)
memory usage: 492.0+ bytes
```
Veremos información como el número de registros, los valores no nulos y los tipos de datos. También podemos ejecutar:
```python
df_sucio.dtypes

# Resultado
Pedido        int64
Producto     object
Cantidad      int64
Precio      float64
Pais         object
dtype: object
```


Pandas identifica, entre otros:
- int64: números enteros.
- float64: números decimales.
- object: puede contener texto u otros objetos Python.
Observa que Precio se representará como float64, porque incluye un dato ausente y Pandas utiliza NaN para representarlo en esta columna numérica.

# OPERACIONES PANDAS RESUMIDAS
para importar pandas usamos `import pandas as pd`.
 - `pd.shape`: dimensiones de la tabla; shape[0] muestra solo las filas, shape[1] muestra solo las columnas.
 - `pd.info()`: muestra los tipos de datos, la cantidad de valores no nulos y el uso de la memoria.
 - `pd.head()`: muestra los 5 primeros registros de la tabla, si usamos pd.head(10) mostrara los primeros 10 registros.
 - `pd.tail()`: muestra los 5 ultimos registros de la tabla, igual que con head podemos indicar la cantidad concreta de registros que mostrar.
 - `pd.describe()`: calcula estadísticas sobre las columnas numéricas: **count**: valores no nulos; **mean**: media aritmética; **std**: desviación estándar; **min**: mínimo; **25%**: primer cuartil; **50%**: mediana; **75%**: tercer cuartil; **max**: máximo.
 - `copy()`: Crear una copia independiente
 - `astype()`: Convertir tipos de datos
 - `str.startswith()`: Comprobar prefijos de texto
 - `dt.year`: Extraer el año de una fecha
 - `dt.month`: Extraer el mes
 - `pd.to_datetime()`: Convertir datos a fechas
 - `to_csv()`: Exportar un DataFrame a CSV