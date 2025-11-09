-- Model 1: Her ürünün aylık satış analizi
-- Bu model, her ayın siparişlerini analiz eder ve her ürün için
-- toplam sipariş sayısını ve toplam satış miktarını bulur

{{ config(
    materialized='table',
    schema='analytics'
) }}

WITH order_data AS (
    SELECT
        product_id,
        order_month,
        order_date,
        total_amount
    FROM {{ ref('stg_orders') }}
)

SELECT
    product_id,
    order_month,
    TO_CHAR(order_month, 'YYYY-MM') as year_month,
    EXTRACT(YEAR FROM order_month) as year,
    EXTRACT(MONTH FROM order_month) as month,
    COUNT(*) as total_orders,
    SUM(total_amount) as total_sales_amount,
    AVG(total_amount) as avg_order_amount,
    MIN(total_amount) as min_order_amount,
    MAX(total_amount) as max_order_amount
FROM order_data
GROUP BY
    product_id,
    order_month
ORDER BY
    order_month DESC,
    product_id

