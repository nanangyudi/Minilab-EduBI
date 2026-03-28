"""
init_duckdb.py
Inisialisasi database DuckDB:
- Buat file DuckDB di data/warehouse/lab_bi.duckdb
- Buat schema Bronze, Silver, Gold
"""

from utils import get_duckdb_conn, get_logger

log = get_logger("init_duckdb")


def init_database():
    log.info("Menginisialisasi DuckDB...")
    con = get_duckdb_conn()

    for schema in ("bronze", "silver", "gold"):
        con.execute(f"CREATE SCHEMA IF NOT EXISTS {schema}")
        log.info(f"  Schema '{schema}' siap.")

    schemas = [
        row[0]
        for row in con.execute(
            "SELECT schema_name FROM information_schema.schemata"
        ).fetchall()
    ]
    log.info(f"Schema aktif: {schemas}")
    con.close()
    log.info("DuckDB berhasil diinisialisasi.")


if __name__ == "__main__":
    init_database()
