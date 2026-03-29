#!/usr/bin/env bash
# scripts/run_fase2.sh
# Minilab EduBI — Helper untuk menjalankan Fase 2 (Data Mining)
#
# Penggunaan:
#   ./scripts/run_fase2.sh [start|stop|status|logs]
#
# Contoh:
#   ./scripts/run_fase2.sh start    — jalankan seluruh stack Fase 1 + Fase 2
#   ./scripts/run_fase2.sh stop     — hentikan service Fase 2
#   ./scripts/run_fase2.sh status   — tampilkan status container
#   ./scripts/run_fase2.sh logs     — tampilkan log Jupyter & MLflow

set -euo pipefail

COMPOSE_CMD="docker compose"
PROFILE_ANALYTICS="--profile analytics"
PROFILE_ALL="--profile bi --profile analytics"

usage() {
  echo "Penggunaan: $0 [start|stop|status|logs|pipeline]"
  echo ""
  echo "  start     Jalankan Fase 1 pipeline + Fase 2 services (Jupyter, MLflow)"
  echo "  stop      Hentikan service Fase 2"
  echo "  status    Tampilkan status semua container Minilab"
  echo "  logs      Tampilkan log Jupyter & MLflow (Ctrl+C untuk keluar)"
  echo "  pipeline  Jalankan ulang ETL + dbt (tanpa restart service)"
  exit 1
}

check_env() {
  if [ ! -f ".env" ]; then
    echo "⚠  File .env tidak ditemukan. Menyalin dari .env.example..."
    cp .env.example .env
    echo "   Sesuaikan nilai di .env jika diperlukan."
  fi
}

cmd_start() {
  check_env
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo " Minilab EduBI — Fase 2: Data Mining"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  echo ""
  echo "▶ [1/4] Menjalankan infrastruktur (postgres, clickhouse)..."
  $COMPOSE_CMD up -d postgres clickhouse

  echo ""
  echo "▶ [2/4] Menjalankan ETL pipeline..."
  $COMPOSE_CMD run --rm app

  echo ""
  echo "▶ [3/4] Menjalankan dbt transformasi..."
  $COMPOSE_CMD run --rm dbt

  echo ""
  echo "▶ [4/4] Menjalankan service Fase 2 (Jupyter + MLflow)..."
  $COMPOSE_CMD $PROFILE_ANALYTICS up -d jupyter mlflow

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo " ✅ Fase 2 siap!"
  echo ""
  echo "   Jupyter Lab : http://localhost:8888"
  echo "   MLflow UI   : http://localhost:5000"
  echo ""
  JUPYTER_TOKEN=${JUPYTER_TOKEN:-minilab}
  echo "   Token Jupyter: $JUPYTER_TOKEN"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

cmd_stop() {
  echo "▶ Menghentikan service Fase 2..."
  $COMPOSE_CMD $PROFILE_ANALYTICS down jupyter mlflow 2>/dev/null || \
    $COMPOSE_CMD stop jupyter mlflow
  echo "✅ Service Fase 2 dihentikan."
}

cmd_status() {
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo " Status Container Minilab EduBI"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  docker ps --filter "name=minilab_" \
    --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
}

cmd_logs() {
  echo "▶ Log Jupyter & MLflow (Ctrl+C untuk keluar)..."
  $COMPOSE_CMD logs -f jupyter mlflow
}

cmd_pipeline() {
  check_env
  echo "▶ Menjalankan ulang ETL + dbt..."
  $COMPOSE_CMD run --rm app
  $COMPOSE_CMD run --rm dbt
  echo "✅ Pipeline selesai."
}

# ─── Main ────────────────────────────────────────────────
cd "$(dirname "$0")/.."   # pastikan working dir di root proyek

case "${1:-}" in
  start)    cmd_start    ;;
  stop)     cmd_stop     ;;
  status)   cmd_status   ;;
  logs)     cmd_logs     ;;
  pipeline) cmd_pipeline ;;
  *)        usage        ;;
esac
