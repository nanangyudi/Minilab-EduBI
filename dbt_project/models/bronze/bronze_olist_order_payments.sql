-- bronze_olist_order_payments.sql
-- Bronze layer: raw data pembayaran per pesanan Olist — tidak ada transformasi
-- Sumber: data/raw/olist/olist_order_payments_dataset.csv → ClickHouse bronze.olist_order_payments

{{ config(
    materialized = 'table',
    schema       = 'bronze',
    engine       = 'MergeTree()',
    order_by     = '(order_id, payment_sequential)'
) }}

SELECT
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value
FROM {{ source('bronze', 'olist_order_payments') }}
