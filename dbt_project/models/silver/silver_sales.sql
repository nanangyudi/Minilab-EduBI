-- silver_sales.sql
-- Silver layer: bersihkan dan standarisasi data penjualan
-- Transformasi:
--   - Cast tipe data (tanggal, numerik)
--   - Buang baris yang quantity atau total_price tidak valid
--   - Tambah kolom turunan: year, month, revenue_category

{{ config(materialized='table', schema='silver') }}

SELECT
    order_id,
    customer_id,
    TRIM(product_name)                      AS product_name,
    TRIM(category)                          AS category,
    CAST(quantity   AS INTEGER)             AS quantity,
    CAST(unit_price AS DECIMAL(12,2))       AS unit_price,
    CAST(total_price AS DECIMAL(12,2))      AS total_price,
    CAST(order_date AS DATE)                AS order_date,
    YEAR(CAST(order_date AS DATE))          AS order_year,
    MONTH(CAST(order_date AS DATE))         AS order_month,
    TRIM(branch)                            AS branch,
    LOWER(TRIM(status))                     AS status,

    -- Klasifikasi nilai transaksi
    CASE
        WHEN CAST(total_price AS DECIMAL) >= 10000000 THEN 'High Value'
        WHEN CAST(total_price AS DECIMAL) >= 3000000  THEN 'Mid Value'
        ELSE 'Low Value'
    END AS revenue_category

FROM {{ ref('bronze_sales') }}
WHERE
    quantity   IS NOT NULL AND CAST(quantity   AS INTEGER) > 0
    AND total_price IS NOT NULL AND CAST(total_price AS DECIMAL) > 0
    AND order_id IS NOT NULL
