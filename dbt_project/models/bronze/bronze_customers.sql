-- bronze_customers.sql
-- Bronze layer: ambil raw data customer dari sumber (bronze.customers)
-- Tidak ada transformasi — data persis seperti yang dimuat ETL

{{ config(
    materialized = 'table',
    schema       = 'bronze',
    engine       = 'MergeTree()',
    order_by     = 'customer_id'
) }}

SELECT
    customer_id,
    name,
    email,
    phone,
    city,
    branch,
    customer_since
FROM {{ source('bronze', 'customers') }}
