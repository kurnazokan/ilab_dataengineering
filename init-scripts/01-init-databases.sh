#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE DATABASE ecommerce;
    GRANT ALL PRIVILEGES ON DATABASE ecommerce TO airflow;
EOSQL

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "ecommerce" <<-EOSQL
    -- Orders tablosu
    CREATE TABLE IF NOT EXISTS orders (
        order_id SERIAL PRIMARY KEY,
        customer_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        order_date DATE NOT NULL,
        total_amount DECIMAL(10, 2) NOT NULL
    );

    -- Products tablosu
    CREATE TABLE IF NOT EXISTS products (
        product_id SERIAL PRIMARY KEY,
        product_category VARCHAR(100) NOT NULL,
        product_price DECIMAL(10, 2) NOT NULL
    );

    -- CSV dosyalarından veri yükleme
    -- Not: CSV dosyaları /data dizinine mount edilmiş
    
    -- Products tablosuna CSV'den veri yükle
    COPY products(product_id, product_category, product_price)
    FROM '/data/products.csv'
    DELIMITER ','
    CSV HEADER;

    -- Orders tablosuna CSV'den veri yükle
    COPY orders(order_id, customer_id, product_id, order_date, total_amount)
    FROM '/data/orders.csv'
    DELIMITER ','
    CSV HEADER;

    -- Analytics schema oluştur
    CREATE SCHEMA IF NOT EXISTS analytics;
    GRANT ALL PRIVILEGES ON SCHEMA analytics TO airflow;
EOSQL

