-- gold_delivery_kpi.sql (Olist mode — fase2/olist-ecommerce)
-- Gold layer: metrik pengiriman per seller_state × kategori produk
-- Digunakan untuk: analisis ketepatan pengiriman di Metabase
--
-- Pertanyaan bisnis yang bisa dijawab:
--   - Seller state mana yang paling sering terlambat?
--   - Kategori produk mana yang paling lama dikirimkan?
--   - Apakah freight_value tinggi berkorelasi dengan ketepatan pengiriman?

{{ config(
    materialized = 'table',
    schema       = 'gold',
    engine       = 'MergeTree()',
    order_by     = '(seller_state, category)'
) }}

SELECT
    seller_state,
    category,
    count()                                                 AS total_items,
    count(DISTINCT order_id)                                AS total_orders,

    -- Waktu pengiriman
    round(avg(delivery_days), 1)                            AS avg_delivery_days,
    min(delivery_days)                                      AS min_delivery_days,
    max(delivery_days)                                      AS max_delivery_days,

    -- Ketepatan
    countIf(is_delayed = 0)                                 AS on_time_count,
    countIf(is_delayed = 1)                                 AS delayed_count,
    round(
        countIf(is_delayed = 0) * 100.0
        / nullIf(countIf(delivery_days IS NOT NULL), 0),
        1
    )                                                       AS on_time_pct,

    -- Biaya
    round(avg(freight_value), 2)                            AS avg_freight_value,
    sum(freight_value)                                      AS total_freight_value,
    round(avg(unit_price), 2)                               AS avg_unit_price

FROM {{ ref('silver_sales') }}
WHERE
    status = 'done'
    AND delivery_days IS NOT NULL
GROUP BY seller_state, category
ORDER BY seller_state, avg_delivery_days DESC
