-- silver_sales.sql (Olist mode — fase2/olist-ecommerce)
-- Silver layer: data penjualan dari dataset Olist Brazilian E-Commerce
-- Granularitas: 1 baris = 1 item dalam 1 pesanan (berbeda dari Minilab standard: 1 baris = 1 order)
--
-- JOIN: order_items ⟵ orders ⟵ customers + sellers + products + category_translation
-- Kolom baru vs Minilab standard:
--   seller_state   — dimensi geografis penjual (pengganti branch)
--   customer_state — dimensi geografis pembeli
--   delivery_days  — lama pengiriman (hari) dari pembelian ke diterima
--   is_delayed     — 1 jika dikirim melebihi tanggal estimasi, 0 jika tepat waktu
--   freight_value  — biaya pengiriman per item (BRL)

{{ config(
    materialized = 'table',
    schema       = 'silver',
    engine       = 'MergeTree()',
    order_by     = '(order_date, order_id, order_item_id)'
) }}

SELECT
    i.order_id,
    i.order_item_id,

    -- Customer: gunakan customer_unique_id (ID permanen lintas order)
    coalesce(trimBoth(c.customer_unique_id), '')                        AS customer_id,
    trimBoth(coalesce(c.customer_state, 'unknown'))                     AS customer_state,

    -- Seller: seller_state sebagai dimensi geografis (pengganti branch)
    trimBoth(coalesce(s.seller_state, 'unknown'))                       AS seller_state,
    i.seller_id,

    -- Produk
    i.product_id,
    coalesce(
        trimBoth(t.product_category_name_english),
        trimBoth(p.product_category_name),
        'unknown'
    )                                                                   AS category,
    trimBoth(coalesce(p.product_category_name, 'unknown'))              AS category_pt,

    -- Harga (BRL)
    toDecimal64OrZero(i.price, 2)                                       AS unit_price,
    toDecimal64OrZero(i.freight_value, 2)                               AS freight_value,
    toDecimal64OrZero(i.price, 2)
        + toDecimal64OrZero(i.freight_value, 2)                         AS total_price,

    -- Waktu
    toDate(o.order_purchase_timestamp)                                  AS order_date,
    toYear(toDate(o.order_purchase_timestamp))                          AS order_year,
    toMonth(toDate(o.order_purchase_timestamp))                         AS order_month,

    -- Normalisasi status: delivered→done, canceled→cancelled, lainnya→pending
    multiIf(
        o.order_status = 'delivered',                    'done',
        o.order_status IN ('canceled', 'unavailable'),   'cancelled',
        'pending'
    )                                                                   AS status,

    -- Metrik pengiriman: hari dari pembelian ke diterima customer
    if(
        o.order_delivered_customer_date != '' AND o.order_purchase_timestamp != '',
        toInt32(dateDiff(
            'day',
            toDate(o.order_purchase_timestamp),
            toDate(o.order_delivered_customer_date)
        )),
        NULL
    )                                                                   AS delivery_days,

    -- Flag keterlambatan: 1 = terlambat dari estimasi, 0 = tepat waktu
    if(
        o.order_delivered_customer_date != '' AND o.order_estimated_delivery_date != '',
        if(
            toDate(o.order_delivered_customer_date)
                > toDate(o.order_estimated_delivery_date),
            1, 0
        ),
        NULL
    )                                                                   AS is_delayed,

    -- Klasifikasi nilai transaksi (dalam BRL — ~1 BRL ≈ 0.2 USD)
    CASE
        WHEN toDecimal64OrZero(i.price, 2) >= 500  THEN 'High Value'
        WHEN toDecimal64OrZero(i.price, 2) >= 100  THEN 'Mid Value'
        ELSE 'Low Value'
    END                                                                 AS revenue_category

FROM {{ ref('bronze_olist_order_items') }}              AS i
JOIN {{ ref('bronze_olist_orders') }}                   AS o ON i.order_id = o.order_id
LEFT JOIN {{ ref('bronze_olist_customers') }}           AS c ON o.customer_id = c.customer_id
LEFT JOIN {{ ref('bronze_olist_sellers') }}             AS s ON i.seller_id = s.seller_id
LEFT JOIN {{ ref('bronze_olist_products') }}            AS p ON i.product_id = p.product_id
LEFT JOIN {{ ref('bronze_olist_category_translation') }} AS t ON p.product_category_name = t.product_category_name

WHERE
    i.order_id IS NOT NULL AND i.order_id != ''
    AND toDecimal64OrZero(i.price, 2) > 0
