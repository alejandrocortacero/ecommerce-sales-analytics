# Python intermedio y avanzado para análisis de datos

**Proyecto:** E-Commerce Analytics  
**Nivel:** Intermedio → avanzado  
**Continuación de:** `docs/PYTHON_FUNDAMENTOS.md`  
**Entorno de referencia:** Python 3.12, Linux/WSL2, JupyterLab y PostgreSQL  
**Objetivo:** pasar de escribir pequeños ejemplos a diseñar programas reutilizables, verificables y preparados para automatizar procesos de datos.

> **Cómo utilizar este documento:** los capítulos empiezan en el número 26, justo después de los 25 apartados de `PYTHON_FUNDAMENTOS.md`. No necesitas aprenderlos todos de una vez. Los ejemplos pequeños funcionan con la biblioteca estándar de Python salvo que se indique una dependencia adicional. Los datos comerciales de ejemplo son ficticios; cuando se hace referencia a Online Retail, se especifican sus limitaciones.

## Índice y ruta de aprendizaje

| Bloque | Apartados | Prioridad para Data Analyst |
|---|---|---|
| Python como lenguaje | 26–31 | Alta |
| Diseño de programas | 32–37 | Alta |
| Archivos, datos y configuración | 38–42 | Alta |
| Calidad y mantenimiento | 43–48 | Muy alta |
| Rendimiento e integración | 49–53 | Media y alta |
| Proyecto guiado | 54–56 | Muy alta |
| Repaso y referencia | 57–60 | Consulta |

**Orden recomendado:** comienza por 26, 27, 29, 34, 38, 40, 43 y 45. Después estudia 50, 52 y el proyecto guiado. Los decoradores y la concurrencia pueden esperar hasta que los fundamentos estén consolidados.

---

## 26. Referencias, identidad y mutabilidad

En el manual básico vimos que una variable referencia un objeto. Ahora veremos por qué esto importa cuando pasamos listas, diccionarios y DataFrames a funciones.

```python
ventas = [100, 200]
otras_ventas = ventas

otras_ventas.append(300)

print(ventas)                   # [100, 200, 300]
print(ventas is otras_ventas)    # True
```

**`is`:** compara si dos nombres hacen referencia al mismo objeto. **`==`:** compara la igualdad de sus valores.

### Copia superficial y copia profunda

```python
import copy

original = [{"pais": "Spain", "importe": 100}]

superficial = original.copy()
profunda = copy.deepcopy(original)

superficial[0]["importe"] = 200

print(original[0]["importe"])  # 200
print(profunda[0]["importe"])  # 100
```

- **Copia superficial (`copy()`):** crea el contenedor exterior, pero conserva referencias a objetos internos.
- **Copia profunda (`deepcopy()`):** intenta copiar también los objetos anidados.
- **Objetos inmutables:** valores como cadenas, enteros y tuplas de elementos inmutables no se modifican en el lugar.

**Aplicación al proyecto:** cuando una función recibe registros de ventas, conviene decidir y documentar si modificará la entrada. En Pandas, `df.copy()` copia el DataFrame con sus propias reglas; no debe equipararse sin matices a `copy.deepcopy()` de Python.

## 27. Funciones avanzadas: firmas, parámetros y efectos secundarios

Las funciones profesionales deben comunicar claramente qué reciben, qué devuelven y qué cambian.

### Argumentos posicionales, nombrados y valores por defecto

```python
def calcular_total(cantidad, precio, descuento=0):
    subtotal = cantidad * precio
    return subtotal * (1 - descuento)

print(calcular_total(2, 25))
print(calcular_total(cantidad=2, precio=25, descuento=0.10))
```

Podemos exigir determinados tipos de argumentos mediante `/` y `*`:

```python
def registrar_evento(categoria, /, *, detalle, origen="etl"):
    return f"{categoria} | {detalle} | {origen}"

print(registrar_evento("validacion", detalle="3 registros descartados"))
```

En este ejemplo, `categoria` es solo posicional y `detalle` debe pasarse por nombre.

### Argumentos variables

```python
def sumar_importes(*importes):
    return sum(importes)


def crear_registro(**campos):
    return campos

print(sumar_importes(10, 20, 30))
print(crear_registro(pais="Spain", importe=50))
```

- **`*args`:** recibe múltiples argumentos posicionales como una tupla.
- **`**kwargs`:** recibe múltiples argumentos con nombre como un diccionario.

### El error de los valores por defecto mutables

**Evita:**

```python
# Antipatrón: la lista se comparte entre llamadas.
def agregar_error_incorrecto(error, errores=[]):
    errores.append(error)
    return errores
```

**Utiliza:**

```python
def agregar_error(error, errores=None):
    if errores is None:
        errores = []
    errores.append(error)
    return errores
```

### Funciones puras y efectos secundarios

Una función es más fácil de probar cuando **devuelve un resultado** en vez de modificar variables globales, archivos o bases de datos sin advertirlo.

```python
def importe_linea(cantidad: int, precio: float) -> float:
    return cantidad * precio
```

**Buena práctica:** separar las funciones de cálculo de las funciones que leen archivos, escriben resultados o realizan consultas.

## 28. Ámbito de las variables, cierres y funciones internas

Python resuelve los nombres aproximadamente siguiendo **LEGB**: local, enclosing (función exterior), global y built-in.

```python
def crear_clasificador(umbral):
    def clasificar(importe):
        return "alto" if importe >= umbral else "normal"
    return clasificar

clasificar_venta = crear_clasificador(500)
print(clasificar_venta(620))  # alto
```

**Closure o cierre:** la función interna conserva acceso a variables del ámbito exterior, como `umbral`.

```python
def crear_contador():
    total = 0

    def contar():
        nonlocal total
        total += 1
        return total

    return contar

contador = crear_contador()
print(contador())  # 1
print(contador())  # 2
```

- **`nonlocal`:** permite reasignar un nombre definido en una función exterior.
- **`global`:** permite reasignar un nombre global, pero suele dificultar el mantenimiento.

