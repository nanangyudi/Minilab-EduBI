"""
init_duckdb.py
Inisialisasi database DuckDB dan buat schema Medallion Architecture:
- bronze: raw data
- silver: cleaned data
- gold:   BI-ready / aggregated data
"""

import duckdb
import os

DB_PATH = "data/warehouse/lab_bi.duckdb"


def init_database():
    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)
    con = duckdb.connect(DB_PATH)

    con.execute("CREATE SCHEMA IF NOT EXISTS bronze")
    con.execute("CREATE SCHEMA IF NOT EXISTS silver")
    con.execute("CREATE SCHEMA IF NOT EXISTS gold")

    schemas = con.execute("SHOW ALL TABLES").fetchdf()
    print("Database initialized.")
    print(f"DB path: {os.path.abspath(DB_PATH)}")

    existing = con.execute("SELECT schema_name FROM information_schema.schemata").fetchall()
    print("Schemas:", [s[0] for s in existing])

    con.close()


if __name__ == "__main__":
    init_database()
