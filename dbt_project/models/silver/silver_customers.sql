-- silver_customers.sql
-- Silver layer: bersihkan dan standarisasi data customer
-- Transformasi:
--   - Trim whitespace, lowercase email
--   - Cast tanggal
--   - Tambah kolom customer_age_years

{{ config(
    materialized = 'table',
    schema       = 'silver',
    engine       = 'MergeTree()',
    order_by     = 'customer_id'
) }}

SELECT
    customer_id,
    trimBoth(name)                                   AS name,
    lower(trimBoth(email))                           AS email,
    trimBoth(phone)                                  AS phone,
    trimBoth(city)                                   AS city,
    trimBoth(branch)                                 AS branch,
    toDate(customer_since)                           AS customer_since,

    -- Hitung berapa tahun sudah menjadi customer
    dateDiff('year', toDate(customer_since), today()) AS customer_age_years

FROM {{ ref('bronze_customers') }}
WHERE
    customer_id IS NOT NULL AND customer_id != ''
    AND name    IS NOT NULL AND name != ''