**Consejo:** utiliza cierres cuando simplifiquen una función; no los conviertas en una alternativa innecesariamente compleja a pasar parámetros.

## 29. Anotaciones de tipos (type hints)

Python utiliza tipado dinámico, pero podemos anotar parámetros y resultados para facilitar la lectura, las revisiones y las herramientas de análisis estático.

```python
from decimal import Decimal


def calcular_importe(cantidad: int, precio: Decimal) -> Decimal:
    return cantidad * precio


def encontrar_pais(registro: dict[str, str]) -> str | None:
    return registro.get("pais")
```

Las anotaciones **no validan automáticamente** los valores durante la ejecución.

```python
# Una herramienta de análisis estático puede detectar este desacuerdo:
# calcular_importe("dos", Decimal("10.00"))
```

### Tipos frecuentes

| Anotación | Significado |
|---|---|
| `int` | Entero |
| `str` | Cadena |
| `list[str]` | Lista de cadenas |
| `dict[str, int]` | Diccionario con claves de texto y valores enteros |
| `str | None` | Cadena o ausencia de valor |
| `tuple[str, float]` | Tupla con texto y número |
| `Iterable[Registro]` | Secuencia o fuente iterable de registros |

```python
from collections.abc import Iterable


def contar_registros(registros: Iterable[dict]) -> int:
    return sum(1 for _ in registros)
```

**Herramientas:** `mypy` y `pyright` pueden revisar los tipos sin ejecutar la aplicación. Son opcionales y deben configurarse según el proyecto.

## 30. Iteradores, iterables y generadores

Un **iterable** puede recorrerse con `for`. Un **iterador** recuerda por dónde va. Un **generador** produce elementos a medida que se solicitan, normalmente mediante `yield`.

```python
def importes_positivos(importes):
    for importe in importes:
        if importe > 0:
            yield importe

resultado = importes_positivos([100, -20, 50])
print(next(resultado))  # 100
print(next(resultado))  # 50
```

El generador no necesita construir una lista completa de resultados.

```python
registros = range(1_000_000)
cuadrados = (numero ** 2 for numero in registros)
print(sum(cuadrados))
```

**Cuándo utilizarlo:** lectura de archivos largos, procesamiento secuencial y transformaciones donde no necesitamos mantener todo el contenido en memoria.

**Limitación:** un generador suele consumirse una sola vez. Si necesitas recorrer sus valores repetidamente, deberás crearlo de nuevo o almacenar los resultados.

## 31. Comprensiones avanzadas y funciones de orden superior

### Comprensiones con filtros y varias dimensiones

```python
ventas = [
    {"pais": "Spain", "importe": 120},
    {"pais": "France", "importe": 40},
    {"pais": "Spain", "importe": 80},
]

importes_es = [
    venta["importe"]
    for venta in ventas
    if venta["pais"] == "Spain"
]
```

### Diccionarios por comprensión

```python
precios = {"teclado": 25, "raton": 15}
precios_con_iva = {
    nombre: precio * 1.21
    for nombre, precio in precios.items()
}
```

### sorted, key y lambda

```python
ranking = sorted(
    ventas,
    key=lambda venta: venta["importe"],
    reverse=True,
)
print(ranking[0])
```

- **`sorted()`:** devuelve una lista ordenada sin modificar la lista original.
- **`key`:** función que determina por qué valor se ordena.
- **`lambda`:** función anónima breve, útil cuando mejora la claridad.

Evita comprensiones con demasiadas condiciones anidadas. Una función con un bucle explícito es preferible cuando necesita explicaciones o tratamiento de errores.

## 32. Decoradores: añadir comportamiento a funciones

Un decorador recibe una función y devuelve otra función con comportamiento adicional.

```python
from functools import wraps
from time import perf_counter


def medir_tiempo(funcion):
    @wraps(funcion)
    def envoltorio(*args, **kwargs):
        inicio = perf_counter()
        try:
            return funcion(*args, **kwargs)
        finally:
            duracion = perf_counter() - inicio
            print(f"{funcion.__name__}: {duracion:.4f} s")
    return envoltorio


@medir_tiempo
def calcular_total(importes):
    return sum(importes)

print(calcular_total([10, 20, 30]))
```

**`@wraps`:** conserva metadatos de la función original. **`finally`:** ejecuta el bloque incluso si la función produce una excepción.

**Aplicación:** medir tiempos, registrar llamadas, comprobar permisos o gestionar reintentos. No utilices decoradores si una función normal resulta más sencilla de entender.

## 33. Excepciones personalizadas y propagación de errores

En el primer manual aprendimos `try` y `except`. Ahora diseñaremos errores que expliquen qué falló y permitan reaccionar correctamente.

```python
class RegistroInvalidoError(ValueError):
    pass


def validar_cantidad(cantidad: int) -> int:
    if cantidad <= 0:
        raise RegistroInvalidoError("La cantidad debe ser positiva")
    return cantidad
```

### Capturar solo los errores que podemos resolver

```python
try:
    validar_cantidad(-2)
except RegistroInvalidoError as error:
    print(f"Registro descartado: {error}")
```

**No ocultes errores** con `except Exception: pass`. Si se detecta un error inesperado, conviene registrar información suficiente y dejar que el programa falle de manera visible.

### Encadenar excepciones

```python
def convertir_cantidad(texto: str) -> int:
    try:
        return int(texto)
    except ValueError as error:
        raise RegistroInvalidoError(
            f"Cantidad no válida: {texto!r}"
        ) from error
```

**`raise ... from error`:** conserva la causa original para facilitar la depuración.

## 34. Gestores de contexto y uso de with

`with` permite adquirir y liberar recursos correctamente, incluso ante errores.

```python
from pathlib import Path

ruta = Path("ejemplo.txt")
with ruta.open("w", encoding="utf-8") as archivo:
    archivo.write("Datos de ejemplo")
```

El archivo se cierra al salir del bloque.

