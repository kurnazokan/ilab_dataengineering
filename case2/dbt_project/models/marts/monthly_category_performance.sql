-- Model 2: Her ürün kategorisinin aylık performans analizi
-- Bu model, ilk modelin çıktısını ve ürünler tablosunu kullanarak
-- her kategori için toplam sipariş sayısını ve toplam satış miktarını bulur

{{ config(
    materialized='table',
    schema='analytics'
) }}

WITH product_sales AS (
    SELECT
        product_id,
        order_month,
        year_month,
        year,
        month,
        total_orders,
        total_sales_amount,
        avg_order_amount
    FROM {{ ref('monthly_product_sales') }}
),

products AS (
    SELECT
        product_id,
        product_category,
        product_price
    FROM {{ ref('stg_products') }}
)

SELECT
    p.product_category,
    ps.order_month,
    ps.year_month,
    ps.year,
    ps.month,
    COUNT(DISTINCT ps.product_id) as unique_products_sold,
    SUM(ps.total_orders) as total_orders,
    SUM(ps.total_sales_amount) as total_sales_amount,
    AVG(ps.avg_order_amount) as avg_order_amount,
    SUM(ps.total_sales_amount) / NULLIF(SUM(ps.total_orders), 0) as category_avg_order_value
FROM product_sales ps
INNER JOIN products p 
    ON ps.product_id = p.product_id
GROUP BY
    p.product_category,
    ps.order_month,
    ps.year_month,
    ps.year,
    ps.month
ORDER BY
    ps.order_month DESC,
    total_sales_amount DESC

