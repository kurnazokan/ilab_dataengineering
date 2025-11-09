-- Staging model for orders
-- Bu model, orders tablosundan verileri çeker ve temizler

{{ config(
    materialized='view',
    schema='analytics'
) }}

SELECT
    order_id,
    customer_id,
    product_id,
    order_date,
    total_amount,
    DATE_TRUNC('month', order_date) as order_month
FROM {{ source('public', 'orders') }}
WHERE order_date IS NOT NULL
    AND total_amount > 0

