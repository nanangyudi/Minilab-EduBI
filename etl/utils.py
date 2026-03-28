"""
utils.py
Fungsi-fungsi helper yang digunakan oleh modul ETL lain.
"""

import os
import logging
import duckdb
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
# DuckDB
# ─────────────────────────────────────────────

DB_PATH = os.getenv("DUCKDB_PATH", "data/warehouse/lab_bi.duckdb")


def get_duckdb_conn() -> duckdb.DuckDBPyConnection:
    """Buka koneksi ke file DuckDB."""
    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)
    return duckdb.connect(DB_PATH)


# ─────────────────────────────────────────────
# PostgreSQL
# ─────────────────────────────────────────────

def get_pg_conn(schema: str = "public") -> psycopg2.extensions.connection:
    """
    Buka koneksi ke PostgreSQL menggunakan env vars:
      PG_HOST, PG_PORT, PG_DB, PG_USER, PG_PASSWORD
    """
    conn = psycopg2.connect(
        host=os.getenv("PG_HOST", "localhost"),
        port=int(os.getenv("PG_PORT", "5432")),
        dbname=os.getenv("PG_DB", "minilab"),
        user=os.getenv("PG_USER", "minilab"),
        password=os.getenv("PG_PASSWORD", "minilab123"),
        options=f"-c search_path={schema}",
    )
    return conn


def get_pg_dsn() -> str:
    """Return DSN string untuk SQLAlchemy."""
    host = os.getenv("PG_HOST", "localhost")
    port = os.getenv("PG_PORT", "5432")
    db   = os.getenv("PG_DB", "minilab")
    user = os.getenv("PG_USER", "minilab")
    pw   = os.getenv("PG_PASSWORD", "minilab123")
    return f"postgresql+psycopg2://{user}:{pw}@{host}:{port}/{db}"
