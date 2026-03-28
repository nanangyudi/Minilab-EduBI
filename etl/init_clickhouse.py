"""
init_clickhouse.py
Inisialisasi ClickHouse sebagai Data Warehouse:
- Buat database Bronze, Silver, Gold
  (di ClickHouse, "database" setara dengan "schema" di sistem lain)
"""

from utils import get_ch_client, get_logger

log = get_logger("init_clickhouse")


def init_database():
    log.info("Menginisialisasi ClickHouse Data Warehouse...")
    client = get_ch_client()

    for db in ("bronze", "silver", "gold"):
        client.command(f"CREATE DATABASE IF NOT EXISTS {db}")
        log.info(f"  Database '{db}' siap.")

    databases = [
        row[0]
        for row in client.query("SHOW DATABASES").result_rows
    ]
    log.info(f"Databases aktif: {databases}")
    log.info("ClickHouse berhasil diinisialisasi.")


if __name__ == "__main__":
    init_database()