### Crear un gestor de contexto propio

```python
from contextlib import contextmanager
from time import perf_counter


@contextmanager
def cronometro(nombre):
    inicio = perf_counter()
    try:
        yield
    finally:
        print(f"{nombre}: {perf_counter() - inicio:.3f} s")


with cronometro("suma"):
    total = sum(range(100_000))
```

**Ejemplos reales:** archivos, conexiones, transacciones, bloqueos y recursos de red.

## 35. Dataclasses: representar datos de forma clara

Una `dataclass` reduce el código necesario para definir objetos que representan información.

```python
from dataclasses import dataclass
from decimal import Decimal


@dataclass(frozen=True)
class LineaVenta:
    factura: str
    pais: str
    cantidad: int
    precio: Decimal

    @property
    def importe(self) -> Decimal:
        return self.cantidad * self.precio


linea = LineaVenta("1001", "Spain", 2, Decimal("25.50"))
print(linea.importe)  # 51.00
```

- **`@dataclass`:** genera funciones habituales como un inicializador y una representación legible.
- **`frozen=True`:** impide reasignar directamente los atributos de la instancia; no congela recursivamente objetos internos mutables.
- **`@property`:** ofrece acceso a un cálculo con sintaxis de atributo.

**Uso recomendado:** configuraciones, resultados de validación y objetos de dominio pequeños.

## 36. Diseño orientado a objetos: composición y responsabilidades

En programas grandes conviene separar las tareas en componentes. Una clase no es automáticamente mejor que una función: utilízala cuando exista un estado compartido o una responsabilidad clara.

```python
class ValidadorVentas:
    def __init__(self, cantidad_minima=1):
        self.cantidad_minima = cantidad_minima

    def es_valida(self, venta):
        return venta["cantidad"] >= self.cantidad_minima


validador = ValidadorVentas(cantidad_minima=1)
print(validador.es_valida({"cantidad": 4}))
```

**Composición:** una clase recibe otro componente y lo utiliza, en lugar de heredar de él sin necesidad.

```python
class ProcesadorVentas:
    def __init__(self, validador):
        self.validador = validador

    def filtrar(self, ventas):
        return [v for v in ventas if self.validador.es_valida(v)]


procesador = ProcesadorVentas(ValidadorVentas())
print(procesador.filtrar([{"cantidad": 2}, {"cantidad": 0}]))
```

**Principio práctico:** una clase para validar no debería encargarse a la vez de generar gráficos, conectarse a PostgreSQL y enviar correos.

## 37. Interfaces informales y Protocol

En Python podemos diseñar funciones que acepten objetos con ciertas capacidades, sin exigir una clase concreta. Este estilo se conoce como *duck typing*.

```python
from typing import Protocol


class Exportador(Protocol):
    def guardar(self, contenido: str) -> None: ...


class ExportadorConsola:
    def guardar(self, contenido: str) -> None:
        print(contenido)


def guardar_reporte(exportador: Exportador, texto: str) -> None:
    exportador.guardar(texto)


guardar_reporte(ExportadorConsola(), "Ventas analizadas")
```

**`Protocol`:** permite describir una interfaz para herramientas de comprobación de tipos. No comprueba automáticamente todos los tipos en tiempo de ejecución.

**Aplicación:** sustituir una salida a consola por una escritura a archivo o a una base de datos sin cambiar la lógica central.

---

## 38. Rutas robustas, directorios y archivos

Las rutas relativas dependen del directorio desde el que se ejecuta el programa. Por eso, en scripts del proyecto suele ser preferible resolver la ruta a partir del propio archivo.

Supongamos que el script está en `src/etl.py`:

```python
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RUTA_ORIGEN = ROOT / "data" / "raw" / "Online Retail.xlsx"
RUTA_SALIDA = ROOT / "data" / "processed" / "ventas.csv"

RUTA_SALIDA.parent.mkdir(parents=True, exist_ok=True)
```

**Importante:** `__file__` está disponible normalmente en scripts `.py`, pero no en todas las celdas de Jupyter. En notebooks puedes empezar por `Path.cwd()` y establecer una ruta base explícita.

### Escritura atómica de un archivo

Para evitar dejar un archivo parcialmente escrito si falla el proceso, podemos escribir primero un archivo temporal y reemplazar después el destino:

```python
from pathlib import Path

salida = Path("reporte.txt")
temporal = salida.with_suffix(".tmp")

temporal.write_text("Proceso completado", encoding="utf-8")
temporal.replace(salida)
```

Esto es útil en procesos locales sencillos. En sistemas concurrentes o con garantías estrictas de durabilidad se necesitan precauciones adicionales.

## 39. CSV y JSON sin Pandas

Conocer los formatos básicos permite diagnosticar problemas cuando un DataFrame no se carga correctamente.

### CSV con la biblioteca estándar

```python
import csv
from pathlib import Path

ruta = Path("ventas_ejemplo.csv")

with ruta.open("w", newline="", encoding="utf-8") as archivo:
    escritor = csv.DictWriter(archivo, fieldnames=["pais", "importe"])
    escritor.writeheader()
    escritor.writerow({"pais": "Spain", "importe": "35.50"})

with ruta.open("r", newline="", encoding="utf-8") as archivo:
    lector = csv.DictReader(archivo)
    for fila in lector:
        print(fila)
```

**Atención:** los valores leídos desde CSV suelen llegar como cadenas y deben validarse y convertirse antes de calcular.

### JSON

```python
import json
from pathlib import Path

configuracion = {"umbral": 500, "pais": "Spain"}
ruta = Path("config.json")

ruta.write_text(json.dumps(configuracion, indent=2), encoding="utf-8")
datos = json.loads(ruta.read_text(encoding="utf-8"))
print(datos["umbral"])
```

**CSV:** adecuado para tablas planas. **JSON:** adecuado para estructuras jerárquicas, respuestas de APIs y configuraciones.

## 40. Precisión monetaria, fechas y zonas horarias

