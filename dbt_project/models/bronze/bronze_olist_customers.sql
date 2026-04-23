-- bronze_olist_customers.sql
-- Bronze layer: raw data pelanggan Olist — tidak ada transformasi
-- Sumber: data/raw/olist/olist_customers_dataset.csv → ClickHouse bronze.olist_customers
-- Catatan: customer_id berbeda di setiap order; gunakan customer_unique_id untuk analisis RFM

{{ config(
    materialized = 'table',
    schema       = 'bronze',
    engine       = 'MergeTree()',
    order_by     = '(customer_id)'
) }}

SELECT
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state
FROM {{ source('bronze', 'olist_customers') }}
