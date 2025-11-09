# 📚 Case 2'ye Yeni DBT Modeli Ekleme Rehberi

## 🎯 Senaryo: Müşteri Analizi Modeli Eklemek İstiyorum

### Adım 1: Model SQL Dosyasını Oluştur

**Örnek: Müşteri bazlı aylık analiz**

```bash
# Yeni model dosyası oluştur
cd case2/dbt_project/models/marts
vim customer_monthly_analysis.sql
```

```sql
-- models/marts/customer_monthly_analysis.sql
{{ config(
    materialized='table',
    schema='analytics'
) }}

WITH customer_orders AS (
    SELECT
        customer_id,
        DATE_TRUNC('month', order_date) as order_month,
        order_date,
        total_amount
    FROM {{ ref('stg_orders') }}
)

SELECT
    customer_id,
    order_month,
    TO_CHAR(order_month, 'YYYY-MM') as year_month,
    COUNT(*) as total_orders,
    SUM(total_amount) as total_spent,
    AVG(total_amount) as avg_order_value,
    COUNT(DISTINCT DATE_TRUNC('day', order_date)) as active_days
FROM customer_orders
GROUP BY customer_id, order_month
ORDER BY customer_id, order_month DESC
```

### Adım 2: Schema Dosyasına Ekle

```bash
# schema.yml'i düzenle
vim case2/dbt_project/models/marts/schema.yml
```

```yaml
# Mevcut modellerin altına ekle:
  - name: customer_monthly_analysis
    description: "Müşteri bazlı aylık analiz"
    columns:
      - name: customer_id
        description: "Müşteri ID"
        tests:
          - not_null
      - name: order_month
        description: "Sipariş ayı"
        tests:
          - not_null
      - name: total_orders
        description: "Aylık toplam sipariş sayısı"
      - name: total_spent
        description: "Aylık toplam harcama"
        tests:
          - not_null
      - name: avg_order_value
        description: "Ortalama sipariş değeri"
```

### Adım 3: Modeli Test Et

```bash
# Docker container'a gir
cd case2
docker-compose exec airflow-scheduler bash

# Sadece yeni modeli çalıştır
cd /opt/airflow/dbt_project
dbt run --select customer_monthly_analysis --profiles-dir . --target dev

# Testleri çalıştır
dbt test --select customer_monthly_analysis --profiles-dir . --target dev

# Çık
exit
```

### Adım 4: Airflow DAG'a Ekle (Opsiyonel)

Eğer yeni model DAG'da otomatik çalışsın istersen:

```bash
vim case2/dags/ecommerce_dbt_dag.py
```

```python
# Yeni task ekle
dbt_run_customer_analysis = BashOperator(
    task_id='dbt_run_customer_monthly_analysis',
    bash_command='cd /opt/airflow/dbt_project && dbt run --profiles-dir . --target dev --select customer_monthly_analysis',
    dag=dag,
)

# Bağımlılıkları güncelle
(
    start_task
    >> dbt_run_staging
    >> dbt_run_monthly_product_sales
    >> dbt_run_monthly_category_performance
    >> dbt_run_customer_analysis  # YENİ MODEL
    >> dbt_test
    >> end_task
)
```

### Adım 5: Sonuçları Kontrol Et

```bash
# Veriyi görüntüle
docker-compose exec postgres psql -U airflow -d ecommerce

SELECT * FROM public_analytics.customer_monthly_analysis 
WHERE customer_id = 234 
ORDER BY order_month DESC;
```

---

## 🎨 Farklı Model Türleri

### 1. View Model (Hafif, her seferinde hesaplanır)

```sql
{{ config(
    materialized='view',
    schema='analytics'
) }}

SELECT ...
```

### 2. Table Model (Ağır, önceden hesaplanır)

```sql
{{ config(
    materialized='table',
    schema='analytics'
) }}

SELECT ...
```

### 3. Incremental Model (Sadece yeni veriler işlenir)

```sql
{{ config(
    materialized='incremental',
    unique_key='customer_id',
    schema='analytics'
) }}

SELECT ...
{% if is_incremental() %}
WHERE order_date > (SELECT MAX(order_date) FROM {{ this }})
{% endif %}
```

---

## 📊 Yaygın Model Örnekleri

### Örnek 1: En Çok Harcayan Müşteriler

```sql
-- models/marts/top_spending_customers.sql
{{ config(materialized='table', schema='analytics') }}

SELECT
    customer_id,
    SUM(total_amount) as lifetime_value,
    COUNT(*) as total_orders,
    MIN(order_date) as first_order_date,
    MAX(order_date) as last_order_date,
    MAX(order_date) - MIN(order_date) as customer_lifetime_days
FROM {{ ref('stg_orders') }}
GROUP BY customer_id
HAVING SUM(total_amount) > 100
ORDER BY lifetime_value DESC
```

### Örnek 2: Ürün Performans Trendi

```sql
-- models/marts/product_trend_analysis.sql
{{ config(materialized='table', schema='analytics') }}

WITH monthly_sales AS (
    SELECT * FROM {{ ref('monthly_product_sales') }}
),

trend AS (
    SELECT
        product_id,
        order_month,
        total_sales_amount,
        LAG(total_sales_amount) OVER (PARTITION BY product_id ORDER BY order_month) as previous_month_sales
    FROM monthly_sales
)

SELECT
    product_id,
    order_month,
    total_sales_amount,
    previous_month_sales,
    CASE 
        WHEN previous_month_sales IS NULL THEN 0
        ELSE ((total_sales_amount - previous_month_sales) / previous_month_sales * 100)
    END as growth_percentage
FROM trend
ORDER BY product_id, order_month DESC
```

