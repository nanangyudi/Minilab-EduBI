-- silver_targets.sql
-- Silver layer: bersihkan dan standarisasi data target penjualan
-- Transformasi:
--   - Cast tipe numerik
--   - Tambah kolom period_label untuk kemudahan display

{{ config(materialized='table', schema='silver') }}

SELECT
    target_id,
    TRIM(branch)                            AS branch,
    CAST(month AS INTEGER)                  AS month,
    CAST(year  AS INTEGER)                  AS year,
    CAST(sales_target AS DECIMAL(14,2))     AS sales_target,
    CAST(order_target AS INTEGER)           AS order_target,

    -- Label periode: "Jan 2024", "Feb 2024", dll
    STRFTIME(
        MAKE_DATE(CAST(year AS INTEGER), CAST(month AS INTEGER), 1),
        '%b %Y'
    )                                       AS period_label

FROM {{ ref('bronze_targets') }}
WHERE
    target_id IS NOT NULL
    AND sales_target IS NOT NULL
    AND CAST(sales_target AS DECIMAL) > 0