### Decimal para importes exactos

```python
from decimal import Decimal, ROUND_HALF_UP

precio = Decimal("19.95")
cantidad = 3
importe = (precio * cantidad).quantize(
    Decimal("0.01"), rounding=ROUND_HALF_UP
)
print(importe)  # 59.85
```

No construyas un `Decimal` directamente desde un `float` si necesitas preservar el valor decimal escrito originalmente; utiliza texto o convierte conscientemente la representación.

```python
from decimal import Decimal

print(Decimal("0.10") + Decimal("0.20"))  # 0.30
```

**En Online Retail:** durante el trabajo inicial usamos valores numéricos que pueden conservar pequeños residuos de representación. Para cálculos monetarios rigurosos debemos definir la política de redondeo, la moneda y las reglas contables; redondear una consulta no sustituye esa definición.

### Fechas con zona horaria

```python
from datetime import datetime, timezone
from zoneinfo import ZoneInfo

instante_utc = datetime.now(timezone.utc)
instante_madrid = instante_utc.astimezone(ZoneInfo("Europe/Madrid"))

print(instante_madrid.isoformat())
```

- **Fecha consciente de zona horaria:** permite identificar el instante temporal correctamente.
- **Fecha ingenua (naive):** no contiene zona horaria explícita.
- **No asumir zonas:** `InvoiceDate` no debe reinterpretarse como una hora local concreta sin evidencia sobre la fuente.

## 41. Configuración y variables de entorno

Nunca escribas contraseñas de producción directamente en el código fuente.

```python
import os

host = os.getenv("DB_HOST", "localhost")
base_datos = os.getenv("DB_NAME", "ecommerce")
password = os.getenv("POSTGRES_PASSWORD")

if not password:
    raise RuntimeError("Falta la variable POSTGRES_PASSWORD")
```

En nuestro proyecto:

- **Jupyter dentro de Docker Compose:** suele acceder al servicio PostgreSQL mediante el nombre `postgres`.
- **Herramientas desde Windows/WSL:** suelen conectarse a `localhost:5432` si Docker publicó ese puerto.
- **`.env`:** facilita la configuración local, pero no debe subirse con secretos a GitHub.
- **`.env.example`:** documenta los nombres de variables sin exponer credenciales reales.

Evita imprimir secretos o registrarlos en mensajes de error.

## 42. Logging: registrar procesos sin depender de print

`print()` es práctico durante el aprendizaje. En un proceso automatizado suele ser preferible utilizar `logging`.

```python
import logging

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)s | %(message)s",
)

logger = logging.getLogger(__name__)

logger.info("Iniciando importación")
logger.warning("Se encontraron registros sin identificador")
```

| Nivel | Uso habitual |
|---|---|
| `DEBUG` | Detalles técnicos para investigar problemas |
| `INFO` | Progreso normal del proceso |
| `WARNING` | Situación inesperada, pero recuperable |
| `ERROR` | Una operación ha fallado |
| `CRITICAL` | Error grave del servicio o proceso |

```python
try:
    int("no_es_un_numero")
except ValueError:
    logger.exception("Error al interpretar cantidad")
```

**`logger.exception()`:** registra también la traza del error, lo cual facilita el diagnóstico. Utilízalo dentro de un bloque `except`.

---

## 43. Estructura modular del proyecto

Un notebook sirve para explorar, pero un flujo de datos reproducible se beneficia de funciones y módulos independientes.

```text
e-commerce-analytics/
├── src/
│   └── ecommerce_analytics/
│       ├── __init__.py
│       ├── config.py
│       ├── extract.py
│       ├── transform.py
│       ├── validate.py
│       └── load.py
├── tests/
│   ├── test_transform.py
│   └── test_validate.py
├── notebooks/
├── sql/
├── data/
│   ├── raw/
│   └── processed/
└── pyproject.toml
```

**Extract:** obtiene datos. **Transform:** normaliza y transforma. **Validate:** verifica reglas. **Load:** guarda resultados. Es una organización propuesta, no una estructura que debas adoptar de golpe.

### Una función por responsabilidad

```python
def seleccionar_ventas_validas(df):
    condiciones = (
        (df["Quantity"] > 0)
        & (df["UnitPrice"] > 0)
        & df["InvoiceDate"].notna()
    )
    return df.loc[condiciones].copy()
```

Esta función **no incluye por sí sola** la exclusión de facturas de cancelación; para aplicarla deben añadirse explícitamente las reglas del proyecto. Una buena función indica con precisión qué hace y qué deja fuera.

## 44. Empaquetado y dependencias

Para ejecutar y probar módulos de forma uniforme conviene declarar las dependencias del proyecto.

Ejemplo reducido de `pyproject.toml`:

```toml
[build-system]
requires = ["setuptools>=68"]
build-backend = "setuptools.build_meta"

[project]
name = "ecommerce-analytics-learning"
version = "0.1.0"
requires-python = ">=3.12"
dependencies = [
    "pandas>=2.2,<4",
    "SQLAlchemy>=2,<3",
    "psycopg[binary]>=3,<4",
]

[project.optional-dependencies]
dev = ["pytest>=8,<10", "ruff>=0.7"]

[tool.setuptools.packages.find]
where = ["src"]
```

Este archivo es un **ejemplo de configuración**, no sustituye automáticamente nuestro `requirements.txt` ni el `Dockerfile`. Antes de adoptarlo debemos comprobar las versiones reales del entorno.

Comandos habituales desde un entorno virtual de desarrollo:

```bash
python -m pip install -e ".[dev]"
python -m pytest
```

**Instalación editable:** permite modificar el código fuente sin reinstalar el paquete después de cada cambio.

## 45. Pruebas automatizadas con pytest

Las pruebas permiten comprobar que el código sigue funcionando cuando lo modificamos.

**Dependencia opcional:** instalar `pytest` en el entorno donde se ejecutan las pruebas.

