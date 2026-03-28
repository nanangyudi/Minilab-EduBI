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
    trimBoth(branch)                            AS branch,
    toInt32(month)                              AS month,
    toInt32(year)                               AS year,
    CAST(sales_target AS Decimal(14,2))         AS sales_target,
    toInt32(order_target)                       AS order_target,

    -- Label periode: "Jan 2024", "Feb 2024", dll
    formatDateTime(
        makeDate(toInt32(year), toInt32(month), 1),
        '%b %Y'
    )                                           AS period_label

FROM {{ ref('bronze_targets') }}
WHERE
    target_id    IS NOT NULL AND target_id != ''
    AND sales_target IS NOT NULL AND sales_target != ''
    AND toFloat64(sales_target) > 0
