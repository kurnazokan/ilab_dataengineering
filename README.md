# iLab Data Engineering Cases

Bu repository, data engineering case çalışmalarını içerir.

## 📁 Klasör Yapısı

### case1/
İlk case çalışması (boş - gelecek projeler için hazır)

### case2/
**E-Commerce Analytics Pipeline (DBT + Airflow + Docker)**

DBT ve Airflow kullanarak e-ticaret verilerinin analiz edilmesi:
- Her ürünün aylık satış analizi
- Her kategorinin aylık performans raporu
- Her gün saat 10:00'da otomatik çalışan pipeline
- Docker üzerinde tam entegre sistem

Detaylar için: [case2/README.md](./case2/README.md)

## 🚀 Hızlı Başlangıç

### Case 2'yi Çalıştırmak:

```bash
cd case2
docker-compose up -d

# Airflow UI: http://localhost:8080 (admin/admin)
# PostgreSQL: localhost:5432 (airflow/airflow)
```

## 📚 Teknolojiler

- **DBT** - Data transformation
- **Apache Airflow** - Workflow orchestration
- **PostgreSQL** - Database
- **Docker** - Containerization
- **Python** - Scripting

## 👤 Yazar

Okan Kurnaz
- GitHub: [@kurnazokan](https://github.com/kurnazokan)