```python
# src/ecommerce_analytics/calculos.py
from decimal import Decimal


def importe(cantidad: int, precio: Decimal) -> Decimal:
    if cantidad <= 0:
        raise ValueError("Cantidad no positiva")
    if precio < 0:
        raise ValueError("Precio negativo")
    return cantidad * precio
```

```python
# tests/test_calculos.py
from decimal import Decimal
import pytest
from ecommerce_analytics.calculos import importe


def test_calcula_importe():
    assert importe(2, Decimal("12.50")) == Decimal("25.00")


def test_rechaza_cantidad_invalida():
    with pytest.raises(ValueError):
        importe(0, Decimal("12.50"))
```

Ejecuta desde la raíz del proyecto, con el paquete instalado:

```bash
python -m pytest -q
```

### Qué conviene probar en nuestro ETL

- **Entradas normales:** varias ventas válidas.
- **Casos límite:** lista vacía, precio cero, cantidad negativa.
- **Errores:** fechas imposibles, archivos inexistentes, columnas ausentes.
- **Propiedades:** el número de filas resultantes no debe superar el número de filas de entrada cuando solo filtramos.
- **Datos monetarios:** el importe debe calcularse con la precisión y política establecidas.

Una prueba no debe depender de la base de datos real cuando podemos verificar la lógica con datos pequeños y controlados.

## 46. Fixtures, archivos temporales y pruebas de integración

Los tests de datos suelen necesitar archivos y ejemplos. Pytest ofrece `tmp_path` para crear archivos temporales sin contaminar el repositorio.

```python
def test_exportacion_csv(tmp_path):
    ruta = tmp_path / "ventas.csv"
    ruta.write_text("pais,importe\nSpain,25\n", encoding="utf-8")

    contenido = ruta.read_text(encoding="utf-8")
    assert "Spain,25" in contenido
```

Una **prueba unitaria** revisa una pequeña función aislada. Una **prueba de integración** comprueba que varios componentes se comunican correctamente, por ejemplo Python y PostgreSQL.

**Recomendación:** usar una base de datos de pruebas separada, nunca ejecutar pruebas destructivas en la base `ecommerce` que contiene nuestros análisis.

## 47. Depuración: entender un error antes de corregirlo

Herramientas útiles:

- **Traceback:** muestra dónde se produjo el error y la cadena de llamadas.
- **`breakpoint()`:** detiene la ejecución para inspeccionar variables si existe un depurador disponible.
- **Logs:** permiten seguir un proceso sin observarlo continuamente.
- **Aserciones:** comprueban supuestos internos, pero no deben sustituir validación de datos externos.

```python
def calcular_media(importes):
    if not importes:
        raise ValueError("No hay importes")
    return sum(importes) / len(importes)
```

### Diagnóstico de rutas

```python
from pathlib import Path

print("Directorio actual:", Path.cwd())
print("Existe CSV:", Path("data/processed/online_retail_ventas.csv").exists())
```

En Jupyter dentro de `notebooks/`, es posible que se necesite `../data/...`. No cambies rutas a ciegas: comprueba primero el directorio actual.

## 48. Herramientas de calidad: formato, lint y análisis estático

Estas herramientas ayudan a encontrar errores antes de ejecutar programas grandes.

| Herramienta | Función |
|---|---|
| `ruff` | Reglas de estilo y análisis de código; también puede formatear |
| `black` | Formato consistente, si se elige este formateador |
| `mypy` | Comprobación estática de anotaciones de tipos |
| `pytest` | Pruebas automatizadas |
| `git` | Historial de cambios y colaboración |

Ejemplo opcional con Ruff:

```bash
ruff check src tests
ruff format src tests
```

**No necesitas instalar todas a la vez.** Para el portfolio, empezar por pruebas básicas, Ruff y commits pequeños con cambios verificables ya aporta mucho valor.

---

## 49. Rendimiento y complejidad

Una solución correcta puede ser demasiado lenta cuando crece la cantidad de registros.

### Complejidad temporal simplificada

| Operación aproximada | Coste habitual |
|---|---|
| Acceder a una lista por índice | `O(1)` |
| Recorrer una lista | `O(n)` |
| Buscar pertenencia en una lista | `O(n)` |
| Buscar pertenencia en un conjunto | `O(1)` promedio |
| Ordenar una lista | `O(n log n)` |

Son orientaciones, no garantías para todos los tipos de datos y contextos.

```python
codigos = ["A", "B", "C"]
codigos_set = set(codigos)

print("B" in codigos)
print("B" in codigos_set)
```

### Medir antes de optimizar

```python
from time import perf_counter

inicio = perf_counter()
resultado = sum(range(1_000_000))
print("Segundos:", perf_counter() - inicio)
```

**Herramientas:** `timeit` para fragmentos pequeños y `cProfile` para localizar funciones costosas.

```bash
python -m cProfile -s cumulative src/mi_script.py
```

**Aplicación a Pandas:** suele ser mejor utilizar operaciones vectorizadas y `groupby()` que recorrer fila por fila con `iterrows()`; siempre hay que medir y verificar que el resultado es equivalente.

## 50. Procesamiento de datos por bloques

No siempre conviene cargar un CSV enorme en memoria.

```python
import pandas as pd

ruta = "data/processed/online_retail_ventas.csv"
importe_total = 0.0

for bloque in pd.read_csv(ruta, chunksize=50_000):
    importe_total += bloque["ImporteLinea"].sum()

print(importe_total)
```

**`chunksize`:** devuelve un iterador de DataFrames de tamaño limitado.

**Precaución:** sumar bloques de `float` puede acumular pequeñas imprecisiones. Para conciliaciones monetarias importantes conviene establecer tipos y una política de precisión consistente.

**Cuándo usar bloques:** cargas grandes, validación secuencial y escritura por lotes. Para análisis cruzados complejos, quizá convenga utilizar SQL directamente.

## 51. Concurrencia: hilos, procesos y async

La concurrencia permite organizar tareas que esperan recursos externos o aprovechar varios núcleos en ciertos casos, pero añade complejidad.

