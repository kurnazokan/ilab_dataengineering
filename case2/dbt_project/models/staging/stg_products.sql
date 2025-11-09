-- Staging model for products
-- Bu model, products tablosundan verileri çeker ve temizler

{{ config(
    materialized='view',
    schema='analytics'
) }}

SELECT
    product_id,
    product_category,
    product_price
FROM {{ source('public', 'products') }}
WHERE product_price > 0

