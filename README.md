# E-Ticaret Analiz Pipeline - DBT & Airflow

Bu proje, e-ticaret sipariş ve ürün verilerini analiz etmek için DBT (Data Build Tool) ve Apache Airflow kullanarak otomatik bir veri pipeline'ı oluşturur.

## Proje Özeti

### Gereksinimler
- Docker ve Docker Compose kurulu olmalı
- En az 4GB RAM (Docker için)

### Özellikler
1. DBT Modelleri:
   - monthly_product_sales: Her ürünün aylık satış analizi
   - monthly_category_performance: Her kategorinin aylık performans analizi

2. Airflow DAG:
   - Her gün saat 10:00'da otomatik çalışır
   - Modelleri sırayla ve kontrollü şekilde çalıştırır

3. Docker Ortamı:
   - PostgreSQL veritabanı
   - Apache Airflow (webserver + scheduler)
   - DBT entegrasyonu



## Kurulum ve Çalıştırma

### 1. Projeyi Başlatma

# Proje dizinine git
cd /Users/okan/Desktop/ilab-case-okurnaz

# Docker container'ları başlat
docker compose up -d


İlk başlatmada:
- PostgreSQL veritabanı oluşturulur
- Örnek veriler yüklenir
- Airflow kullanıcısı (admin/admin) oluşturulur
- DBT bağımlılıkları yüklenir

### 2. Servislere Erişim

Apache Airflow Web UI:
- URL: http://localhost:8080
- Kullanıcı adı: admin
- Şifre: admin

PostgreSQL:
- Host: localhost
- Port: 5432
- Kullanıcı: airflow
- Şifre: airflow
- Veritabanları: airflow, ecommerce

### 3. DAG'ı Çalıştırma

1. Airflow UI'a giriş yap (http://localhost:8080)
2. ecommerce_dbt_pipeline DAG'ını bul
3. DAG'ı aktif hale getir (toggle switch)
4. Manuel çalıştırmak için "Trigger DAG" butonuna tıkla

DAG otomatik olarak her gün saat 10:00'da çalışacak.

## Veri Modelleri

### Model 1: monthly_product_sales

Amaç: Her ürünün aylık satış performansını analiz eder.

Kolonlar:
- product_id: Ürün ID
- order_month: Sipariş ayı
- year_month: Yıl-Ay (YYYY-MM)
- total_orders: Toplam sipariş sayısı
- total_sales_amount: Toplam satış tutarı
- avg_order_amount: Ortalama sipariş tutarı
- min_order_amount: Minimum sipariş tutarı
- max_order_amount: Maximum sipariş tutarı

Sorgu Örneği:
sql
SELECT * FROM analytics.monthly_product_sales
WHERE year = 2024 AND month = 11
ORDER BY total_sales_amount DESC;


### Model 2: monthly_category_performance

Amaç: İlk modeli kullanarak kategori bazlı aylık performans analizi yapar.

Kolonlar:
- product_category: Ürün kategorisi
- order_month: Sipariş ayı
- year_month: Yıl-Ay (YYYY-MM)
- unique_products_sold: Satılan benzersiz ürün sayısı
- total_orders: Toplam sipariş sayısı
- total_sales_amount: Toplam satış tutarı
- avg_order_amount: Ortalama sipariş tutarı
- category_avg_order_value: Kategori ortalama sipariş değeri

Sorgu Örneği:
sql
SELECT 
    product_category,
    year_month,
    total_orders,
    total_sales_amount,
    category_avg_order_value
FROM analytics.monthly_category_performance
WHERE year = 2024
ORDER BY total_sales_amount DESC;


## Pipeline Akışı


1. start_pipeline
   ↓
2. dbt_deps (Bağımlılıkları yükle)
   ↓
3. dbt_debug (Bağlantıyı test et)
   ↓
4. dbt_run_staging (Staging modellerini çalıştır)
   ↓
5. dbt_run_monthly_product_sales (Model 1)
   ↓
6. dbt_run_monthly_category_performance (Model 2)
   ↓
7. dbt_test (Testleri çalıştır)
   ↓
8. complete_pipeline








