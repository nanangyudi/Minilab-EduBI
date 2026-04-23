-- bronze_olist_order_items.sql
-- Bronze layer: raw data item per pesanan Olist — tidak ada transformasi
-- Sumber: data/raw/olist/olist_order_items_dataset.csv → ClickHouse bronze.olist_order_items
-- Catatan: 1 order bisa punya BANYAK item (berbeda dari dataset toko elektronik)

{{ config(
    materialized = 'table',
    schema       = 'bronze',
    engine       = 'MergeTree()',
    order_by     = '(order_id, order_item_id)'
) }}

SELECT
    order_id,
    order_item_id,
    product_id,
    seller_id,
    shipping_limit_date,
    price,
    freight_value
FROM {{ source('bronze', 'olist_order_items') }}
