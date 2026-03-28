"""
run_pipeline.py
Orchestrator ETL untuk Minilab EduBI.
Urutan:
  1. init_duckdb  — siapkan file DuckDB dan schema
  2. load_csv     — load sample CSV ke bronze DuckDB
  3. (opsional) extract_odoo — load dari PG odoo_sim ke bronze
"""

import os
import sys
from utils import get_logger

log = get_logger("run_pipeline")

USE_POSTGRES = os.getenv("USE_POSTGRES_SOURCE", "false").lower() == "true"


def run():
    log.info("=" * 50)
    log.info("  Minilab EduBI — ETL Pipeline")
    log.info("=" * 50)

    # Step 1: Inisialisasi DuckDB
    log.info("[Step 1/3] Inisialisasi DuckDB...")
    from init_duckdb import init_database
    init_database()

    # Step 2: Load CSV ke bronze
    log.info("[Step 2/3] Load CSV sample ke bronze...")
    from load_csv import load_all
    load_all()

    # Step 3 (opsional): Extract dari PostgreSQL odoo_sim
    if USE_POSTGRES:
        log.info("[Step 3/3] Extract dari PostgreSQL odoo_sim...")
        try:
            from extract_odoo import extract_customers, extract_sales
            extract_customers()
            extract_sales()
        except Exception as e:
            log.warning(f"Skip extract_odoo (koneksi gagal): {e}")
    else:
        log.info("[Step 3/3] Skip extract_odoo (USE_POSTGRES_SOURCE=false)")

    log.info("=" * 50)
    log.info("  Pipeline ETL selesai.")
    log.info("=" * 50)


if __name__ == "__main__":
    # Pastikan import berjalan dari folder etl/
    sys.path.insert(0, os.path.dirname(__file__))
    run()
