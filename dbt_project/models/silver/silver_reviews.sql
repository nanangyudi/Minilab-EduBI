-- silver_reviews.sql
-- Silver layer: bersihkan dan standarisasi data ulasan
-- Transformasi:
--   - Cast rating ke Int32
--   - Cast tanggal
--   - Tambah kolom sentiment berdasarkan rating

{{ config(
    materialized = 'table',
    schema       = 'silver',
    engine       = 'MergeTree()',
    order_by     = '(review_date, review_id)'
) }}

SELECT
    review_id,
    trimBoth(author)                                    AS author,
    toInt32OrZero(trimBoth(rating))                     AS rating,
    trimBoth(text)                                      AS review_text,
    toDate(review_date)                                 AS review_date,
    toYear(toDate(review_date))                         AS review_year,
    toMonth(toDate(review_date))                        AS review_month,
    trimBoth(branch)                                    AS branch,
    lower(trimBoth(source))                             AS source,

    -- Kategorikan sentimen berdasarkan rating
    CASE
        WHEN toInt32OrZero(trimBoth(rating)) >= 4 THEN 'Positif'
        WHEN toInt32OrZero(trimBoth(rating)) = 3  THEN 'Netral'
        ELSE 'Negatif'
    END AS sentiment

FROM {{ ref('bronze_reviews') }}
WHERE
    review_id IS NOT NULL AND review_id != ''
    AND rating IS NOT NULL AND rating != ''
    AND toInt32OrZero(trimBoth(rating)) BETWEEN 1 AND 5
