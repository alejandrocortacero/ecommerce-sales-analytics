"""Análisis reproducible de ventas para el proyecto E-Commerce Analytics.

Fuente de datos prevista:
    UCI Machine Learning Repository — Online Retail (2010–2011)
    https://archive.ics.uci.edu/dataset/352/online+retail

Este módulo implementa un flujo sencillo de análisis de datos:

    1. Cargar el archivo original (.xlsx o .csv).
    2. Comprobar el esquema y los tipos de columnas.
    3. Auditar nulos, duplicados, cancelaciones y valores sospechosos.
    4. Seleccionar líneas de venta válidas SIN modificar el original.
    5. Calcular indicadores comerciales y agrupaciones.
    6. Exportar tablas, un informe Markdown y gráficos.

IMPORTANTE:
    - Las cantidades negativas y las facturas que comienzan por C pueden
      representar devoluciones o cancelaciones; no se borran del origen.
    - Las cifras de ingresos de este módulo son ventas positivas brutas,
      NO ingresos netos después de devoluciones, impuestos o costes.
    - Una línea de Excel NO equivale necesariamente a una factura completa.
    - Los duplicados exactos se notifican, pero no se eliminan automáticamente.

Uso desde la raíz del repositorio:
    python src/retail_analysis.py
    python src/retail_analysis.py --no-charts
    python src/retail_analysis.py --export-detail
    python src/retail_analysis.py --input data/raw/otro_archivo.csv

Dependencias: pandas, openpyxl (para Excel) y matplotlib.
"""

from __future__ import annotations

import argparse
import logging
from pathlib import Path
from typing import Any

import matplotlib

# Permite guardar gráficos al ejecutar dentro de Docker, sin pantalla gráfica.
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import pandas as pd


LOGGER = logging.getLogger("ecommerce_analytics")
PROJECT_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_INPUT = PROJECT_ROOT / "data" / "raw" / "Online Retail.xlsx"
DEFAULT_OUTPUT = PROJECT_ROOT / "data" / "processed"
DEFAULT_REPORTS = PROJECT_ROOT / "reports"

REQUIRED_COLUMNS = (
    "InvoiceNo",
    "StockCode",
    "Description",
    "Quantity",
    "InvoiceDate",
    "UnitPrice",
    "CustomerID",
    "Country",
)


# ---------------------------------------------------------------------------
# 1. Lectura y validación
# ---------------------------------------------------------------------------

def load_retail_data(file_path: Path) -> pd.DataFrame:
    """Carga una hoja de Excel o un CSV sin modificar el fichero original."""
    if not file_path.exists():
        raise FileNotFoundError(
            f"No existe el dataset: {file_path}\n"
            "Descarga 'Online Retail.xlsx' y guárdalo en data/raw/."
        )

    LOGGER.info("Cargando datos desde %s", file_path)
    extension = file_path.suffix.lower()

    if extension in {".xlsx", ".xls"}:
        frame = pd.read_excel(file_path)
    elif extension == ".csv":
        frame = pd.read_csv(file_path, low_memory=False)
    else:
        raise ValueError("Formato no admitido. Utiliza .xlsx, .xls o .csv")

    validate_schema(frame)
    LOGGER.info("Lectura completada: %s filas, %s columnas", *frame.shape)
    return frame


def validate_schema(frame: pd.DataFrame) -> None:
    """Informa si faltan columnas necesarias para el análisis."""
    missing_columns = sorted(set(REQUIRED_COLUMNS) - set(frame.columns))
    if missing_columns:
        raise ValueError(
            "El dataset no tiene todas las columnas esperadas: "
            + ", ".join(missing_columns)
        )


# ---------------------------------------------------------------------------
# 2. Preparación de tipos y columnas auxiliares
# ---------------------------------------------------------------------------

