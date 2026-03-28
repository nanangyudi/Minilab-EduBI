"""
load_csv.py
Load file CSV sample dari data/raw/ ke tabel bronze di ClickHouse.
Semua kolom disimpan sebagai String di layer Bronze (raw data).
Casting ke tipe yang tepat dilakukan di layer Silver oleh dbt.
"""

import os
import pandas as pd
from utils import get_ch_client, get_logger

log = get_logger("load_csv")

RAW_DIR = os.getenv("RAW_DIR", "data/raw")

# DDL untuk setiap tabel bronze di ClickHouse
# Semua kolom String — Silver layer yang melakukan casting
TABLES_DDL = {
    "bronze.sales": """
        CREATE TABLE IF NOT EXISTS bronze.sales (
            order_id      String,
            customer_id   String,
            product_name  String,
            category      String,
            quantity      String,
            unit_price    String,
            total_price   String,
            order_date    String,
            branch        String,
            status        String
        ) ENGINE = MergeTree()
        ORDER BY (order_date, order_id)
    """,
    "bronze.customers": """
        CREATE TABLE IF NOT EXISTS bronze.customers (
            customer_id     String,
            name            String,
            email           String,
            phone           String,
            city            String,
            branch          String,
            customer_since  String
        ) ENGINE = MergeTree()
        ORDER BY customer_id
    """,
    "bronze.reviews": """
        CREATE TABLE IF NOT EXISTS bronze.reviews (
            review_id    String,
            author       String,
            rating       String,
            text         String,
            review_date  String,
            branch       String,
            source       String
        ) ENGINE = MergeTree()
        ORDER BY (review_date, review_id)
    """,
    "bronze.targets": """
        CREATE TABLE IF NOT EXISTS bronze.targets (
            target_id     String,
            branch        String,
            month         String,
            year          String,
            sales_target  String,
            order_target  String
        ) ENGINE = MergeTree()
        ORDER BY (year, month, branch)
    """,
}

# Mapping: nama file CSV → nama tabel bronze
CSV_TABLE_MAP = {
    "sample_sales.csv":     "bronze.sales",
    "sample_customers.csv": "bronze.customers",
    "sample_reviews.csv":   "bronze.reviews",
    "sample_targets.csv":   "bronze.targets",
}


def load_all():
    client = get_ch_client()

    for table, ddl in TABLES_DDL.items():
        client.command(ddl)

    for filename, table in CSV_TABLE_MAP.items():
        filepath = os.path.join(RAW_DIR, filename)
        if not os.path.exists(filepath):
            log.warning(f"File tidak ditemukan, skip: {filepath}")
            continue

        df = pd.read_csv(filepath, dtype=str)  # baca semua sebagai string (bronze = raw)
        df = df.fillna("")                      # ganti NaN dengan string kosong

        # Hapus data lama lalu insert ulang (idempotent)
        db, tbl = table.split(".")
        client.command(f"TRUNCATE TABLE IF EXISTS {table}")
        client.insert_df(table, df)

        count = client.query(f"SELECT count() FROM {table}").result_rows[0][0]
        log.info(f"Loaded {count:>4} baris → {table}")


if __name__ == "__main__":
    load_all()
