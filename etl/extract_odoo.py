"""
extract_odoo.py
Ekstrak data dari Odoo via XML-RPC dan simpan ke data/raw/
"""

import xmlrpc.client
import pandas as pd
import os
from dotenv import load_dotenv

load_dotenv()

ODOO_URL = os.getenv("ODOO_URL", "http://localhost:8069")
ODOO_DB = os.getenv("ODOO_DB", "odoo")
ODOO_USER = os.getenv("ODOO_USER", "admin")
ODOO_PASSWORD = os.getenv("ODOO_PASSWORD", "admin")

OUTPUT_DIR = "data/raw"


def authenticate():
    common = xmlrpc.client.ServerProxy(f"{ODOO_URL}/xmlrpc/2/common")
    uid = common.authenticate(ODOO_DB, ODOO_USER, ODOO_PASSWORD, {})
    models = xmlrpc.client.ServerProxy(f"{ODOO_URL}/xmlrpc/2/object")
    return uid, models


def extract_sales_orders(uid, models):
    records = models.execute_kw(
        ODOO_DB, uid, ODOO_PASSWORD,
        "sale.order", "search_read",
        [[]],
        {"fields": ["name", "partner_id", "date_order", "amount_total", "state"]}
    )
    df = pd.DataFrame(records)
    df.to_csv(f"{OUTPUT_DIR}/sales_orders.csv", index=False)
    print(f"Extracted {len(df)} sales orders.")
    return df


def extract_customers(uid, models):
    records = models.execute_kw(
        ODOO_DB, uid, ODOO_PASSWORD,
        "res.partner", "search_read",
        [[["customer_rank", ">", 0]]],
        {"fields": ["name", "email", "phone", "city", "country_id"]}
    )
    df = pd.DataFrame(records)
    df.to_csv(f"{OUTPUT_DIR}/customers.csv", index=False)
    print(f"Extracted {len(df)} customers.")
    return df


if __name__ == "__main__":
    uid, models = authenticate()
    extract_sales_orders(uid, models)
    extract_customers(uid, models)
