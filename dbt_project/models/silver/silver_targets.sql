-- silver_targets.sql (Olist mode — tidak digunakan / not applicable)
-- Dataset Olist tidak memiliki data target penjualan per wilayah.
-- Model ini mengembalikan tabel kosong agar pipeline tidak error.
-- Pada domain yang memiliki data target, ganti dengan tabel aktual.

{{ config(
    materialized = 'table',
    schema       = 'silver',
    engine       = 'MergeTree()',
    order_by     = '(year, month, branch)'
) }}

SELECT
    ''                      AS target_id,
    ''                      AS branch,
    toInt32(0)              AS month,
    toInt32(0)              AS year,
    toDecimal64(0, 2)       AS sales_target,
    toInt32(0)              AS order_target,
    ''                      AS period_label
WHERE 1 = 0
