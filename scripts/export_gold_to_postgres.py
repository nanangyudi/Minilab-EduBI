"""
export_gold_to_postgres.py
Export tabel Gold dari DuckDB ke PostgreSQL schema 'analytics'.
Tujuannya: Metabase dapat membaca hasil Gold dari PostgreSQL
karena DuckDB tidak mendukung koneksi network langsung.

Dijalankan setelah: dbt run selesai
"""

import os
import sys
import duckdb
import pandas as pd
from sqlalchemy import create_engine, text

# Pastikan etl/ ada di path agar utils bisa diimport
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "etl"))
from utils import get_pg_dsn, get_logger

log = get_logger("export_gold")

DB_PATH = os.getenv("DUCKDB_PATH", "data/warehouse/lab_bi.duckdb")

# Tabel Gold yang akan diekspor ke PG analytics
GOLD_TABLES = [
    "gold.gold_sales_daily",
    "gold.gold_branch_kpi",
    "gold.gold_review_summary",
]


def export_table(duck_con: duckdb.DuckDBPyConnection, engine, table_full: str):
    """Export satu tabel Gold DuckDB → PG analytics."""
    schema, table_name = table_full.split(".")
    df = duck_con.execute(f"SELECT * FROM {table_full}").fetchdf()

    if df.empty:
        log.warning(f"Tabel {table_full} kosong, skip.")
        return

    # Tulis ke PG schema analytics, ganti tabel jika sudah ada
    df.to_sql(
        name=table_name,
        con=engine,
        schema="analytics",
        if_exists="replace",
        index=False,
        method="multi",
        chunksize=500,
    )
    log.info(f"Export {len(df):>5} baris: {table_full} → analytics.{table_name}")


def main():
    log.info("=" * 50)
    log.info("  Export Gold → PostgreSQL analytics")
    log.info("=" * 50)

    if not os.path.exists(DB_PATH):
        log.error(f"File DuckDB tidak ditemukan: {DB_PATH}")
        log.error("Jalankan ETL dan dbt terlebih dahulu.")
        sys.exit(1)

    duck_con = duckdb.connect(DB_PATH, read_only=True)
    engine   = create_engine(get_pg_dsn())

    # Pastikan schema analytics sudah ada
    with engine.connect() as conn:
        conn.execute(text("CREATE SCHEMA IF NOT EXISTS analytics"))
        conn.commit()

    for table in GOLD_TABLES:
        try:
            export_table(duck_con, engine, table)
        except Exception as e:
            log.error(f"Gagal export {table}: {e}")

    duck_con.close()
    engine.dispose()

    log.info("=" * 50)
    log.info("  Export selesai.")
    log.info("=" * 50)


if __name__ == "__main__":
    main()