| Enfoque | Adecuado principalmente para |
|---|---|
| `threading` | Tareas con espera de entrada/salida (I/O) |
| `asyncio` | Muchas operaciones I/O compatibles con programación asíncrona |
| `multiprocessing` | Trabajo intensivo de CPU distribuible en procesos |

### Ejemplo sencillo de async

```python
import asyncio


async def tarea(nombre):
    await asyncio.sleep(0.1)
    return f"Completada: {nombre}"


async def principal():
    resultados = await asyncio.gather(tarea("A"), tarea("B"))
    print(resultados)


if __name__ == "__main__":
    asyncio.run(principal())
```

**Atención:** `asyncio.run()` no debe ejecutarse dentro de un entorno que ya tiene un bucle de eventos activo, como algunas configuraciones de Jupyter. En un notebook, se puede utilizar `await principal()` directamente.

La concurrencia no convierte automáticamente un cálculo de Pandas en uno más rápido. Para nuestro proyecto actual, el procesamiento secuencial y SQL son suficientes.

## 52. Consultar PostgreSQL con SQLAlchemy

Podemos combinar SQL y Pandas desde Python. La conexión depende de dónde se ejecuta el programa.

**Dependencias:** `SQLAlchemy`, `psycopg` y opcionalmente `pandas`.

```python
import os
from sqlalchemy import create_engine, text, URL

url = URL.create(
    drivername="postgresql+psycopg",
    username="ecommerce",
    password=os.environ["POSTGRES_PASSWORD"],
    host=os.getenv("DB_HOST", "postgres"),
    port=5432,
    database="ecommerce",
)

engine = create_engine(url, pool_pre_ping=True)

with engine.connect() as conexion:
    total = conexion.execute(
        text("SELECT COUNT(*) FROM ventas_online_retail")
    ).scalar_one()
    print(total)
```

**Nota:** `DB_HOST=postgres` funciona normalmente desde el servicio Jupyter de Docker Compose; desde Windows o WSL con el puerto publicado suele ser `localhost`.

### Leer un resultado SQL con Pandas

```python
import pandas as pd
from sqlalchemy import text

consulta = text("""
    SELECT pais, SUM(importe_linea) AS facturacion
    FROM ventas_online_retail
    GROUP BY pais
    ORDER BY facturacion DESC
""")

with engine.connect() as conexion:
    resumen = pd.read_sql_query(consulta, conexion)

print(resumen.head())
```

### Escribir con transacción

```python
# Ejemplo: supone que df_resultado ya existe y contiene datos validados.
with engine.begin() as conexion:
    df_resultado.to_sql(
        "resumen_temporal",
        conexion,
        if_exists="append",
        index=False,
        chunksize=5_000,
    )
```

**`engine.begin()`:** gestiona una transacción, confirmando si termina correctamente o revirtiendo ante un error. **`if_exists="append"`:** añade filas y puede duplicarlas si ejecutas el proceso de nuevo. Nunca utilices `replace` indiscriminadamente sobre tablas que deseas conservar.

## 53. Idempotencia, cargas incrementales y calidad de datos

Un proceso **idempotente** produce un estado equivalente cuando se ejecuta varias veces con las mismas entradas, sin duplicar ni deteriorar los resultados.

### Problema habitual

```python
# Cada ejecución de este patrón puede volver a insertar las mismas filas:
# df.to_sql("ventas_online_retail", engine, if_exists="append", index=False)
```

### Estrategias posibles

- **Reconstrucción controlada:** generar un archivo nuevo completo y sustituir el anterior al terminar correctamente.
- **Clave única:** impedir duplicados mediante una restricción real de la base de datos.
- **Upsert:** insertar nuevas filas y actualizar las existentes cuando corresponda.
- **Watermark:** registrar qué fechas o identificadores se han procesado para realizar cargas incrementales.
- **Auditoría:** almacenar fecha de ejecución, origen, recuentos y errores.

**Cuidado con Online Retail:** `InvoiceNo` no identifica una línea por sí solo, ya que una factura puede contener varios productos y líneas. No inventes una clave única a partir de `InvoiceNo` sin comprender la granularidad de los datos.

### Validaciones antes de cargar

```python
def validar_columnas(columnas_recibidas, columnas_requeridas):
    faltantes = set(columnas_requeridas) - set(columnas_recibidas)
    if faltantes:
        raise ValueError(f"Faltan columnas: {sorted(faltantes)}")


validar_columnas(
    ["InvoiceNo", "Quantity", "UnitPrice"],
    ["InvoiceNo", "Quantity", "UnitPrice"],
)
```

Otros controles: porcentaje de valores ausentes, cantidades negativas, fechas fuera de rango, variaciones inesperadas y comparación de sumas antes y después de transformar.

---

## 54. Proyecto guiado: un ETL pequeño sin Pandas

Vamos a crear un programa reproducible que lea un CSV pequeño, compruebe reglas y genere un CSV preparado junto con un resumen JSON. Este proyecto **es independiente del Excel real Online Retail** para que puedas comprender el flujo completo sin depender de cientos de miles de filas.

### Estructura

```text
e-commerce-analytics/
├── data/
│   ├── raw/
│   │   └── ventas_demo.csv
│   └── processed/
├── src/
│   └── etl_ventas_demo.py
└── tests/
    └── test_etl_demo.py
```

### Datos de prueba: `data/raw/ventas_demo.csv`

```csv
invoice_no,country,quantity,unit_price
1001,Spain,2,25.50
1002,France,1,80.00
C1003,Spain,-1,25.50
1004,Germany,0,10.00
1005,Spain,3,12.00
1006,Spain,dos,15.00
```

**Reglas del ejemplo:** excluir facturas marcadas con `C`, cantidades no positivas, precios no positivos y registros con cantidades o precios mal escritos. En una auditoría real, las cancelaciones se conservarían también en una salida separada.

### Script completo: `src/etl_ventas_demo.py`

