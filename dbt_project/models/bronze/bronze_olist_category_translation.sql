-- bronze_olist_category_translation.sql
-- Bronze layer: tabel translasi kategori produk Olist (Portugis → English)
-- Sumber: data/raw/olist/product_category_name_translation.csv → ClickHouse bronze.olist_category_translation

{{ config(
    materialized = 'table',
    schema       = 'bronze',
    engine       = 'MergeTree()',
    order_by     = '(product_category_name)'
) }}

SELECT
    product_category_name,
    product_category_name_english
FROM {{ source('bronze', 'olist_category_translation') }}
