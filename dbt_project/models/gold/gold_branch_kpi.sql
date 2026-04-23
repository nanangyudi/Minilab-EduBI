-- gold_branch_kpi.sql (Olist mode — tidak digunakan / stub)
-- Dataset Olist tidak memiliki konsep "cabang" (branch).
-- Gunakan gold_seller_kpi.sql sebagai gantinya — berisi KPI per seller_state.
-- Model ini mengembalikan tabel kosong agar pipeline tidak error.

{{ config(
    materialized = 'table',
    schema       = 'gold',
    engine       = 'MergeTree()',
    order_by     = '(branch)'
) }}

SELECT
    ''          AS branch,
    toInt64(0)  AS total_orders,
    toDecimal64(0, 2) AS total_revenue
WHERE 1 = 0
