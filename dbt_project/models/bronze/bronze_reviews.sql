-- bronze_reviews.sql
-- Bronze layer: ambil raw data ulasan dari sumber (bronze.reviews)
-- Tidak ada transformasi — data persis seperti yang dimuat ETL

{{ config(materialized='table', schema='bronze') }}

SELECT
    review_id,
    author,
    rating,
    text,
    review_date,
    branch,
    source
FROM {{ source('bronze', 'reviews') }}
