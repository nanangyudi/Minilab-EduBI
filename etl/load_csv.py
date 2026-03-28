"""
load_csv.py
Load file CSV dari data/raw ke tabel bronze di DuckDB.
"""

import duckdb
import os

DB_PATH = "data/warehouse/lab_bi.duckdb"
RAW_DIR = "data/raw"

CSV_TABLE_MAP = {
    "sales_orders.csv": "bronze.sales_orders",
    "customers.csv": "bronze.customers",
    "google_reviews.csv": "bronze.google_reviews",
}


def load_csv_to_bronze():
    con = duckdb.connect(DB_PATH)
    con.execute("CREATE SCHEMA IF NOT EXISTS bronze")

    for filename, table in CSV_TABLE_MAP.items():
        filepath = os.path.join(RAW_DIR, filename)
        if not os.path.exists(filepath):
            print(f"Skipping {filename}: file not found.")
            continue

        con.execute(f"CREATE OR REPLACE TABLE {table} AS SELECT * FROM read_csv_auto('{filepath}')")
        count = con.execute(f"SELECT COUNT(*) FROM {table}").fetchone()[0]
        print(f"Loaded {count} rows into {table}.")

    con.close()


if __name__ == "__main__":
    load_csv_to_bronze()
