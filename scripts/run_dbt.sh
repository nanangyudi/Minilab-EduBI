#!/bin/bash
# =============================================================
# run_dbt.sh
# Jalankan transformasi dbt untuk Minilab EduBI
# Mengeksekusi TAHAP 3 (Silver) dan TAHAP 4 (Gold) secara eksplisit.
# Usage: bash scripts/run_dbt.sh
# =============================================================

set -e

echo "============================================"
echo " Minilab EduBI - dbt Transformations"
echo " Target: ClickHouse (bronze → silver → gold)"
echo "============================================"

# Pastikan berada di root direktori proyek
cd "$(dirname "$0")/.."

# Salin profiles jika belum ada
if [ ! -f dbt_project/profiles.yml ]; then
    echo "Menyalin profiles.yml dari contoh..."
    cp dbt_project/profiles.yml.example dbt_project/profiles.yml
fi

cd dbt_project

echo ""
echo "[0] dbt deps (unduh packages)..."
dbt deps --profiles-dir .

echo ""
echo "┌─────────────────────────────────────────────┐"
echo "│  Bronze dbt models (mirror sumber ETL)       │"
echo "└─────────────────────────────────────────────┘"
dbt run --select path:models/bronze --profiles-dir .

echo ""
echo "┌─────────────────────────────────────────────┐"
echo "│  TAHAP 3 — Transform ke Silver (ClickHouse)  │"
echo "└─────────────────────────────────────────────┘"
dbt run --select path:models/silver --profiles-dir .

echo ""
echo "┌─────────────────────────────────────────────┐"
echo "│  TAHAP 4 — Transform ke Gold (ClickHouse)    │"
echo "└─────────────────────────────────────────────┘"
dbt run --select path:models/gold --profiles-dir .

echo ""
echo "┌─────────────────────────────────────────────┐"
echo "│  Validasi dbt Tests                          │"
echo "└─────────────────────────────────────────────┘"
dbt test --profiles-dir .

echo ""
echo "dbt selesai."
echo "  Silver layer: silver.silver_sales, silver_customers, silver_reviews, silver_targets"
echo "  Gold layer  : gold.gold_sales_daily, gold_branch_kpi, gold_review_summary"
echo ""
echo "  TAHAP 5 — Visualisasi: buka http://localhost:3000 (Metabase)"
