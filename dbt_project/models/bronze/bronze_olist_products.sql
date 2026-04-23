-- bronze_olist_products.sql
-- Bronze layer: raw data produk Olist — tidak ada transformasi
-- Sumber: data/raw/olist/olist_products_dataset.csv → ClickHouse bronze.olist_products
-- Catatan: product_category_name dalam Bahasa Portugis; gunakan olist_category_translation untuk English

{{ config(
    materialized = 'table',
    schema       = 'bronze',
    engine       = 'MergeTree()',
    order_by     = '(product_id)'
) }}

SELECT
    product_id,
    product_category_name,
    product_name_lenght,
    product_description_lenght,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
FROM {{ source('bronze', 'olist_products') }}
