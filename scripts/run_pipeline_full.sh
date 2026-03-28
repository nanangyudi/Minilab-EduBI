#!/bin/bash
# =============================================================
# run_pipeline_full.sh
# Panduan end-to-end Pipeline Minilab EduBI (5 Tahap)
#
# Skrip ini menampilkan seluruh alur kerja data pipeline
# secara eksplisit, dari Extract hingga Visualisasi.
#
# Usage: bash scripts/run_pipeline_full.sh
# =============================================================

set -e

# Pastikan berada di root direktori proyek
cd "$(dirname "$0")/.."

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║       Minilab EduBI — Full Data Pipeline (5 Tahap)   ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""
echo "  Alur kerja end-to-end:"
echo "    TAHAP 1 : Extract (Odoo PG, Google Reviews, Manual CSV)"
echo "    TAHAP 2 : Load ke Bronze (ClickHouse)"
echo "    TAHAP 3 : Transform ke Silver (dbt, ClickHouse)"
echo "    TAHAP 4 : Transform ke Gold   (dbt, ClickHouse)"
echo "    TAHAP 5 : Visualisasi (Metabase)"
echo ""

# ─────────────────────────────────────────────────────────────
# Prasyarat: pastikan Docker Compose berjalan
# ─────────────────────────────────────────────────────────────
echo "┌─────────────────────────────────────────────────────┐"
echo "│  Memastikan PostgreSQL dan ClickHouse berjalan...    │"
echo "└─────────────────────────────────────────────────────┘"
docker compose up -d postgres clickhouse

echo ""
echo "  Menunggu services healthy (15 detik)..."
sleep 15

# ─────────────────────────────────────────────────────────────
# TAHAP 1 + 2: Extract dan Load Bronze
# ─────────────────────────────────────────────────────────────
echo ""
echo "┌─────────────────────────────────────────────────────┐"
echo "│  TAHAP 1 + 2 — Extract & Load Bronze                 │"
echo "│  (docker compose run --rm app)                       │"
echo "└─────────────────────────────────────────────────────┘"
docker compose run --rm app

# ─────────────────────────────────────────────────────────────
# TAHAP 3 + 4: Transform Silver dan Gold
# ─────────────────────────────────────────────────────────────
echo ""
echo "┌─────────────────────────────────────────────────────┐"
echo "│  TAHAP 3 + 4 — Transform Silver & Gold (dbt)         │"
echo "│  (docker compose run --rm dbt)                       │"
echo "└─────────────────────────────────────────────────────┘"
docker compose run --rm dbt

# ─────────────────────────────────────────────────────────────
# TAHAP 5: Visualisasi Metabase
# ─────────────────────────────────────────────────────────────
echo ""
echo "┌─────────────────────────────────────────────────────┐"
echo "│  TAHAP 5 — Visualisasi (Metabase)                    │"
echo "│  Memulai Metabase...                                 │"
echo "└─────────────────────────────────────────────────────┘"
docker compose up -d metabase

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║  PIPELINE SELESAI                                    ║"
echo "║                                                      ║"
echo "║  Buka dashboard Metabase di: http://localhost:3000   ║"
echo "║  (tunggu ~2 menit hingga Metabase siap)              ║"
echo "║                                                      ║"
echo "║  Konfigurasi koneksi ClickHouse di Metabase:         ║"
echo "║    Type     : ClickHouse                             ║"
echo "║    Host     : clickhouse                             ║"
echo "║    Port     : 8123                                   ║"
echo "║    Database : gold                                   ║"
echo "║    Username : default                                ║"
echo "║    Password : (kosong)                               ║"
echo "╚══════════════════════════════════════════════════════╝"
