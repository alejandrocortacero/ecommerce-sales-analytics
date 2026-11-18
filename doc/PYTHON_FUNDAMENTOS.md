# Fundamentos de Python para análisis de datos

**Proyecto:** E-Commerce Analytics  
**Nivel:** Principiante  
**Objetivo:** comprender los fundamentos de Python antes de profundizar en Pandas, SQL y automatización.

> Este documento es una guía de consulta y aprendizaje. Los ejemplos usan Python 3.12 y se pueden ejecutar en JupyterLab o en un archivo `.py`. Los datos de ejemplo son ficticios salvo que se indique lo contrario.

## 1. ¿Qué es Python y para qué lo utilizamos?

Python es un lenguaje de programación de propósito general. En nuestro proyecto lo usamos para leer datos, limpiarlos, calcular indicadores, generar gráficos y automatizar procesos.

- **Python:** el lenguaje con el que escribimos programas.
- **Pandas:** una biblioteca de Python especializada en datos tabulares.
- **JupyterLab:** un entorno donde ejecutamos código en celdas.
- **PostgreSQL:** una base de datos que puede almacenar los resultados de nuestros programas.

En resumen: primero aprendemos a programar con Python; después usamos bibliotecas como Pandas para trabajar con datos.

## 2. Primer programa y comentarios

```python
print("Hola, E-Commerce Analytics")
```

`print()` muestra información en la salida de la consola o del notebook.

```python
# Este comentario explica qué vamos a calcular
ventas = 120
print(ventas)
```

- **Comentario:** comienza con `#` y Python lo ignora al ejecutar.
- **Instrucción:** una orden que ejecuta Python.
- **Indentación:** espacios al comienzo de una línea que delimitan bloques de código. En Python es obligatoria.

## 3. Variables y nombres

Una variable es un nombre que referencia un valor.

```python
producto = "Teclado"
cantidad = 3
precio = 25.50

importe = cantidad * precio
print(importe)  # 76.5
```

Buenas prácticas:

- **Nombres descriptivos:** `precio_unitario` es más claro que `p`.
- **snake_case:** usa minúsculas y guiones bajos para variables y funciones.
- **Mayúsculas y minúsculas:** `precio` y `Precio` son variables distintas.
- **Sin espacios:** `precio_unitario` es válido; `precio unitario` no.
- **Evitar nombres reservados:** no uses `list`, `sum` o `str` como variables.

## 4. Tipos de datos básicos

| Tipo | Ejemplo | Uso |
|---|---|---|
| `int` | `42` | Números enteros |
| `float` | `19.95` | Números decimales aproximados |
| `str` | `"España"` | Texto |
| `bool` | `True` | Condiciones verdaderas o falsas |
| `NoneType` | `None` | Ausencia de valor |

```python
unidades = 7
precio = 12.50
pais = "Spain"
es_cliente = True
codigo_descuento = None

print(type(unidades))
print(type(precio))
print(type(pais))
```

**Nota sobre dinero:** los valores `float` pueden presentar pequeñas imprecisiones. Para cálculo monetario exacto en Python estándar puede utilizarse `Decimal`; en nuestra base de datos empleamos `NUMERIC`.

```python
from decimal import Decimal

precio = Decimal("12.50")
unidades = 3
print(precio * unidades)  # 37.50
```

## 5. Conversiones de tipos

```python
cantidad_texto = "5"
cantidad = int(cantidad_texto)

precio_texto = "19.99"
precio = float(precio_texto)

mensaje = str(cantidad)
```

- **`int()`** convierte a entero cuando el valor es válido.
- **`float()`** convierte a decimal aproximado.
- **`str()`** convierte a texto.
- **`bool()`** obtiene el valor lógico según las reglas del lenguaje.

No todos los textos pueden convertirse: `int("cinco")` genera un error.

## 6. Operadores

### Operaciones matemáticas

