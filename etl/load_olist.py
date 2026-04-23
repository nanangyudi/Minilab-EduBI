"""
load_olist.py
Load file CSV Olist dari data/raw/olist/ ke tabel bronze di ClickHouse.

Olist Brazilian E-Commerce memiliki 8 file CSV yang saling berelasi.
Semua dimuat ke Bronze sebagai String (raw layer) — JOIN dilakukan di Silver (dbt).

Sumber: https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce
"""

import os
import pandas as pd
from utils import get_ch_client, get_logger

log = get_logger("load_olist")

RAW_DIR  = os.getenv("RAW_DIR", "data/raw")
OLIST_DIR = os.path.join(RAW_DIR, "olist")

OLIST_TABLES = {
    "bronze.olist_orders": "olist_orders_dataset.csv",
    "bronze.olist_order_items": "olist_order_items_dataset.csv",
    "bronze.olist_order_payments": "olist_order_payments_dataset.csv",
    "bronze.olist_order_reviews": "olist_order_reviews_dataset.csv",
    "bronze.olist_customers": "olist_customers_dataset.csv",
    "bronze.olist_sellers": "olist_sellers_dataset.csv",
    "bronze.olist_products": "olist_products_dataset.csv",
    "bronze.olist_category_translation": "product_category_name_translation.csv",
}

# DDL — semua kolom String (raw layer, typing dilakukan di Silver/dbt)
OLIST_DDL = {
    "bronze.olist_orders": """
        CREATE TABLE IF NOT EXISTS bronze.olist_orders (
            order_id                        String,
            customer_id                     String,
            order_status                    String,
            order_purchase_timestamp        String,
            order_approved_at               String,
            order_delivered_carrier_date    String,
            order_delivered_customer_date   String,
            order_estimated_delivery_date   String
        ) ENGINE = MergeTree() ORDER BY order_id
    """,
    "bronze.olist_order_items": """
        CREATE TABLE IF NOT EXISTS bronze.olist_order_items (
            order_id            String,
            order_item_id       String,
            product_id          String,
            seller_id           String,
            shipping_limit_date String,
            price               String,
            freight_value       String
        ) ENGINE = MergeTree() ORDER BY (order_id, order_item_id)
    """,
    "bronze.olist_order_payments": """
        CREATE TABLE IF NOT EXISTS bronze.olist_order_payments (
            order_id                String,
            payment_sequential      String,
            payment_type            String,
            payment_installments    String,
            payment_value           String
        ) ENGINE = MergeTree() ORDER BY (order_id, payment_sequential)
    """,
    "bronze.olist_order_reviews": """
        CREATE TABLE IF NOT EXISTS bronze.olist_order_reviews (
            review_id                   String,
            order_id                    String,
            review_score                String,
            review_comment_title        String,
            review_comment_message      String,
            review_creation_date        String,
            review_answer_timestamp     String
        ) ENGINE = MergeTree() ORDER BY review_id
    """,
    "bronze.olist_customers": """
        CREATE TABLE IF NOT EXISTS bronze.olist_customers (
            customer_id             String,
            customer_unique_id      String,
            customer_zip_code_prefix String,
            customer_city           String,
            customer_state          String
        ) ENGINE = MergeTree() ORDER BY customer_id
    """,
    "bronze.olist_sellers": """
        CREATE TABLE IF NOT EXISTS bronze.olist_sellers (
            seller_id               String,
            seller_zip_code_prefix  String,
            seller_city             String,
            seller_state            String
        ) ENGINE = MergeTree() ORDER BY seller_id
    """,
    "bronze.olist_products": """
        CREATE TABLE IF NOT EXISTS bronze.olist_products (
            product_id                  String,
            product_category_name       String,
            product_name_lenght         String,
            product_description_lenght  String,
            product_photos_qty          String,
            product_weight_g            String,
            product_length_cm           String,
            product_height_cm           String,
            product_width_cm            String
        ) ENGINE = MergeTree() ORDER BY product_id
    """,
    "bronze.olist_category_translation": """
        CREATE TABLE IF NOT EXISTS bronze.olist_category_translation (
            product_category_name           String,
            product_category_name_english   String
        ) ENGINE = MergeTree() ORDER BY product_category_name
    """,
}


def olist_files_exist() -> bool:
    """Cek apakah file Olist sudah ada di data/raw/olist/."""
    required = ["olist_orders_dataset.csv", "olist_order_items_dataset.csv"]
    return all(
        os.path.exists(os.path.join(OLIST_DIR, f)) for f in required
    )


def load_all():
    if not olist_files_exist():
        log.warning(
            f"File Olist tidak ditemukan di {OLIST_DIR}. "
            "Download dari https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce "
            "dan ekstrak ke data/raw/olist/"
        )
        return False

    client = get_ch_client()

    for table, ddl in OLIST_DDL.items():
        client.command(ddl)

    for table, filename in OLIST_TABLES.items():
        filepath = os.path.join(OLIST_DIR, filename)
        if not os.path.exists(filepath):
            log.warning(f"  File tidak ditemukan: {filepath} — skip {table}")
            continue

        df = pd.read_csv(filepath, dtype=str).fillna("")
        client.command(f"TRUNCATE TABLE IF EXISTS {table}")
        client.insert_df(table, df)

        count = client.query(f"SELECT count() FROM {table}").result_rows[0][0]
        log.info(f"  {count:>7} baris → {table:<40} ← {filename}")

    return True


if __name__ == "__main__":
    load_all()
