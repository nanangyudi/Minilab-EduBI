"""
utils.py
Fungsi-fungsi helper yang digunakan oleh modul ETL lain.
"""

import os
import logging
import clickhouse_connect
import psycopg2
from dotenv import load_dotenv

load_dotenv()

# ─────────────────────────────────────────────
# Logging
# ─────────────────────────────────────────────

def get_logger(name: str) -> logging.Logger:
    """Buat logger dengan format standar."""
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )
    return logging.getLogger(name)


# ─────────────────────────────────────────────
# ClickHouse — Data Warehouse
# ─────────────────────────────────────────────

def get_ch_client() -> clickhouse_connect.driver.Client:
    """Buka koneksi ke ClickHouse via HTTP interface."""
    return clickhouse_connect.get_client(
        host=os.getenv("CH_HOST", "localhost"),
        port=int(os.getenv("CH_PORT", "8123")),
        username=os.getenv("CH_USER", "default"),
        password=os.getenv("CH_PASSWORD", ""),
    )


# ─────────────────────────────────────────────
# PostgreSQL — Simulasi Odoo ERP
# ─────────────────────────────────────────────

def get_pg_conn(schema: str = "public") -> psycopg2.extensions.connection:
    """
    Buka koneksi ke PostgreSQL menggunakan env vars:
      PG_HOST, PG_PORT, PG_DB, PG_USER, PG_PASSWORD
    """
    return psycopg2.connect(
        host=os.getenv("PG_HOST", "localhost"),
        port=int(os.getenv("PG_PORT", "5432")),
        dbname=os.getenv("PG_DB", "minilab"),
        user=os.getenv("PG_USER", "minilab"),
        password=os.getenv("PG_PASSWORD", "minilab123"),
        options=f"-c search_path={schema}",
    )