### Örnek 3: Kategori Çapraz Satış Analizi

```sql
-- models/marts/category_cross_sell.sql
{{ config(materialized='table', schema='analytics') }}

WITH order_products AS (
    SELECT
        o.order_id,
        o.customer_id,
        p.product_category
    FROM {{ ref('stg_orders') }} o
    JOIN {{ ref('stg_products') }} p ON o.product_id = p.product_id
)

SELECT
    a.product_category as category_a,
    b.product_category as category_b,
    COUNT(DISTINCT a.customer_id) as customers_bought_both
FROM order_products a
JOIN order_products b 
    ON a.customer_id = b.customer_id 
    AND a.product_category < b.product_category
GROUP BY a.product_category, b.product_category
HAVING COUNT(DISTINCT a.customer_id) > 2
ORDER BY customers_bought_both DESC
```

---

## 🧪 Test Ekleme

### Custom Test Oluştur

```bash
# Test dosyası oluştur
vim case2/dbt_project/tests/assert_no_negative_sales.sql
```

```sql
-- tests/assert_no_negative_sales.sql
SELECT *
FROM {{ ref('customer_monthly_analysis') }}
WHERE total_spent < 0
-- Negatif değer varsa test fail olur
```

### Built-in Testler

```yaml
# schema.yml içinde
tests:
  - not_null
  - unique
  - relationships:
      to: ref('stg_orders')
      field: customer_id
  - accepted_values:
      values: ['Electronics', 'Books', 'Clothing']
```

---

## 🚀 Deployment Checklist

Yeni model ekledikten sonra:

- [ ] SQL dosyası oluşturuldu
- [ ] schema.yml'e eklendi
- [ ] Local'de test edildi (`dbt run --select model_name`)
- [ ] Testler yazıldı ve geçti (`dbt test --select model_name`)
- [ ] Dokumentasyon eklendi
- [ ] Airflow DAG'a eklendi (gerekirse)
- [ ] Git commit yapıldı
- [ ] GitHub'a push edildi

```bash
# Deployment
git add .
git commit -m "Add new model: customer_monthly_analysis"
git push origin main

# Airflow'da DAG'ı restart et
cd case2
docker-compose restart airflow-scheduler
```

---

## 🔍 Debugging İpuçları

### Model çalışmıyor?

```bash
# DBT compile et, SQL'i gör
dbt compile --select model_name --profiles-dir . --target dev

# Compiled SQL'i kontrol et
cat target/compiled/ecommerce_analytics/models/marts/model_name.sql

# Manuel çalıştır
docker-compose exec postgres psql -U airflow -d ecommerce < target/compiled/.../model_name.sql
```

### Bağımlılık hatası?

```bash
# Model lineage'ı görüntüle
dbt deps --profiles-dir . --target dev
dbt docs generate --profiles-dir . --target dev
dbt docs serve --profiles-dir . --target dev
```

### Performance problemi?

```sql
-- Execution plan gör
EXPLAIN ANALYZE
SELECT * FROM public_analytics.model_name;

-- Index ekle
CREATE INDEX idx_customer_month ON public_analytics.customer_monthly_analysis(customer_id, order_month);
```

---

## 📚 Best Practices

1. **Naming Convention:**
   - Staging: `stg_tablename`
   - Marts: `business_concept_name`
   - Intermediate: `int_meaningful_name`

2. **Model Organizasyonu:**
   ```
   models/
   ├── staging/      # Raw data cleaning
   ├── intermediate/ # Complex transformations
   └── marts/        # Business logic
   ```

3. **Materialization Strategy:**
   - Views: Lightweight, always fresh
   - Tables: Heavy queries, pre-computed
   - Incremental: Large datasets, only new data

4. **Testing:**
   - Her model en az 1 test olmalı
   - Critical alanlar: not_null, unique
   - Business rules: custom tests

5. **Documentation:**
   ```yaml
   description: |
     ## Purpose
     Customer monthly analysis
     
     ## Logic
     Groups orders by customer and month
     
     ## Usage
     Marketing team için retention analysis
   ```

---

## 🎯 Hızlı Komutlar

```bash
# Tüm modelleri çalıştır
dbt run --profiles-dir . --target dev

# Sadece bir model
dbt run --select model_name --profiles-dir . --target dev

# Model ve downstream'leri
dbt run --select model_name+ --profiles-dir . --target dev

# Model ve upstream'leri
dbt run --select +model_name --profiles-dir . --target dev

# Değişen modeller
dbt run --select state:modified --profiles-dir . --target dev

# Full refresh (incremental için)
dbt run --select model_name --full-refresh --profiles-dir . --target dev
```

---

## 💡 Özet

Yeni model eklemek için **3 adım**:

1. **SQL yaz** → `models/marts/new_model.sql`
2. **Test et** → `dbt run --select new_model`
3. **Deploy et** → Git commit + push

İhtiyacın olursa bu dosyaya bakabilirsin! 🚀

