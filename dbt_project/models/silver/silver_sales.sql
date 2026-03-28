-- silver_sales.sql
-- Silver layer: bersihkan dan standarisasi data penjualan
-- Transformasi:
--   - Cast tipe data (tanggal, numerik) dari String (bronze)
--   - Buang baris quantity/total_price tidak valid
--   - Tambah kolom turunan: year, month, revenue_category

{{ config(
    materialized = 'table',
    schema       = 'silver',
    engine       = 'MergeTree()',
    order_by     = '(order_date, order_id)'
) }}

SELECT
    order_id,
    customer_id,
    trimBoth(product_name)                      AS product_name,
    trimBoth(category)                          AS category,
    toInt32(quantity)                           AS quantity,
    CAST(unit_price  AS Decimal(12,2))          AS unit_price,
    CAST(total_price AS Decimal(12,2))          AS total_price,
    toDate(order_date)                          AS order_date,
    toYear(toDate(order_date))                  AS order_year,
    toMonth(toDate(order_date))                 AS order_month,
    trimBoth(branch)                            AS branch,
    lower(trimBoth(status))                     AS status,

    -- Klasifikasi nilai transaksi
    CASE
        WHEN toFloat64(total_price) >= 10000000 THEN 'High Value'
        WHEN toFloat64(total_price) >= 3000000  THEN 'Mid Value'
        ELSE 'Low Value'
    END AS revenue_category

FROM {{ ref('bronze_sales') }}
WHERE
    quantity   IS NOT NULL AND toInt32(quantity)   > 0
    AND total_price IS NOT NULL AND toFloat64(total_price) > 0
    AND order_id IS NOT NULL AND order_id != ''
