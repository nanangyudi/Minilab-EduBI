-- gold_sales_daily.sql
-- Gold layer: agregasi penjualan harian per cabang
-- Digunakan untuk: grafik tren penjualan di dashboard Metabase

{{ config(
    materialized = 'table',
    schema       = 'gold',
    engine       = 'MergeTree()',
    order_by     = '(order_date, branch)'
) }}

SELECT
    order_date,
    order_year,
    order_month,
    branch,
    count(order_id)                                             AS total_orders,
    sum(total_price)                                            AS total_revenue,
    avg(total_price)                                            AS avg_order_value,
    sum(quantity)                                               AS total_items_sold,

    -- Breakdown per kategori produk
    countIf(category = 'Elektronik')                           AS orders_elektronik,
    countIf(category = 'Aksesoris')                            AS orders_aksesoris,
    countIf(category = 'Komponen')                             AS orders_komponen,

    sumIf(total_price, category = 'Elektronik')                AS rev_elektronik,
    sumIf(total_price, category = 'Aksesoris')                 AS rev_aksesoris,
    sumIf(total_price, category = 'Komponen')                  AS rev_komponen

FROM {{ ref('silver_sales') }}
WHERE status = 'done'
GROUP BY
    order_date,
    order_year,
    order_month,
    branch
ORDER BY
    order_date,
    branch
