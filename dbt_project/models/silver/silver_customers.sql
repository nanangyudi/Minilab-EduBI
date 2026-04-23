-- silver_customers.sql (Olist mode — fase2/olist-ecommerce)
-- Silver layer: data pelanggan unik dari Olist
-- Deduplikasi menggunakan customer_unique_id (ID permanen lintas order)
-- Catatan: 1 customer_unique_id dapat punya banyak customer_id (satu per order baru)

{{ config(
    materialized = 'table',
    schema       = 'silver',
    engine       = 'MergeTree()',
    order_by     = '(customer_id)'
) }}

SELECT
    customer_unique_id                  AS customer_id,
    any(customer_zip_code_prefix)       AS zip_code,
    trimBoth(any(customer_city))        AS city,
    trimBoth(any(customer_state))       AS state,
    count()                             AS total_order_ids

FROM {{ ref('bronze_olist_customers') }}
WHERE customer_unique_id IS NOT NULL AND customer_unique_id != ''
GROUP BY customer_unique_id
