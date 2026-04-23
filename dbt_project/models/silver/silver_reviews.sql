-- silver_reviews.sql (Olist mode — fase2/olist-ecommerce)
-- Silver layer: data ulasan dari olist_order_reviews
-- Dimensi geografis: customer_state (negara bagian asal pembeli yang mengulas)
-- Kolom 'branch' dipertahankan sebagai alias customer_state untuk kompatibilitas gold models

{{ config(
    materialized = 'table',
    schema       = 'silver',
    engine       = 'MergeTree()',
    order_by     = '(review_date, review_id)'
) }}

SELECT
    r.review_id,
    r.order_id,
    toInt32OrZero(r.review_score)                           AS rating,
    trimBoth(coalesce(r.review_comment_title, ''))          AS review_title,
    trimBoth(coalesce(r.review_comment_message, ''))        AS review_text,
    toDate(r.review_creation_date)                          AS review_date,
    toYear(toDate(r.review_creation_date))                  AS review_year,
    toMonth(toDate(r.review_creation_date))                 AS review_month,

    -- Dimensi geografis: customer_state (asal pembeli yang mengulas)
    trimBoth(coalesce(c.customer_state, 'unknown'))         AS customer_state,
    trimBoth(coalesce(c.customer_state, 'unknown'))         AS branch,  -- alias untuk gold_review_summary

    -- Kategorikan sentimen berdasarkan skor ulasan (1-5)
    CASE
        WHEN toInt32OrZero(r.review_score) >= 4 THEN 'Positif'
        WHEN toInt32OrZero(r.review_score) = 3  THEN 'Netral'
        ELSE 'Negatif'
    END                                                     AS sentiment

FROM {{ ref('bronze_olist_order_reviews') }}    AS r
LEFT JOIN {{ ref('bronze_olist_orders') }}      AS o ON r.order_id = o.order_id
LEFT JOIN {{ ref('bronze_olist_customers') }}   AS c ON o.customer_id = c.customer_id

WHERE
    r.review_id IS NOT NULL AND r.review_id != ''
    AND toInt32OrZero(r.review_score) BETWEEN 1 AND 5
