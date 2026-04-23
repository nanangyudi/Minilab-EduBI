-- gold_seller_kpi.sql (Olist mode — fase2/olist-ecommerce)
-- Gold layer: KPI ringkasan per seller_state (pengganti gold_branch_kpi)
-- Digunakan untuk: scorecard / peta performa penjual per negara bagian di Metabase
--
-- Kolom utama:
--   seller_state         — negara bagian penjual (dimensi geografis)
--   total_orders         — jumlah order unik
--   total_items          — jumlah item (1 order bisa punya banyak item)
--   total_revenue        — total pendapatan item (BRL, tidak termasuk freight)
--   total_freight        — total biaya pengiriman (BRL)
--   avg_delivery_days    — rata-rata waktu pengiriman (hari)
--   on_time_delivery_pct — persentase pengiriman tepat waktu
--   avg_rating           — rata-rata skor ulasan (dari gold_review_summary via customer_state)

{{ config(
    materialized = 'table',
    schema       = 'gold',
    engine       = 'MergeTree()',
    order_by     = '(seller_state)'
) }}

SELECT *
FROM (
    SELECT
        seller_state,
        count(DISTINCT order_id)                            AS total_orders,
        count()                                             AS total_items,
        sum(unit_price)                                     AS total_revenue,
        sum(freight_value)                                  AS total_freight,
        round(avg(total_price), 2)                          AS avg_item_value,

        -- Metrik pengiriman (hanya untuk order dengan data pengiriman lengkap)
        round(avg(delivery_days), 1)                        AS avg_delivery_days,
        min(delivery_days)                                  AS min_delivery_days,
        max(delivery_days)                                  AS max_delivery_days,
        round(
            countIf(is_delayed = 0 AND delivery_days IS NOT NULL) * 100.0
            / nullIf(countIf(delivery_days IS NOT NULL), 0),
            1
        )                                                   AS on_time_delivery_pct,
        countIf(is_delayed = 1)                             AS total_delayed,

        -- Rentang tanggal
        min(order_date)                                     AS first_order_date,
        max(order_date)                                     AS last_order_date

    FROM {{ ref('silver_sales') }}
    WHERE status = 'done'
    GROUP BY seller_state
)
