#!/bin/bash
# =============================================================
# run_dbt.sh
# Jalankan transformasi dbt untuk Minilab EduBI
# Usage: bash scripts/run_dbt.sh
# =============================================================

set -e

echo "============================================"
echo " Minilab EduBI - dbt Transformations"
echo "============================================"

# Pastikan berada di root direktori proyek
cd "$(dirname "$0")/.."

# Salin profiles jika belum ada
if [ ! -f dbt_project/profiles.yml ]; then
    echo "Menyalin profiles.yml dari contoh..."
    cp dbt_project/profiles.yml.example dbt_project/profiles.yml
fi

echo "[1/3] dbt debug (cek koneksi)..."
cd dbt_project && dbt debug --profiles-dir .

echo ""
echo "[2/3] dbt run (jalankan semua model)..."
dbt run --profiles-dir .

echo ""
echo "[3/3] dbt test (jalankan semua test)..."
dbt test --profiles-dir .

echo ""
echo "dbt selesai. Bronze, Silver, Gold sudah tersedia di DuckDB."
