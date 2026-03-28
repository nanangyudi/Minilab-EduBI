-- bronze_targets.sql
-- Bronze layer: ambil raw data target penjualan (bronze.targets)
-- Tidak ada transformasi — data persis seperti yang dimuat ETL

{{ config(
    materialized = 'table',
    schema       = 'bronze',
    engine       = 'MergeTree()',
    order_by     = '(year, month, branch)'
) }}

SELECT
    target_id,
    branch,
    month,
    year,
    sales_target,
    order_target
FROM {{ source('bronze', 'targets') }}