def prepare_retail_data(raw: pd.DataFrame) -> pd.DataFrame:
    """Normaliza tipos y añade banderas; conserva las filas originales."""
    validate_schema(raw)
    frame = raw.copy()

    # Los identificadores son etiquetas, no números que haya que sumar.
    for column in ("InvoiceNo", "StockCode", "CustomerID"):
        frame[column] = frame[column].astype("string").str.strip()

    # Excel puede leer identificadores numéricos como '17850.0'.
    frame["CustomerID"] = frame["CustomerID"].str.replace(
        r"\.0$", "", regex=True
    )

    for column in ("Description", "Country"):
        frame[column] = frame[column].astype("string").str.strip()
        frame[column] = frame[column].replace("", pd.NA)

    frame["Quantity"] = pd.to_numeric(frame["Quantity"], errors="coerce")
    frame["UnitPrice"] = pd.to_numeric(frame["UnitPrice"], errors="coerce")
    frame["InvoiceDate"] = pd.to_datetime(
        frame["InvoiceDate"], errors="coerce"
    )

    # En el dataset original los números de factura con 'C' indican cancelación.
    frame["IsCancellation"] = frame["InvoiceNo"].str.startswith(
        "C", na=False
    )
    frame["LineAmountGBP"] = frame["Quantity"] * frame["UnitPrice"]

    # No rechazamos por país o cliente desconocido: una venta puede ser válida
    # aunque esos atributos estén incompletos.
    frame["IsValidSale"] = (
        frame["InvoiceNo"].notna()
        & frame["InvoiceDate"].notna()
        & frame["Quantity"].gt(0)
        & frame["UnitPrice"].gt(0)
        & ~frame["IsCancellation"]
    )
    return frame


# ---------------------------------------------------------------------------
# 3. Calidad y trazabilidad
# ---------------------------------------------------------------------------

def analyze_quality(frame: pd.DataFrame) -> tuple[pd.DataFrame, pd.DataFrame]:
    """Devuelve un inventario de anomalías y el detalle de valores ausentes."""
    original_columns = list(REQUIRED_COLUMNS)
    missing = (
        frame[original_columns]
        .isna()
        .sum()
        .rename_axis("columna")
        .reset_index(name="valores_ausentes")
    )
    missing["porcentaje"] = (
        missing["valores_ausentes"] / max(len(frame), 1) * 100
    ).round(2)

    checks: dict[str, int] = {
        "filas_originales": len(frame),
        "facturas_distintas": frame["InvoiceNo"].nunique(dropna=True),
        "filas_duplicadas_exactas": int(
            frame[original_columns].duplicated().sum()
        ),
        "valores_ausentes_totales": int(missing["valores_ausentes"].sum()),
        "facturas_sin_identificador": int(frame["InvoiceNo"].isna().sum()),
        "fechas_invalidas_o_ausentes": int(frame["InvoiceDate"].isna().sum()),
        "clientes_sin_identificar": int(frame["CustomerID"].isna().sum()),
        "filas_con_cantidad_negativa": int(frame["Quantity"].lt(0).sum()),
        "filas_con_cantidad_cero": int(frame["Quantity"].eq(0).sum()),
        "filas_con_precio_negativo": int(frame["UnitPrice"].lt(0).sum()),
        "filas_con_precio_cero": int(frame["UnitPrice"].eq(0).sum()),
        "facturas_marcadas_como_cancelacion": int(
            frame.loc[frame["IsCancellation"], "InvoiceNo"].nunique()
        ),
        "lineas_marcadas_como_cancelacion": int(
            frame["IsCancellation"].sum()
        ),
        "lineas_de_venta_validas": int(frame["IsValidSale"].sum()),
        "lineas_excluidas_del_analisis_de_ventas": int(
            (~frame["IsValidSale"]).sum()
        ),
    }

    quality = pd.DataFrame(
        {"metrica": list(checks), "valor": list(checks.values())}
    )
    return quality, missing


# ---------------------------------------------------------------------------
# 4. Métricas y análisis comerciales
# ---------------------------------------------------------------------------

def select_sales(frame: pd.DataFrame) -> pd.DataFrame:
    """Extrae las líneas de venta positivas sin alterar el DataFrame base."""
    sales = frame.loc[frame["IsValidSale"]].copy()
    sales["Country"] = sales["Country"].fillna("Sin especificar")
    sales["Description"] = sales["Description"].fillna("Sin descripción")
    sales["StockCode"] = sales["StockCode"].fillna("Sin código")
    return sales


