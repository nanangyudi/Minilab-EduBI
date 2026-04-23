"""
run_pipeline.py
Orchestrator pipeline data Minilab EduBI.

Mensimulasikan alur kerja ELT end-to-end:

  DATASET=standard (default — Toko Elektronik):
    TAHAP 0 — Init        : Siapkan database ClickHouse (bronze/silver/gold)
    TAHAP 1A              : Extract Odoo ERP (PostgreSQL odoo_sim) → CSV
    TAHAP 1B              : Extract Google Reviews (API / fallback CSV)
    TAHAP 1C              : File CSV manual (sudah ada di data/raw/)
    TAHAP 2               : Load semua CSV → ClickHouse bronze.*

  DATASET=olist (Olist Brazilian E-Commerce):
    TAHAP 0               : Siapkan database ClickHouse
    TAHAP 2               : Load CSV Olist dari data/raw/olist/ → ClickHouse bronze.olist_*
    (TAHAP 1 Extract tidak diperlukan — CSV sudah diunduh manual dari Kaggle)

  [TAHAP 3 Silver + TAHAP 4 Gold + TAHAP 5 Metabase → jalankan via dbt service]

Env vars:
  DATASET  : "standard" (default) | "olist"
"""

import os
import sys
from utils import get_logger

log = get_logger("run_pipeline")

SEPARATOR = "=" * 52
DATASET   = os.getenv("DATASET", "standard")


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
    TAHAP 2 — Load ke Bronze ClickHouse (mode standard).
    Muat semua file CSV dari data/raw/ ke ClickHouse bronze.*.
    Prioritas: file hasil Extract Odoo > sample fallback.
    """
    log.info("")
    log.info("┌─────────────────────────────────────────────┐")
    log.info("│  TAHAP 2 — Load ke Bronze (ClickHouse)       │")
    log.info("└─────────────────────────────────────────────┘")
    from load_csv import load_all
    load_all()


def stage_2_load_olist():
    """
    TAHAP 2 — Load CSV Olist ke Bronze ClickHouse (mode olist).
    Muat 8 file CSV dari data/raw/olist/ ke ClickHouse bronze.olist_*.
    File harus diunduh manual dari Kaggle sebelum menjalankan ini.
    """
    log.info("")
    log.info("┌─────────────────────────────────────────────┐")
    log.info("│  TAHAP 2 — Load Olist ke Bronze (ClickHouse) │")
    log.info("└─────────────────────────────────────────────┘")
    from load_olist import load_all
    ok = load_all()
    if not ok:
        log.error(
            "  File Olist tidak ditemukan di data/raw/olist/. "
            "Download dari https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce "
            "dan ekstrak ke data/raw/olist/ sebelum melanjutkan."
        )
        sys.exit(1)


def run():
    if DATASET == "olist":
        _header("Minilab EduBI — Olist E-Commerce Pipeline")
        log.info("  Dataset : Olist Brazilian E-Commerce (Kaggle)")
        log.info("  Alur    : Load Bronze → [dbt: Silver → Gold → Metabase]")
        stage_0_init()
        stage_2_load_olist()
    else:
        _header("Minilab EduBI — Data Pipeline")
        log.info("  Dataset : Toko Elektronik (standard)")
        log.info("  Alur: Extract → Load Bronze → [dbt: Silver → Gold → Metabase]")
        stage_0_init()
        stage_1a_extract_odoo()
        stage_1b_extract_reviews()
        stage_1c_manual_csv()
        stage_2_load_bronze()

    log.info("")
    log.info("┌─────────────────────────────────────────────┐")
    log.info("│  SELESAI: Load Bronze                        │")
    log.info("│                                             │")
    log.info("│  Tahap selanjutnya — jalankan:               │")
    log.info("│    docker compose run --rm dbt               │")
    log.info("│  untuk Transform Silver, Gold, dan           │")
    log.info("│  membuka dashboard di Metabase.              │")
    log.info("└─────────────────────────────────────────────┘")


if __name__ == "__main__":
    sys.path.insert(0, os.path.dirname(__file__))
    run()
