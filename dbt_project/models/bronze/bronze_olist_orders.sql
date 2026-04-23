-- bronze_olist_orders.sql
-- Bronze layer: raw data pesanan Olist — tidak ada transformasi
-- Sumber: data/raw/olist/olist_orders_dataset.csv → ClickHouse bronze.olist_orders

{{ config(
    materialized = 'table',
    schema       = 'bronze',
    engine       = 'MergeTree()',
    order_by     = '(order_id)'
) }}

SELECT
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date
FROM {{ source('bronze', 'olist_orders') }}
