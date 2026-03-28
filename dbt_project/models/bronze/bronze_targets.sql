-- bronze_targets.sql
-- Bronze layer: ambil raw data target penjualan (bronze.targets)
-- Tidak ada transformasi — data persis seperti yang dimuat ETL

{{ config(materialized='table', schema='bronze') }}

SELECT
    target_id,
    branch,
    month,
    year,
    sales_target,
    order_target
FROM {{ source('bronze', 'targets') }}