```python
import argparse
import csv
import json
import logging
from decimal import Decimal, InvalidOperation
from pathlib import Path

LOGGER = logging.getLogger(__name__)


class VentaInvalidaError(ValueError):
    pass


def transformar(fila: dict[str, str]) -> dict[str, str]:
    factura = fila["invoice_no"].strip()
    pais = fila["country"].strip()

    if not factura or not pais:
        raise VentaInvalidaError("Falta factura o país")
    if factura.upper().startswith("C"):
        raise VentaInvalidaError("Factura de cancelación")

    try:
        cantidad = int(fila["quantity"])
        precio = Decimal(fila["unit_price"])
    except (ValueError, InvalidOperation) as error:
        raise VentaInvalidaError("Cantidad o precio inválido") from error

    if cantidad <= 0 or not precio.is_finite() or precio <= 0:
        raise VentaInvalidaError("Cantidad o precio no positivo")

    importe = (precio * cantidad).quantize(Decimal("0.01"))

    return {
        "invoice_no": factura,
        "country": pais,
        "quantity": str(cantidad),
        "unit_price": str(precio),
        "line_amount": str(importe),
    }


def ejecutar(origen: Path, destino: Path) -> dict[str, object]:
    destino.parent.mkdir(parents=True, exist_ok=True)
    temporal = destino.with_suffix(".tmp")
    columnas = ["invoice_no", "country", "quantity", "unit_price"]
    columnas_salida = columnas + ["line_amount"]

    leidos = 0
    conservados = 0
    descartados = 0
    importe_total = Decimal("0.00")

    try:
        with origen.open("r", newline="", encoding="utf-8-sig") as entrada:
            lector = csv.DictReader(entrada)
            if lector.fieldnames is None:
                raise ValueError("El CSV no contiene cabecera")
            faltantes = set(columnas) - set(lector.fieldnames)
            if faltantes:
                raise ValueError(f"Faltan columnas: {sorted(faltantes)}")

            with temporal.open("w", newline="", encoding="utf-8") as salida:
                escritor = csv.DictWriter(salida, fieldnames=columnas_salida)
                escritor.writeheader()

                for fila in lector:
                    leidos += 1
                    try:
                        venta = transformar(fila)
                    except VentaInvalidaError as error:
                        descartados += 1
                        LOGGER.warning("Fila %s descartada: %s", leidos, error)
                        continue

                    escritor.writerow(venta)
                    conservados += 1
                    importe_total += Decimal(venta["line_amount"])

        temporal.replace(destino)
    finally:
        if temporal.exists():
            temporal.unlink()

    resumen = {
        "registros_leidos": leidos,
        "registros_conservados": conservados,
        "registros_descartados": descartados,
        "importe_total": str(importe_total),
    }
    return resumen


def main() -> None:
    parser = argparse.ArgumentParser(description="ETL de ventas de ejemplo")
    parser.add_argument("--input", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    argumentos = parser.parse_args()

    logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")
    resumen = ejecutar(argumentos.input, argumentos.output)
    print(json.dumps(resumen, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
```

### Ejecutar desde la raíz del proyecto

```bash
python src/etl_ventas_demo.py \
  --input data/raw/ventas_demo.csv \
  --output data/processed/ventas_demo_limpias.csv
```

**Salida esperada del resumen:**

```json
{
  "registros_leidos": 6,
  "registros_conservados": 3,
  "registros_descartados": 3,
  "importe_total": "167.00"
}
```

El archivo de salida contiene tres líneas y las columnas `invoice_no`, `country`, `quantity`, `unit_price` y `line_amount`.

**Limitaciones deliberadas:** este programa no elimina duplicados, no almacena las líneas descartadas, no identifica clientes y no realiza un cálculo neto de devoluciones. Son futuras mejoras posibles, no capacidades que debamos atribuirle ahora.

## 55. Ampliación del proyecto: pruebas y métricas

Podemos probar la función pura de transformación sin leer ningún archivo.

```python
# tests/test_etl_demo.py
from decimal import Decimal
import pytest

from etl_ventas_demo import VentaInvalidaError, transformar


def test_transformar_venta_valida():
    fila = {
        "invoice_no": "1001",
        "country": "Spain",
        "quantity": "2",
        "unit_price": "25.50",
    }
    resultado = transformar(fila)
    assert Decimal(resultado["line_amount"]) == Decimal("51.00")


def test_cancelacion_no_se_incluye():
    fila = {
        "invoice_no": "C1001",
        "country": "Spain",
        "quantity": "-1",
        "unit_price": "25.50",
    }
    with pytest.raises(VentaInvalidaError):
        transformar(fila)
```

**Configuración para el ejemplo:** si ejecutas tests sin instalar un paquete, importa el módulo desde `src` estableciendo `PYTHONPATH=src` en el proceso de pruebas, o reorganiza este ejemplo dentro del paquete de la sección 43. No asumas que Python encontrará automáticamente todos los módulos de cualquier carpeta.

```bash
PYTHONPATH=src python -m pytest -q tests/test_etl_demo.py
```

### Mejoras posibles

- **Auditoría:** guardar por separado las filas rechazadas y el motivo.
- **Calidad:** comparar sumas de entrada y salida con reglas definidas.
- **Eficiencia:** procesar archivos grandes en lotes.
- **PostgreSQL:** cargar la salida en una tabla de pruebas con una estrategia que no duplique registros.
- **Automatización:** programar el script para ejecutarse cuando haya datos nuevos.

## 56. De un script local a un pipeline profesional

Un flujo de datos profesional añade varias garantías alrededor de las transformaciones:

<details>
<summary>Esquema conceptual del proceso</summary>

```text
Origen CSV / Excel / API
        |
        v
Extracción y validación de esquema
        |
        v
Transformaciones y reglas de negocio
        |
        v
Controles de calidad y auditoría
        |
        v
Carga controlada en PostgreSQL
        |
        v
Vistas SQL y análisis con Pandas
        |
        v
Dashboard Power BI
```