| Operador | Operación | Ejemplo |
|---|---|---|
| `+` | Suma | `7 + 2` |
| `-` | Resta | `7 - 2` |
| `*` | Multiplicación | `7 * 2` |
| `/` | División | `7 / 2` |
| `//` | División entera | `7 // 2` |
| `%` | Resto | `7 % 2` |
| `**` | Potencia | `7 ** 2` |

### Comparaciones y lógica

| Operador | Significado |
|---|---|
| `==` | Igual a |
| `!=` | Distinto de |
| `>` y `<` | Mayor y menor |
| `>=` y `<=` | Mayor o igual y menor o igual |
| `and` | Ambas condiciones |
| `or` | Al menos una condición |
| `not` | Negación |

```python
importe = 150
pais = "Spain"

print(importe > 100 and pais == "Spain")  # True
```

**Diferencia importante:** en Python habitual usamos `and`, `or` y `not`; para combinar Series booleanas de Pandas usamos `&`, `|` y `~`, con cada condición entre paréntesis.

## 7. Condicionales: if, elif y else

Permiten ejecutar un bloque cuando se cumple una condición.

```python
importe = 240

if importe >= 500:
    categoria = "Alta"
elif importe >= 100:
    categoria = "Media"
else:
    categoria = "Baja"

print(categoria)  # Media
```

- **`if`:** comprueba la primera condición.
- **`elif`:** prueba otra condición si la anterior no se cumplió.
- **`else`:** gestiona los casos restantes.
- **Indentación:** se recomienda usar cuatro espacios dentro de cada bloque.

## 8. Listas y tuplas

### Listas

Una lista almacena una secuencia ordenada y modificable.

```python
paises = ["Spain", "France", "Germany"]

print(paises[0])   # Spain
print(paises[-1])  # Germany

paises.append("Portugal")
print(len(paises))  # 4
```

- **Índices:** empiezan en 0.
- **`append()`:** añade un elemento al final.
- **`len()`:** devuelve el número de elementos.
- **`in`:** comprueba pertenencia.

```python
print("Spain" in paises)  # True
print(paises[1:3])        # ['France', 'Germany']
```

### Tuplas

Son secuencias ordenadas que no permiten cambiar sus elementos directamente.

```python
coordenadas = (40.4, -3.7)
print(coordenadas[0])
```

## 9. Diccionarios y conjuntos

### Diccionarios (`dict`)

Guardan pares **clave: valor**. Son muy útiles para representar registros y configuraciones.

```python
pedido = {
    "invoice_no": "1001",
    "pais": "Spain",
    "cantidad": 2,
    "precio": 25.0
}

print(pedido["pais"])
print(pedido.get("descuento", 0))

pedido["cantidad"] = 3
```

- **`pedido["pais"]`:** recupera el valor y genera `KeyError` si falta la clave.
- **`get()`:** permite indicar un valor alternativo cuando falta una clave.
- **Asignación:** puede añadir o actualizar una clave.

### Conjuntos (`set`)

Almacenan elementos únicos; son útiles para eliminar repeticiones.

```python
paises = ["Spain", "France", "Spain"]
paises_unicos = set(paises)
print(len(paises_unicos))  # 2
```

## 10. Bucles for y while

### for

Recorre los elementos de una secuencia.

```python
importes = [20, 35, 15]
total = 0

for importe in importes:
    total += importe

print(total)  # 70
```

También puedes usar `enumerate()` cuando necesitas la posición:

```python
for posicion, importe in enumerate(importes, start=1):
    print(posicion, importe)
```

### while

Repite un bloque mientras una condición sea verdadera.

```python
intento = 1
while intento <= 3:
    print("Intento", intento)
    intento += 1
```

- **`break`:** sale del bucle.
- **`continue`:** pasa a la siguiente iteración.
- **Precaución:** asegúrate de que un `while` pueda terminar.

## 11. Funciones: def, parámetros y return

Una función agrupa instrucciones reutilizables.

```python
def calcular_importe(cantidad, precio_unitario):
    importe = cantidad * precio_unitario
    return importe

resultado = calcular_importe(3, 12.5)
print(resultado)  # 37.5
```

