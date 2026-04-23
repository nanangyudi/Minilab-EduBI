-- gold_sales_daily.sql (Olist mode — fase2/olist-ecommerce)
-- Gold layer: agregasi penjualan harian per seller_state
-- Perubahan vs Minilab standard:
--   - seller_state menggantikan branch sebagai dimensi geografis
--   - total_items_sold = count baris (tidak ada kolom quantity di Olist)
--   - Breakdown kategori menggunakan kategori Olist (top categories)

{{ config(
    materialized = 'table',
    schema       = 'gold',
    engine       = 'MergeTree()',
    order_by     = '(order_date, seller_state)'
) }}

SELECT
    order_date,
    order_year,
    order_month,
    seller_state,

    count(DISTINCT order_id)                                AS total_orders,
    count()                                                 AS total_items_sold,
    sum(unit_price)                                         AS total_revenue,
    avg(unit_price)                                         AS avg_order_value,
    sum(freight_value)                                      AS total_freight,

    -- Breakdown metrik pengiriman harian
    round(avg(delivery_days), 1)                            AS avg_delivery_days,
    countIf(is_delayed = 1)                                 AS delayed_orders,
    countIf(is_delayed = 0)                                 AS on_time_orders,

    -- Breakdown per kategori populer Olist
    countIf(category = 'bed_bath_table')                    AS items_bed_bath_table,
    countIf(category = 'health_beauty')                     AS items_health_beauty,
    countIf(category = 'computers_accessories')             AS items_computers,
    countIf(category = 'furniture_decor')                   AS items_furniture,
    countIf(category = 'sports_leisure')                    AS items_sports,

    sumIf(unit_price, category = 'bed_bath_table')          AS rev_bed_bath_table,
    sumIf(unit_price, category = 'health_beauty')           AS rev_health_beauty,
    sumIf(unit_price, category = 'computers_accessories')   AS rev_computers,
    sumIf(unit_price, category = 'furniture_decor')         AS rev_furniture,
    sumIf(unit_price, category = 'sports_leisure')          AS rev_sports

FROM {{ ref('silver_sales') }}
WHERE status = 'done'
GROUP BY
    order_date,
    order_year,
    order_month,
    seller_state
ORDER BY
    order_date,
    seller_state