def calculate_kpis(sales: pd.DataFrame) -> pd.DataFrame:
    """Calcula indicadores básicos a partir de ventas brutas positivas."""
    unique_invoices = sales["InvoiceNo"].nunique()
    total_revenue = float(sales["LineAmountGBP"].sum())
    values: dict[str, Any] = {
        "lineas_de_venta": len(sales),
        "facturas_unicas": unique_invoices,
        "unidades_vendidas": float(sales["Quantity"].sum()),
        "facturacion_bruta_gbp": round(total_revenue, 2),
        "ticket_medio_por_factura_gbp": round(
            total_revenue / unique_invoices, 2
        ) if unique_invoices else 0.0,
        "clientes_identificados": sales["CustomerID"].nunique(dropna=True),
        "paises_distintos": sales["Country"].nunique(),
    }
    return pd.DataFrame(
        {"indicador": list(values), "valor": list(values.values())}
    )


def monthly_sales(sales: pd.DataFrame) -> pd.DataFrame:
    """Agrupa ingresos, unidades y facturas por mes de calendario."""
    prepared = sales.assign(
        mes=sales["InvoiceDate"].dt.to_period("M").astype("string")
    )
    result = prepared.groupby("mes", dropna=False).agg(
        ingresos_gbp=("LineAmountGBP", "sum"),
        unidades=("Quantity", "sum"),
        facturas=("InvoiceNo", "nunique"),
    ).reset_index()
    return result.sort_values("mes").round({"ingresos_gbp": 2})


def country_sales(sales: pd.DataFrame) -> pd.DataFrame:
    """Resumen de ventas por país, incluyendo país desconocido."""
    result = sales.groupby("Country", dropna=False).agg(
        ingresos_gbp=("LineAmountGBP", "sum"),
        unidades=("Quantity", "sum"),
        facturas=("InvoiceNo", "nunique"),
        clientes_identificados=("CustomerID", "nunique"),
    ).reset_index().rename(columns={"Country": "pais"})
    return (
        result.sort_values("ingresos_gbp", ascending=False)
        .reset_index(drop=True)
        .round({"ingresos_gbp": 2})
    )


def product_sales(sales: pd.DataFrame) -> pd.DataFrame:
    """Resumen por código y descripción; no presupone un catálogo limpio."""
    result = sales.groupby(
        ["StockCode", "Description"], dropna=False
    ).agg(
        ingresos_gbp=("LineAmountGBP", "sum"),
        unidades=("Quantity", "sum"),
        facturas=("InvoiceNo", "nunique"),
    ).reset_index().rename(columns={
        "StockCode": "codigo_producto",
        "Description": "descripcion",
    })
    return (
        result.sort_values("ingresos_gbp", ascending=False)
        .reset_index(drop=True)
        .round({"ingresos_gbp": 2})
    )


def customer_sales(sales: pd.DataFrame) -> pd.DataFrame:
    """Calcula frecuencia, gasto y recencia para clientes identificados."""
    identified = sales.loc[sales["CustomerID"].notna()].copy()
    if identified.empty:
        return pd.DataFrame(columns=[
            "cliente", "facturas", "unidades", "ingresos_gbp",
            "ultima_compra", "recencia_dias",
        ])

    result = identified.groupby("CustomerID").agg(
        facturas=("InvoiceNo", "nunique"),
        unidades=("Quantity", "sum"),
        ingresos_gbp=("LineAmountGBP", "sum"),
        ultima_compra=("InvoiceDate", "max"),
    ).reset_index().rename(columns={"CustomerID": "cliente"})

    # Fecha de referencia posterior al último registro del dataset.
    reference_date = identified["InvoiceDate"].max() + pd.Timedelta(days=1)
    result["recencia_dias"] = (
        reference_date - result["ultima_compra"]
    ).dt.days
    return (
        result.sort_values("ingresos_gbp", ascending=False)
        .reset_index(drop=True)
        .round({"ingresos_gbp": 2})
    )


def weekday_sales(sales: pd.DataFrame) -> pd.DataFrame:
    """Explora en qué días de la semana se registraron más ventas."""
    prepared = sales.assign(
        dia_semana=sales["InvoiceDate"].dt.dayofweek
    )
    result = prepared.groupby("dia_semana").agg(
        ingresos_gbp=("LineAmountGBP", "sum"),
        lineas=("InvoiceNo", "size"),
    ).reset_index()
    return result.sort_values("dia_semana").round({"ingresos_gbp": 2})


# ---------------------------------------------------------------------------
# 5. Exportaciones e informes
# ---------------------------------------------------------------------------

