"""
load_csv.py
Load file CSV sample dari data/raw/ ke tabel bronze di DuckDB.
File ini adalah sumber data utama untuk PoC (menggantikan koneksi Odoo langsung).
"""

import os
from utils import get_duckdb_conn, get_logger

log = get_logger("load_csv")

RAW_DIR = os.getenv("RAW_DIR", "data/raw")

# Mapping: nama file CSV → nama tabel bronze di DuckDB
CSV_TABLE_MAP = {
    "sample_sales.csv":     "bronze.sales",
    "sample_customers.csv": "bronze.customers",
    "sample_reviews.csv":   "bronze.reviews",
    "sample_targets.csv":   "bronze.targets",
}


def load_all():
    con = get_duckdb_conn()
    con.execute("CREATE SCHEMA IF NOT EXISTS bronze")

    for filename, table in CSV_TABLE_MAP.items():
        filepath = os.path.join(RAW_DIR, filename)
        if not os.path.exists(filepath):
            log.warning(f"File tidak ditemukan, skip: {filepath}")
            continue

        con.execute(
            f"CREATE OR REPLACE TABLE {table} AS "
            f"SELECT * FROM read_csv_auto('{filepath}', header=true)"
        )
        count = con.execute(f"SELECT COUNT(*) FROM {table}").fetchone()[0]
        log.info(f"Loaded {count:>4} baris → {table}")

    con.close()


if __name__ == "__main__":
    load_all()