- **`def`:** declara la función.
- **Parámetros:** valores que la función recibe.
- **`return`:** devuelve un resultado para utilizarlo en otras operaciones.
- **`print`:** solo muestra información; no sustituye a `return`.

### Parámetros con valores por defecto

```python
def calcular_total(cantidad, precio, descuento=0):
    subtotal = cantidad * precio
    return subtotal * (1 - descuento)

print(calcular_total(2, 50))       # 100.0
print(calcular_total(2, 50, 0.10)) # 90.0
```

## 12. Comprensiones de listas

Permiten crear listas transformando una secuencia.

```python
precios = [10, 20, 30]
precios_con_iva = [precio * 1.21 for precio in precios]
print(precios_con_iva)
```

Una forma tradicional equivalente es:

```python
precios_con_iva = []
for precio in precios:
    precios_con_iva.append(precio * 1.21)
```

Para empezar, utiliza la forma que te resulte más clara. Las comprensiones son útiles cuando la transformación es sencilla.

## 13. Cadenas de texto

```python
producto = "  Teclado Mecánico  "

print(producto.strip())
print(producto.lower())
print(producto.upper())
print(producto.replace("Mecánico", "USB"))
```

- **`strip()`:** elimina espacios al inicio y al final.
- **`lower()` y `upper()`:** convierten a minúsculas o mayúsculas.
- **`replace()`:** reemplaza fragmentos de texto.
- **`split()`:** divide un texto en partes.

### f-strings

Sirven para insertar variables en textos.

```python
pais = "Spain"
facturacion = 15234.568
print(f"País: {pais}; facturación: {facturacion:,.2f} £")
```

El formato `:,.2f` establece dos decimales y un separador de miles con el formato predeterminado de Python.

## 14. Valores ausentes, errores y excepciones

En Python estándar, `None` indica que falta un valor. En Pandas también veremos `NaN`, `NaT` y `pd.NA`, que tienen comportamientos distintos.

```python
customer_id = None

if customer_id is None:
    print("Cliente sin identificar")
```

### Manejar errores con try y except

```python
texto = "12a"

try:
    cantidad = int(texto)
except ValueError:
    print("La cantidad debe ser un número entero válido")
```

Errores habituales:

| Error | Motivo frecuente |
|---|---|
| `NameError` | Variable no definida |
| `TypeError` | Operación incompatible con el tipo |
| `ValueError` | Valor no válido para la conversión |
| `KeyError` | Clave inexistente en un diccionario o columna inexistente en Pandas |
| `IndexError` | Posición fuera del rango de una lista |
| `FileNotFoundError` | Ruta de archivo incorrecta o archivo inexistente |
| `IndentationError` | Bloques mal indentados |

**Consejo:** lee la última línea del mensaje de error y comprueba primero la variable, el tipo y la ruta implicados.

## 15. Archivos y rutas con pathlib

La biblioteca estándar `pathlib` facilita trabajar con archivos de manera portable.

```python
from pathlib import Path

ruta = Path("../data/processed/online_retail_ventas.csv")
print(ruta.exists())
```

Las rutas relativas dependen del **directorio de trabajo actual**, no necesariamente de la ubicación del archivo `.py` o del notebook.

```python
from pathlib import Path
print(Path.cwd())
```

Si estás en `/workspace/notebooks`, `../data/processed/` apunta a `/workspace/data/processed/`.

### Leer y escribir texto

```python
from pathlib import Path

ruta = Path("ejemplo.txt")
ruta.write_text("Primer registro", encoding="utf-8")
contenido = ruta.read_text(encoding="utf-8")
print(contenido)
```

Para tablas CSV y Excel grandes, preferiremos Pandas en vez de procesar todo manualmente con cadenas de texto.

## 16. Módulos, paquetes y bibliotecas

- **Módulo:** archivo de Python con funciones, variables o clases.
- **Paquete:** conjunto organizado de módulos.
- **Biblioteca:** código reutilizable que importamos en nuestros programas.

```python
import math
print(math.sqrt(81))  # 9.0

from pathlib import Path
```

