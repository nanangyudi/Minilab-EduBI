-- silver_customers.sql
-- Silver layer: bersihkan dan standarisasi data customer
-- Transformasi:
--   - Trim whitespace
--   - Cast tanggal
--   - Tambah kolom customer_age_years (lama menjadi customer)

{{ config(materialized='table', schema='silver') }}

SELECT
    customer_id,
    TRIM(name)                                   AS name,
    LOWER(TRIM(email))                           AS email,
    TRIM(phone)                                  AS phone,
    TRIM(city)                                   AS city,
    TRIM(branch)                                 AS branch,
    CAST(customer_since AS DATE)                 AS customer_since,

    -- Hitung berapa tahun sudah menjadi customer
    DATE_DIFF('year',
        CAST(customer_since AS DATE),
        CURRENT_DATE
    )                                            AS customer_age_years

FROM {{ ref('bronze_customers') }}
WHERE
    customer_id IS NOT NULL
    AND name IS NOT NULL
