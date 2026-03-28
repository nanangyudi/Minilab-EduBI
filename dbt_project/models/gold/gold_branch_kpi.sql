-- gold_branch_kpi.sql
-- Gold layer: KPI ringkasan per cabang (lintas semua periode data)
-- Digunakan untuk: scorecard / ringkasan kinerja cabang di Metabase

{{ config(materialized='table', schema='gold') }}

WITH sales_summary AS (
    SELECT
        branch,
        COUNT(order_id)         AS total_orders,
        SUM(total_price)        AS total_revenue,
        AVG(total_price)        AS avg_order_value,
        MAX(total_price)        AS max_order_value,
        MIN(order_date)         AS first_sale_date,
        MAX(order_date)         AS last_sale_date
    FROM {{ ref('silver_sales') }}
    WHERE status = 'done'
    GROUP BY branch
),

target_summary AS (
    SELECT
        branch,
        SUM(sales_target)   AS total_sales_target,
        SUM(order_target)   AS total_order_target
    FROM {{ ref('silver_targets') }}
    GROUP BY branch
),

review_summary AS (
    SELECT
        branch,
        ROUND(AVG(CAST(rating AS DOUBLE)), 2) AS avg_rating,
        COUNT(review_id)                       AS total_reviews
    FROM {{ ref('silver_reviews') }}
    GROUP BY branch
)

SELECT
    s.branch,
    s.total_orders,
    s.total_revenue,
    ROUND(s.avg_order_value, 0)                             AS avg_order_value,
    s.max_order_value,
    s.first_sale_date,
    s.last_sale_date,

    -- Target dan pencapaian
    COALESCE(t.total_sales_target, 0)                       AS total_sales_target,
    COALESCE(t.total_order_target, 0)                       AS total_order_target,
    CASE
        WHEN COALESCE(t.total_sales_target, 0) > 0
        THEN ROUND(s.total_revenue / t.total_sales_target * 100, 1)
        ELSE NULL
    END                                                     AS revenue_achievement_pct,

    -- Review
    COALESCE(r.avg_rating, 0)                               AS avg_rating,
    COALESCE(r.total_reviews, 0)                            AS total_reviews

FROM sales_summary s
LEFT JOIN target_summary t USING (branch)
LEFT JOIN review_summary r USING (branch)
ORDER BY total_revenue DESC
