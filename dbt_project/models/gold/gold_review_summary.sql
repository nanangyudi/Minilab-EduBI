-- gold_review_summary.sql
-- Gold layer: ringkasan ulasan per cabang
-- Digunakan untuk: tile rating, bar chart sentimen di Metabase

{{ config(materialized='table', schema='gold') }}

SELECT
    branch,
    COUNT(review_id)                                        AS total_reviews,
    ROUND(AVG(CAST(rating AS DOUBLE)), 2)                   AS avg_rating,

    -- Distribusi bintang
    COUNT(CASE WHEN rating = 5 THEN 1 END)                  AS rating_5,
    COUNT(CASE WHEN rating = 4 THEN 1 END)                  AS rating_4,
    COUNT(CASE WHEN rating = 3 THEN 1 END)                  AS rating_3,
    COUNT(CASE WHEN rating = 2 THEN 1 END)                  AS rating_2,
    COUNT(CASE WHEN rating = 1 THEN 1 END)                  AS rating_1,

    -- Distribusi sentimen
    COUNT(CASE WHEN sentiment = 'Positif'  THEN 1 END)      AS sentiment_positif,
    COUNT(CASE WHEN sentiment = 'Netral'   THEN 1 END)      AS sentiment_netral,
    COUNT(CASE WHEN sentiment = 'Negatif'  THEN 1 END)      AS sentiment_negatif,

    -- Persentase positif
    ROUND(
        COUNT(CASE WHEN sentiment = 'Positif' THEN 1 END) * 100.0
        / NULLIF(COUNT(review_id), 0),
        1
    )                                                       AS pct_positif

FROM {{ ref('silver_reviews') }}
GROUP BY branch
ORDER BY avg_rating DESC
