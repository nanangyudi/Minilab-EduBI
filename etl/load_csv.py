"""
load_csv.py
Load file CSV dari data/raw/ ke tabel bronze di ClickHouse.

Prioritas sumber per tabel:
  bronze.customers → odoo_customers.csv (hasil extract Odoo)
                     fallback: sample_customers.csv
  bronze.sales     → odoo_sales.csv     (hasil extract Odoo)
                     fallback: sample_sales.csv
  bronze.reviews   → google_reviews.csv (hasil extract Google API)
                     fallback: sample_reviews.csv
  bronze.targets   → sample_targets.csv (selalu pakai sample)

Semua kolom disimpan sebagai String di Bronze (raw data).
Casting ke tipe yang tepat dilakukan di Silver oleh dbt.
"""

import os
import pandas as pd
from utils import get_ch_client, get_logger

log = get_logger("load_csv")

RAW_DIR = os.getenv("RAW_DIR", "data/raw")

# DDL tabel bronze — semua kolom String (raw layer)
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

# Sumber file per tabel: (file_prioritas, file_fallback)
# Jika file_prioritas ada → gunakan itu; jika tidak → gunakan fallback
TABLE_SOURCES = {
    "bronze.customers": ("odoo_customers.csv", "sample_customers.csv"),
    "bronze.sales":     ("odoo_sales.csv",      "sample_sales.csv"),
    "bronze.reviews":   ("google_reviews.csv",  "sample_reviews.csv"),
    "bronze.targets":   (None,                  "sample_targets.csv"),
}


def _resolve_source(table: str) -> tuple[str, str]:
    """Return (filepath, label) untuk tabel yang diberikan."""
    primary, fallback = TABLE_SOURCES[table]

    if primary:
        primary_path = os.path.join(RAW_DIR, primary)
        if os.path.exists(primary_path):
            return primary_path, f"[extracted] {primary}"

    fallback_path = os.path.join(RAW_DIR, fallback)
    return fallback_path, f"[sample]    {fallback}"


def load_all():
    client = get_ch_client()

    # Pastikan semua tabel bronze sudah ada
    for table, ddl in TABLES_DDL.items():
        client.command(ddl)

    for table in TABLE_SOURCES:
        filepath, label = _resolve_source(table)

        if not os.path.exists(filepath):
            log.warning(f"  Tidak ada file untuk {table}, skip.")
            continue

        df = pd.read_csv(filepath, dtype=str).fillna("")

        # Truncate lalu insert (idempotent)
        client.command(f"TRUNCATE TABLE IF EXISTS {table}")
        client.insert_df(table, df)

        count = client.query(f"SELECT count() FROM {table}").result_rows[0][0]
        log.info(f"  {count:>4} baris → {table:<22} ← {label}")
