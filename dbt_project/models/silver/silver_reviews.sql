-- silver_reviews.sql
-- Silver layer: bersihkan dan standarisasi data ulasan
-- Transformasi:
--   - Cast rating ke integer
--   - Cast tanggal
--   - Tambah kolom sentiment berdasarkan rating

{{ config(materialized='table', schema='silver') }}

SELECT
    review_id,
    TRIM(author)                        AS author,
    CAST(rating AS INTEGER)             AS rating,
    TRIM(text)                          AS review_text,
    CAST(review_date AS DATE)           AS review_date,
    YEAR(CAST(review_date AS DATE))     AS review_year,
    MONTH(CAST(review_date AS DATE))    AS review_month,
    TRIM(branch)                        AS branch,
    LOWER(TRIM(source))                 AS source,

    -- Kategorikan sentimen berdasarkan rating
    CASE
        WHEN CAST(rating AS INTEGER) >= 4 THEN 'Positif'
        WHEN CAST(rating AS INTEGER) = 3  THEN 'Netral'
        ELSE 'Negatif'
    END AS sentiment

FROM {{ ref('bronze_reviews') }}
WHERE
    review_id IS NOT NULL
    AND rating IS NOT NULL
    AND CAST(rating AS INTEGER) BETWEEN 1 AND 5
