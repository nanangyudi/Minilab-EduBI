#!/bin/bash
# =============================================================
# run_etl.sh
# Jalankan pipeline ETL Minilab EduBI
# Usage: bash scripts/run_etl.sh
# =============================================================

set -e  # Hentikan script jika ada error

echo "============================================"
echo " Minilab EduBI - ETL Pipeline"
echo "============================================"

# Pastikan berada di root direktori proyek
cd "$(dirname "$0")/.."

# Jalankan pipeline utama
echo "[1/1] Menjalankan run_pipeline.py..."
python etl/run_pipeline.py

echo ""
echo "ETL selesai. File DuckDB tersedia di: data/warehouse/lab_bi.duckdb"
