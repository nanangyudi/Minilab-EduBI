-- gold_branch_kpi.sql
-- Gold layer: KPI ringkasan per cabang (lintas semua periode data)
-- Digunakan untuk: scorecard / ringkasan kinerja cabang di Metabase
--
-- Catatan: subquery berjenjang (bukan CTE) digunakan karena ClickHouse 24.3
-- meng-inline CTE sehingga kolom 'branch' dari tiga sumber JOIN menjadi
-- ambigu saat MergeTree ORDER BY mencoba meresolvenya.
-- Wrapper SELECT * FROM (...) memastikan hanya satu 'branch' yang terlihat.

{{ config(
    materialized = 'table',
    schema       = 'gold',
    engine       = 'MergeTree()',
    order_by     = '(branch)'
) }}

SELECT *
FROM (
    SELECT
        s.branch                                                        AS branch,
        s.total_orders,
        s.total_revenue,
        round(s.avg_order_value, 0)                                     AS avg_order_value,
        s.max_order_value,
        s.first_sale_date,
        s.last_sale_date,

        -- Target dan pencapaian
        coalesce(t.total_sales_target, 0)                               AS total_sales_target,
        coalesce(t.total_order_target, 0)                               AS total_order_target,
        if(
            coalesce(t.total_sales_target, 0) > 0,
            round(s.total_revenue / t.total_sales_target * 100, 1),
            NULL
        )                                                               AS revenue_achievement_pct,

        -- Review
        coalesce(r.avg_rating, 0)                                       AS avg_rating,
        coalesce(r.total_reviews, 0)                                    AS total_reviews

    FROM (
        SELECT
            branch,
            count(order_id)         AS total_orders,
            sum(total_price)        AS total_revenue,
            avg(total_price)        AS avg_order_value,
            max(total_price)        AS max_order_value,
            min(order_date)         AS first_sale_date,
            max(order_date)         AS last_sale_date
        FROM {{ ref('silver_sales') }}
        WHERE status = 'done'
        GROUP BY branch
    ) AS s
    LEFT JOIN (
        SELECT
            branch,
            sum(sales_target)   AS total_sales_target,
            sum(order_target)   AS total_order_target
        FROM {{ ref('silver_targets') }}
        GROUP BY branch
    ) AS t ON s.branch = t.branch
    LEFT JOIN (
        SELECT
            branch,
            round(avg(toFloat64(rating)), 2)  AS avg_rating,
            count(review_id)                  AS total_reviews
        FROM {{ ref('silver_reviews') }}
        GROUP BY branch
    ) AS r ON s.branch = r.branch
)
