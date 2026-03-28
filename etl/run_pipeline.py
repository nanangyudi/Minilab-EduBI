"""
run_pipeline.py
Orchestrator pipeline data Minilab EduBI.

Mensimulasikan alur kerja ELT end-to-end:

  TAHAP 0 — Init        : Siapkan database ClickHouse (bronze/silver/gold)
  TAHAP 1 — Extract     : Ambil data dari semua sumber ke data/raw/
    1A. Odoo ERP        : Query PostgreSQL odoo_sim → CSV
    1B. Google Reviews  : Ambil via API (atau fallback CSV sample)
    1C. Manual CSV/XLS  : File sudah ada di data/raw/ (tidak perlu aksi)
  TAHAP 2 — Load Bronze : Muat semua CSV dari data/raw/ → ClickHouse bronze.*

  [TAHAP 3 Silver + TAHAP 4 Gold + TAHAP 5 Metabase → jalankan via dbt service]
"""

import os
import sys
from utils import get_logger

log = get_logger("run_pipeline")

SEPARATOR = "=" * 52


def _header(title: str):
    log.info(SEPARATOR)
    log.info(f"  {title}")
    log.info(SEPARATOR)


def stage_0_init():
    """Siapkan database ClickHouse."""
    log.info("")
    log.info("┌─────────────────────────────────────────────┐")
    log.info("│  TAHAP 0 — Inisialisasi ClickHouse           │")
    log.info("└─────────────────────────────────────────────┘")
    from init_clickhouse import init_database
    init_database()


def stage_1a_extract_odoo():
    """
    TAHAP 1A — Extract dari Odoo ERP (simulasi via PostgreSQL odoo_sim).
    Hasil disimpan ke data/raw/odoo_customers.csv dan data/raw/odoo_sales.csv.
    """
    log.info("")
    log.info("┌─────────────────────────────────────────────┐")
    log.info("│  TAHAP 1A — Extract Odoo (PostgreSQL)        │")
    log.info("└─────────────────────────────────────────────┘")
    try:
        from extract_odoo import extract_customers, extract_sales
        extract_customers()
        extract_sales()
    except Exception as e:
        log.warning(f"  Koneksi Odoo/PG gagal → skip: {e}")
        log.warning("  Akan menggunakan sample_customers.csv dan sample_sales.csv.")


def stage_1b_extract_reviews():
    """
    TAHAP 1B — Extract Google Reviews.
    Jika API key dikonfigurasi → ambil dari API.
    Jika tidak → gunakan sample_reviews.csv sebagai simulasi.
    """
    log.info("")
    log.info("┌─────────────────────────────────────────────┐")
    log.info("│  TAHAP 1B — Extract Google Reviews           │")
    log.info("└─────────────────────────────────────────────┘")
    from extract_google_reviews import extract_reviews
    extract_reviews()


def stage_1c_manual_csv():
    """
    TAHAP 1C — File CSV/XLS manual.
    File sudah tersedia di data/raw/ — tidak perlu aksi download.
    Menampilkan daftar file yang siap dimuat.
    """
    import os
    raw_dir = os.getenv("RAW_DIR", "data/raw")
    manual_files = [
        "sample_sales.csv",
        "sample_customers.csv",
        "sample_targets.csv",
    ]

    log.info("")
    log.info("┌─────────────────────────────────────────────┐")
    log.info("│  TAHAP 1C — File Manual CSV/XLS              │")
    log.info("└─────────────────────────────────────────────┘")
    log.info("  File berikut tersedia di data/raw/ (input manual):")
    for fname in manual_files:
        fpath = os.path.join(raw_dir, fname)
        if os.path.exists(fpath):
            import pandas as pd
            n = len(pd.read_csv(fpath))
            log.info(f"    ✓ {fname} ({n} baris)")
        else:
            log.warning(f"    ✗ {fname} tidak ditemukan")


def stage_2_load_bronze():
    """
    TAHAP 2 — Load ke Bronze ClickHouse.
    Muat semua file CSV dari data/raw/ ke ClickHouse bronze.*.
    Prioritas: file hasil Extract Odoo > sample fallback.
    """
    log.info("")
    log.info("┌─────────────────────────────────────────────┐")
    log.info("│  TAHAP 2 — Load ke Bronze (ClickHouse)       │")
    log.info("└─────────────────────────────────────────────┘")
    from load_csv import load_all
    load_all()


def run():
    _header("Minilab EduBI — Data Pipeline")
    log.info("  Alur: Extract → Load Bronze → [dbt: Silver → Gold → Metabase]")

    stage_0_init()
    stage_1a_extract_odoo()
    stage_1b_extract_reviews()
    stage_1c_manual_csv()
    stage_2_load_bronze()

    log.info("")
    log.info("┌─────────────────────────────────────────────┐")
    log.info("│  SELESAI: Extract + Load Bronze              │")
    log.info("│                                             │")
    log.info("│  Tahap selanjutnya — jalankan:               │")
    log.info("│    docker compose run --rm dbt               │")
    log.info("│  untuk Transform Silver, Gold, dan           │")
    log.info("│  membuka dashboard di Metabase.              │")
    log.info("└─────────────────────────────────────────────┘")


if __name__ == "__main__":
    sys.path.insert(0, os.path.dirname(__file__))
    run()
