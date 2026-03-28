-- bronze_sales.sql
-- Bronze layer: ambil raw data penjualan dari sumber (bronze.sales)
-- Tidak ada transformasi — data persis seperti yang dimuat ETL

{{ config(
    materialized = 'table',
    schema       = 'bronze',
    engine       = 'MergeTree()',
    order_by     = '(order_date, order_id)'
) }}

SELECT
    order_id,
    customer_id,
    product_name,
    category,
    quantity,
    unit_price,
    total_price,
    order_date,
    branch,
    status
FROM {{ source('bronze', 'sales') }}
