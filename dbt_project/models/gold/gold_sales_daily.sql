-- gold_sales_daily.sql
-- Gold layer: agregasi penjualan harian per cabang
-- Digunakan untuk: grafik tren penjualan di dashboard Metabase

{{ config(materialized='table', schema='gold') }}

SELECT
    order_date,
    order_year,
    order_month,
    branch,
    COUNT(order_id)                         AS total_orders,
    SUM(total_price)                        AS total_revenue,
    AVG(total_price)                        AS avg_order_value,
    SUM(quantity)                           AS total_items_sold,

    -- Breakdown per kategori produk
    COUNT(CASE WHEN category = 'Elektronik' THEN 1 END) AS orders_elektronik,
    COUNT(CASE WHEN category = 'Aksesoris'  THEN 1 END) AS orders_aksesoris,
    COUNT(CASE WHEN category = 'Komponen'   THEN 1 END) AS orders_komponen,

    SUM(CASE WHEN category = 'Elektronik' THEN total_price ELSE 0 END) AS rev_elektronik,
    SUM(CASE WHEN category = 'Aksesoris'  THEN total_price ELSE 0 END) AS rev_aksesoris,
    SUM(CASE WHEN category = 'Komponen'   THEN total_price ELSE 0 END) AS rev_komponen

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