</details>

- **Observabilidad:** saber si un proceso terminó, cuánto tardó y cuántos registros procesó.
- **Idempotencia:** poder reejecutarlo sin duplicar resultados.
- **Reproducibilidad:** mismas reglas, dependencias y entradas producen salidas equivalentes.
- **Separación de entornos:** desarrollo, pruebas y producción no comparten datos críticos accidentalmente.
- **Documentación:** registrar las definiciones de cada KPI y las decisiones de limpieza.

Para nuestro portfolio es más valioso construir una primera versión pequeña y fiable que añadir herramientas complejas sin poder explicar su función.

---

## 57. Errores avanzados frecuentes

| Problema | Causa habitual | Corrección recomendada |
|---|---|---|
| Modificar sin querer una lista original | Dos referencias al mismo objeto | Revisar mutabilidad y estrategia de copia |
| Acumular resultados entre llamadas | Argumento por defecto mutable | Usar `None` y crear el contenedor dentro |
| Desbordar la RAM | Cargar todo el archivo | Procesar por lotes o agregar en SQL |
| Datos monetarios con decimales raros | Aritmética `float` | Definir precisión y usar `Decimal` cuando corresponda |
| Duplicar datos en PostgreSQL | Repetir `append` | Aplicar idempotencia y restricciones adecuadas |
| Errores silenciosos | `except` demasiado amplio | Capturar excepciones concretas y registrar contexto |
| Test que funciona solo en mi equipo | Rutas y dependencias implícitas | Estandarizar entorno y rutas |
| Diferencias de fecha | Zona horaria desconocida | Preservar origen y documentar supuestos |
| Código difícil de ampliar | Función que hace todas las tareas | Separar extracción, validación, transformación y carga |
| Publicación accidental de contraseñas | Secretos en scripts y commits | Usar variables de entorno y `.gitignore` |

## 58. Ejercicios propuestos, sin soluciones

**Ejercicio 1 — Referencias:** crea una lista que contenga diccionarios; compara asignación, copia superficial y profunda.

**Ejercicio 2 — Funciones:** escribe una función que reciba cualquier cantidad de importes y devuelva el total usando `Decimal`.

**Ejercicio 3 — Tipos:** anota una función que reciba una lista de registros y devuelva una lista de países únicos.

**Ejercicio 4 — Generadores:** crea un generador que emita únicamente las cantidades positivas de una secuencia.

**Ejercicio 5 — Excepciones:** define una excepción personalizada para precios negativos y escribe una prueba para ella.

**Ejercicio 6 — Archivos:** lee un CSV de prueba usando `csv.DictReader` y cuenta las filas sin cargarlo en Pandas.

**Ejercicio 7 — Logging:** sustituye los mensajes `print()` de un script de carga por logs con niveles `INFO` y `WARNING`.

**Ejercicio 8 — Pruebas:** escribe tres pruebas para una función que calcula el importe de una línea.

**Ejercicio 9 — PostgreSQL:** ejecuta desde Python una consulta agrupada de facturación por país y recibe el resultado en un DataFrame.

**Ejercicio 10 — Pipeline:** modifica el ETL guiado para guardar también el número de líneas rechazadas por cada motivo.

**Ejercicio 11 — Rendimiento:** compara dos formas de buscar códigos de producto en una colección grande y mide el tiempo.

**Ejercicio 12 — Idempotencia:** ejecuta dos veces un proceso de exportación y verifica que el resultado no duplica registros.

## 59. Glosario técnico

| Término | Significado |
|---|---|
| Mutabilidad | Posibilidad de modificar un objeto después de crearlo |
| Copia superficial | Duplica un contenedor, no necesariamente sus elementos internos |
| Closure | Función que conserva referencias a variables de su ámbito exterior |
| Type hint | Anotación sobre tipos esperados |
| Generador | Productor de valores bajo demanda |
| Decorador | Función que envuelve otra función |
| Context manager | Componente que gestiona entrada y salida de un recurso |
| Dataclass | Clase orientada a representar datos con menos código repetitivo |
| Logging | Registro estructurado de eventos del programa |
| Prueba unitaria | Verificación automatizada de una unidad de código |
| Prueba de integración | Verificación de la interacción entre componentes |
| ETL | Extracción, transformación y carga de datos |
| Idempotencia | Capacidad de reejecutar sin duplicar o alterar indebidamente resultados |
| Transacción | Conjunto de operaciones confirmadas o revertidas como unidad |
| Chunk | Bloque de datos procesado por partes |
| Profiling | Medición del rendimiento para localizar cuellos de botella |
| Concurrencia | Organización de tareas que pueden progresar solapadamente |

## 60. Recursos y siguiente itinerario

- **Python — Tutorial y biblioteca estándar:** https://docs.python.org/3/tutorial/ y https://docs.python.org/3/library/
- **Typing:** https://docs.python.org/3/library/typing.html
- **Dataclasses:** https://docs.python.org/3/library/dataclasses.html
- **Logging:** https://docs.python.org/3/howto/logging.html
- **Pytest:** https://docs.pytest.org/
- **Pandas — Guía de usuario:** https://pandas.pydata.org/docs/user_guide/index.html
- **SQLAlchemy:** https://docs.sqlalchemy.org/
- **PostgreSQL:** https://www.postgresql.org/docs/

### Ruta de aplicación a E-Commerce Analytics

1. **Primero:** dominar funciones reutilizables, manejo de errores, rutas y logs.
2. **Después:** convertir el notebook de limpieza en funciones dentro de `src/`.
3. **A continuación:** escribir pruebas con datos de ejemplo y controles de calidad.
4. **Luego:** integrar el script con PostgreSQL y documentar las cargas.
5. **Por último:** automatizar la ejecución y alimentar las vistas SQL y Power BI.

**Ruta recomendada:** `docs/PYTHON_INTERMEDIO_AVANZADO.md`. Este archivo complementa `PYTHON_FUNDAMENTOS.md`; no lo sustituye.
