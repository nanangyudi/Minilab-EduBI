-- silver_targets.sql
-- Silver layer: bersihkan dan standarisasi data target penjualan
-- Transformasi:
--   - Cast tipe numerik dari String (bronze)
--   - Tambah kolom period_label untuk display

{{ config(
    materialized = 'table',
    schema       = 'silver',
    engine       = 'MergeTree()',
    order_by     = '(year, month, branch)'
) }}

SELECT
    target_id,
    trimBoth(branch)                                        AS branch,
    toInt32OrZero(trimBoth(month))                          AS month,
    toInt32OrZero(trimBoth(year))                           AS year,
    toDecimal64OrZero(trimBoth(sales_target), 2)            AS sales_target,
    toInt32OrZero(trimBoth(order_target))                   AS order_target,

    -- Label periode: "Jan 2024", "Feb 2024", dll
    formatDateTime(
        makeDate(
            toInt32OrZero(trimBoth(year)),
            toInt32OrZero(trimBoth(month)),
            1
        ),
        '%b %Y'
    )                                                       AS period_label

FROM {{ ref('bronze_targets') }}
WHERE
    target_id    IS NOT NULL AND target_id != ''
    AND sales_target IS NOT NULL AND sales_target != ''
    AND toFloat64OrZero(trimBoth(sales_target)) > 0
