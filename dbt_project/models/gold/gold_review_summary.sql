-- gold_review_summary.sql
-- Gold layer: ringkasan ulasan per cabang
-- Digunakan untuk: tile rating, bar chart sentimen di Metabase

{{ config(
    materialized = 'table',
    schema       = 'gold',
    engine       = 'MergeTree()',
    order_by     = 'branch'
) }}

SELECT
    branch,
    count(review_id)                                        AS total_reviews,
    round(avg(toFloat64(rating)), 2)                        AS avg_rating,

    -- Distribusi bintang
    countIf(rating = 5)                                     AS rating_5,
    countIf(rating = 4)                                     AS rating_4,
    countIf(rating = 3)                                     AS rating_3,
    countIf(rating = 2)                                     AS rating_2,
    countIf(rating = 1)                                     AS rating_1,

    -- Distribusi sentimen
    countIf(sentiment = 'Positif')                          AS sentiment_positif,
    countIf(sentiment = 'Netral')                           AS sentiment_netral,
    countIf(sentiment = 'Negatif')                          AS sentiment_negatif,

    -- Persentase positif
    round(
        countIf(sentiment = 'Positif') * 100.0
        / nullIf(count(review_id), 0),
        1
    )                                                       AS pct_positif

FROM {{ ref('silver_reviews') }}
GROUP BY branch
ORDER BY avg_rating DESC