Ejemplo de estructura de proyecto:

```text
e-commerce-analytics/
├── src/
│   └── limpieza.py
├── notebooks/
├── data/
└── requirements.txt
```

El archivo `requirements.txt` registra dependencias de terceros, por ejemplo `pandas` y `matplotlib`. En nuestro proyecto esas dependencias se instalan dentro del contenedor de Jupyter.

## 17. Entornos y ejecución de Python

Podemos ejecutar programas de varias formas:

- **Script `.py`:** archivo ejecutado de principio a fin.
- **Notebook `.ipynb`:** documento interactivo con celdas, código y resultados.
- **Entorno virtual:** instalación aislada de dependencias para un proyecto.
- **Docker:** contenedor que incluye Python y las bibliotecas necesarias.

En una instalación local tradicional:

```bash
python -m venv .venv
source .venv/bin/activate
python -m pip install pandas
```

En E-Commerce Analytics ya usamos Docker para mantener un entorno consistente. No es necesario crear otro entorno virtual dentro del contenedor.

## 18. Introducción a las clases y los objetos

Una clase define cómo se crean objetos que comparten atributos y comportamientos.

```python
class Producto:
    def __init__(self, nombre, precio):
        self.nombre = nombre
        self.precio = precio

    def aplicar_descuento(self, porcentaje):
        return self.precio * (1 - porcentaje)

teclado = Producto("Teclado", 50)
print(teclado.aplicar_descuento(0.10))  # 45.0
```

- **`class`:** declara una clase.
- **`__init__`:** inicializa los atributos del objeto.
- **`self`:** referencia al objeto que está utilizando el método.
- **Método:** función definida dentro de una clase.

Para comenzar con análisis de datos no necesitas dominar programación orientada a objetos, pero conviene reconocer estos conceptos cuando leas bibliotecas.

## 19. Cómo se relaciona Python con Pandas

Muchas operaciones de Pandas se entienden mejor conociendo primero Python:

| Python básico | Aplicación en Pandas |
|---|---|
| Variables | Guardar DataFrames y resultados |
| Listas y diccionarios | Crear DataFrames iniciales |
| Comparaciones | Filtrar registros |
| Funciones | Reutilizar procesos de limpieza |
| Importaciones | Usar `pandas`, `matplotlib` y SQLAlchemy |
| Archivos y rutas | Leer Excel, CSV y exportar resultados |
| Errores y excepciones | Diagnosticar fallos al cargar datos |

Por ejemplo, primero conocemos una lista de diccionarios:

```python
ventas = [
    {"pais": "Spain", "cantidad": 2, "precio": 25},
    {"pais": "France", "cantidad": 1, "precio": 60}
]
```

Y después la convertimos en un DataFrame:

```python
import pandas as pd

df = pd.DataFrame(ventas)
df["importe"] = df["cantidad"] * df["precio"]
print(df)
```

## 20. Ejemplo aplicado: resumen de ventas sin Pandas

Este programa permite practicar listas, diccionarios, funciones, bucles y condiciones antes de usar una biblioteca de análisis.

```python
ventas = [
    {"pais": "Spain", "cantidad": 2, "precio": 25},
    {"pais": "France", "cantidad": 1, "precio": 60},
    {"pais": "Spain", "cantidad": 3, "precio": 10}
]


def facturacion_por_pais(registros):
    totales = {}

    for venta in registros:
        pais = venta["pais"]
        importe = venta["cantidad"] * venta["precio"]
        totales[pais] = totales.get(pais, 0) + importe

    return totales


resultado = facturacion_por_pais(ventas)
print(resultado)
# {'Spain': 80, 'France': 60}
```

**¿Qué hemos hecho?**

- **Lista de diccionarios:** cada diccionario representa una línea de venta.
- **Bucle `for`:** recorre las líneas.
- **Multiplicación:** calcula el importe de cada línea.
- **Diccionario `totales`:** acumula los importes por país.
- **`return`:** devuelve los resultados.