def save_csv(frame: pd.DataFrame, destination: Path) -> None:
    """Exporta una tabla en UTF-8 compatible con herramientas habituales."""
    destination.parent.mkdir(parents=True, exist_ok=True)
    frame.to_csv(destination, index=False, encoding="utf-8-sig")
    LOGGER.info("Exportado: %s (%s filas)", destination, len(frame))


def as_metric_map(kpis: pd.DataFrame) -> dict[str, Any]:
    """Convierte la tabla de indicadores en un diccionario para el informe."""
    return dict(zip(kpis["indicador"], kpis["valor"]))


def write_markdown_report(
    destination: Path,
    source: Path,
    prepared: pd.DataFrame,
    quality: pd.DataFrame,
    kpis: pd.DataFrame,
    countries: pd.DataFrame,
    products: pd.DataFrame,
) -> None:
    """Genera un resumen legible y deja documentadas las limitaciones."""
    destination.parent.mkdir(parents=True, exist_ok=True)
    metrics = as_metric_map(kpis)

    first_date = prepared["InvoiceDate"].min()
    last_date = prepared["InvoiceDate"].max()
    if pd.isna(first_date) or pd.isna(last_date):
        date_span = "Sin fechas válidas"
    else:
        date_span = f"{first_date:%Y-%m-%d} a {last_date:%Y-%m-%d}"

    lines = [
        "# E-Commerce Analytics — Informe exploratorio",
        "",
        f"**Origen:** `{source.name}`",
        f"**Periodo observado:** {date_span}",
        "**Divisa:** GBP (libras esterlinas)",
        "",
        "## Indicadores de ventas positivas",
        "",
        f"- Líneas de venta: {int(metrics['lineas_de_venta']):,}",
        f"- Facturas distintas: {int(metrics['facturas_unicas']):,}",
        f"- Facturación bruta: £{metrics['facturacion_bruta_gbp']:,.2f}",
        f"- Ticket medio por factura: £{metrics['ticket_medio_por_factura_gbp']:,.2f}",
        f"- Clientes identificados: {int(metrics['clientes_identificados']):,}",
        "",
        "## Calidad de los datos",
        "",
        "| Comprobación | Resultado |",
        "|---|---:|",
    ]
    for metric, value in quality.itertuples(index=False, name=None):
        lines.append(f"| {metric} | {value:,} |")

    lines.extend(["", "## Países con mayores ventas", "", "| País | GBP |", "|---|---:|"])
    for row in countries.head(5).itertuples(index=False):
        lines.append(f"| {row.pais} | £{row.ingresos_gbp:,.2f} |")

    lines.extend(["", "## Productos con mayores ventas", "", "| Producto | GBP |", "|---|---:|"])
    for row in products.head(5).itertuples(index=False):
        name = str(row.descripcion).replace("|", "/").replace("\n", " ")
        lines.append(f"| {name} | £{row.ingresos_gbp:,.2f} |")

    lines.extend([
        "",
        "## Criterios y limitaciones",
        "",
        "- Se contabilizan únicamente líneas con factura, fecha, cantidad positiva",
        "  y precio unitario positivo que no estén marcadas como cancelación.",
        "- Los duplicados exactos se señalan, pero no se eliminan automáticamente.",
        "- No se atribuye un país ni cliente ficticio a los registros incompletos.",
        "- Esta facturación es **bruta**: no descuenta devoluciones, impuestos",
        "  ni costes. No representa beneficio empresarial.",
        "- Las facturas pueden contener varias líneas: contar filas no es contar pedidos.",
        "- Las ventas históricas no describen el mercado actual.",
        "",
        "**Fuente:** UCI Online Retail, https://doi.org/10.24432/C5BW33",
        "",
    ])
    destination.write_text("\n".join(lines), encoding="utf-8")
    LOGGER.info("Informe Markdown: %s", destination)


# ---------------------------------------------------------------------------
# 6. Visualizaciones reproducibles
# ---------------------------------------------------------------------------

