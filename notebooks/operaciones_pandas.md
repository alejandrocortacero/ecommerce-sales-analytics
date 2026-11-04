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