Con Pandas haríamos una agrupación `groupby()`, pero entender este ejemplo ayuda a saber qué está ocurriendo.

## 21. Buenas prácticas para nuestro portfolio

- **Legibilidad:** prioriza nombres claros y divide el código en pasos comprensibles.
- **Funciones pequeñas:** cada función debería tener una responsabilidad fácil de explicar.
- **No sobrescribir datos originales:** usa copias o archivos de salida separados en las transformaciones.
- **Validación:** comprueba las dimensiones, valores ausentes y resultados después de cada fase.
- **No subir secretos:** mantén contraseñas y tokens fuera de GitHub; utiliza variables de entorno.
- **Documentación:** explica qué entra, qué sale y por qué aplicas una transformación.
- **Reproducibilidad:** guarda el código fuente y las dependencias, no solo capturas de resultados.
- **Control de versiones:** realiza commits con cambios concretos y verificables.

## 22. Errores habituales al aprender Python

| Confusión | Forma correcta de pensarlo |
|---|---|
| `=` frente a `==` | `=` asigna; `==` compara |
| `print()` frente a `return` | Uno muestra; el otro devuelve un resultado |
| `lista[1]` | Accede al segundo elemento, no al primero |
| `df2 = df1` | Crea otra referencia; no copia el DataFrame |
| `df.shape()` | `shape` es una propiedad: `df.shape` |
| Ruta relativa incorrecta | Comprueba `Path.cwd()` |
| `if` sin indentación | Los bloques requieren indentación coherente |
| `and` con Series de Pandas | Emplea `&` con condiciones entre paréntesis |

## 23. Prácticas de repaso (sin soluciones)

**Práctica 1 — Variables y operadores:** crea variables para un producto, cantidad y precio, y calcula su importe.

**Práctica 2 — Condicionales:** clasifica un pedido como `Alto` si supera 200 £ y `Normal` en caso contrario.

**Práctica 3 — Listas:** dada una lista de importes, calcula el total sin utilizar Pandas.

**Práctica 4 — Diccionarios:** representa una venta con país, cantidad y precio; añade un campo `importe` calculado.

**Práctica 5 — Funciones:** escribe `calcular_ticket_medio(facturacion, pedidos)` que devuelva `None` cuando el número de pedidos sea cero.

**Práctica 6 — Archivos:** comprueba con `Path.exists()` si existe `data/processed/online_retail_ventas.csv` desde el directorio correcto.

**Práctica 7 — Integración con Pandas:** transforma una lista de diccionarios de ventas en un DataFrame y calcula la facturación por país.

## 24. Glosario rápido

| Concepto | Definición |
|---|---|
| Variable | Nombre que referencia un valor |
| Tipo de dato | Clase de valor, como entero, texto o booleano |
| Condición | Expresión evaluada como verdadera o falsa |
| Bucle | Estructura que repite instrucciones |
| Función | Bloque reutilizable que puede recibir y devolver valores |
| Lista | Secuencia ordenada y modificable |
| Diccionario | Colección de pares clave-valor |
| Módulo | Archivo con código reutilizable |
| Biblioteca | Conjunto de herramientas importables |
| Excepción | Señal de un error o situación especial durante la ejecución |
| DataFrame | Tabla de datos de Pandas con filas y columnas |
| Script | Archivo con instrucciones ejecutables de Python |

## 25. Recursos para profundizar

- **Tutorial oficial de Python:** https://docs.python.org/es/3/tutorial/
- **Referencia de la biblioteca estándar:** https://docs.python.org/es/3/library/
- **Guía de inicio de Pandas:** https://pandas.pydata.org/docs/getting_started/index.html
- **Documentación de PostgreSQL:** https://www.postgresql.org/docs/

---

**Ruta recomendada en nuestro repositorio:** `docs/PYTHON_FUNDAMENTOS.md`.

**Siguiente paso de aprendizaje:** consolidar funciones, diccionarios y manejo de errores; después automatizar la lectura, limpieza y carga de Online Retail con Python y PostgreSQL.