def export_charts(
    monthly: pd.DataFrame,
    countries: pd.DataFrame,
    products: pd.DataFrame,
    destination: Path,
) -> None:
    """Crea gráficos PNG para el README y futuras presentaciones."""
    destination.mkdir(parents=True, exist_ok=True)

    if not monthly.empty:
        fig, ax = plt.subplots(figsize=(11, 5))
        positions = list(range(len(monthly)))
        ax.plot(positions, monthly["ingresos_gbp"], marker="o")
        ax.set_xticks(positions, monthly["mes"].tolist())
        ax.set_title("Evolución mensual de ventas positivas")
        ax.set_ylabel("Facturación bruta (£)")
        ax.set_xlabel("Mes")
        ax.tick_params(axis="x", rotation=55)
        ax.grid(axis="y", alpha=0.25)
        fig.tight_layout()
        fig.savefig(destination / "ventas_mensuales.png", dpi=150)
        plt.close(fig)

    if not countries.empty:
        top = countries.head(10).iloc[::-1]
        fig, ax = plt.subplots(figsize=(10, 6))
        ax.barh(top["pais"], top["ingresos_gbp"])
        ax.set_title("Países con mayor facturación bruta")
        ax.set_xlabel("Facturación (£)")
        fig.tight_layout()
        fig.savefig(destination / "top_paises.png", dpi=150)
        plt.close(fig)

    if not products.empty:
        top = products.head(10).iloc[::-1]
        labels = top["descripcion"].astype(str).str.slice(0, 34)
        fig, ax = plt.subplots(figsize=(11, 6))
        ax.barh(labels, top["ingresos_gbp"])
        ax.set_title("Productos con mayor facturación bruta")
        ax.set_xlabel("Facturación (£)")
        fig.tight_layout()
        fig.savefig(destination / "top_productos.png", dpi=150)
        plt.close(fig)

    LOGGER.info("Gráficos generados en %s", destination)


# ---------------------------------------------------------------------------
# 7. Flujo principal y argumentos de ejecución
# ---------------------------------------------------------------------------

def run_pipeline(
    source: Path,
    processed_dir: Path,
    reports_dir: Path,
    charts: bool = True,
    export_detail: bool = False,
) -> dict[str, pd.DataFrame]:
    """Ejecuta la preparación, auditoría, agregación y exportaciones."""
    raw = load_retail_data(source)
    prepared = prepare_retail_data(raw)
    quality, missing = analyze_quality(prepared)
    sales = select_sales(prepared)

    LOGGER.info("Líneas de venta válidas: %s", len(sales))
    kpis = calculate_kpis(sales)
    monthly = monthly_sales(sales)
    countries = country_sales(sales)
    products = product_sales(sales)
    customers = customer_sales(sales)
    weekdays = weekday_sales(sales)

    tables = {
        "resumen_calidad": quality,
        "nulos_por_columna": missing,
        "indicadores": kpis,
        "ventas_mensuales": monthly,
        "ventas_por_pais": countries,
        "ventas_por_producto": products,
        "ventas_por_cliente": customers,
        "ventas_por_dia_semana": weekdays,
    }
    for name, frame in tables.items():
        save_csv(frame, processed_dir / f"{name}.csv")

    if export_detail:
        save_csv(sales, processed_dir / "detalle_ventas_validas.csv")

    write_markdown_report(
        reports_dir / "informe_exploratorio.md",
        source, prepared, quality, kpis, countries, products,
    )
    if charts:
        export_charts(monthly, countries, products, reports_dir / "figures")

    LOGGER.info("Análisis terminado sin modificar el archivo original.")
    return tables


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Explora ventas del dataset UCI Online Retail con Pandas."
    )
    parser.add_argument(
        "--input", type=Path, default=DEFAULT_INPUT,
        help="Archivo de entrada .xlsx o .csv",
    )
    parser.add_argument(
        "--output", type=Path, default=DEFAULT_OUTPUT,
        help="Directorio de tablas CSV generadas",
    )
    parser.add_argument(
        "--reports", type=Path, default=DEFAULT_REPORTS,
        help="Directorio de informes Markdown y gráficos",
    )
    parser.add_argument(
        "--no-charts", action="store_true",
        help="No generar gráficos PNG",
    )
    parser.add_argument(
        "--export-detail", action="store_true",
        help="Exportar también todas las líneas de venta válidas",
    )
    return parser.parse_args()


def main() -> None:
    logging.basicConfig(level=logging.INFO, format="%(levelname)s | %(message)s")
    args = parse_args()
    run_pipeline(
        source=args.input,
        processed_dir=args.output,
        reports_dir=args.reports,
        charts=not args.no_charts,
        export_detail=args.export_detail,
    )


if __name__ == "__main__":
    main()
