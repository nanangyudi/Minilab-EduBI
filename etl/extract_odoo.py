"""
extract_odoo.py
Ekstrak data dari simulasi Odoo (PostgreSQL schema odoo_sim)
dan simpan ke data/raw/ sebagai CSV.

Untuk PoC: membaca dari PG odoo_sim yang sudah di-seed oleh init_postgres.sql.
Untuk koneksi Odoo asli: ganti fungsi extract_* dengan XML-RPC ke Odoo.
"""

import os
import pandas as pd
from utils import get_pg_conn, get_logger

log = get_logger("extract_odoo")

RAW_DIR = os.getenv("RAW_DIR", "data/raw")


def extract_customers() -> pd.DataFrame:
    """Ambil data customer dari odoo_sim.res_partner → data/raw/odoo_customers.csv."""
    conn = get_pg_conn(schema="odoo_sim")
    df = pd.read_sql(
        """
        SELECT
            'C' || LPAD(id::text, 3, '0') AS customer_id,
            name,
            email,
            phone,
            city,
            branch,
            customer_since::text AS customer_since
        FROM odoo_sim.res_partner
        WHERE active = TRUE
        ORDER BY id
        """,
        conn,
    )
    conn.close()
    out = os.path.join(RAW_DIR, "odoo_customers.csv")
    os.makedirs(RAW_DIR, exist_ok=True)
    df.to_csv(out, index=False)
    log.info(f"  {len(df):>4} customers → {out}")
    return df


def extract_sales() -> pd.DataFrame:
    """Ambil data sales order dari odoo_sim.sale_order → data/raw/odoo_sales.csv."""
    conn = get_pg_conn(schema="odoo_sim")
    df = pd.read_sql(
        """
        SELECT
            so.name                                        AS order_id,
            'C' || LPAD(so.partner_id::text, 3, '0')      AS customer_id,
            so.product_name,
            so.category,
            so.quantity::text                              AS quantity,
            so.unit_price::text                            AS unit_price,
            so.amount_total::text                          AS total_price,
            so.date_order::text                            AS order_date,
            so.branch,
            so.state                                       AS status
        FROM odoo_sim.sale_order so
        ORDER BY so.date_order
        """,
        conn,
    )
    conn.close()
    out = os.path.join(RAW_DIR, "odoo_sales.csv")
    os.makedirs(RAW_DIR, exist_ok=True)
    df.to_csv(out, index=False)
    log.info(f"  {len(df):>4} sales orders → {out}")
    return df


if __name__ == "__main__":
    extract_customers()
    extract_sales()
