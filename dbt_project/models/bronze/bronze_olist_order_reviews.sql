-- bronze_olist_order_reviews.sql
-- Bronze layer: raw data ulasan per pesanan Olist — tidak ada transformasi
-- Sumber: data/raw/olist/olist_order_reviews_dataset.csv → ClickHouse bronze.olist_order_reviews
-- Catatan: 1 order = maksimal 1 ulasan; review terintegrasi (berbeda dari Google Reviews)

{{ config(
    materialized = 'table',
    schema       = 'bronze',
    engine       = 'MergeTree()',
    order_by     = '(review_id)'
) }}

SELECT
    review_id,
    order_id,
    review_score,
    review_comment_title,
    review_comment_message,
    review_creation_date,
    review_answer_timestamp
FROM {{ source('bronze', 'olist_order_reviews') }}
