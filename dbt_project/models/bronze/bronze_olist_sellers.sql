-- bronze_olist_sellers.sql
-- Bronze layer: raw data penjual Olist — tidak ada transformasi
-- Sumber: data/raw/olist/olist_sellers_dataset.csv → ClickHouse bronze.olist_sellers
-- Catatan: seller_state digunakan sebagai dimensi geografis (pengganti "branch" di Minilab EduBI)

{{ config(
    materialized = 'table',
    schema       = 'bronze',
    engine       = 'MergeTree()',
    order_by     = '(seller_id)'
) }}

SELECT
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
FROM {{ source('bronze', 'olist_sellers') }}
