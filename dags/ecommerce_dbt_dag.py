from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.python import PythonOperator
import logging

# Default arguments
default_args = {
    'owner': 'data-team',
    'depends_on_past': False,
    'start_date': datetime(2024, 1, 1),
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 2,
    'retry_delay': timedelta(minutes=5),
}

# DAG tanımı
dag = DAG(
    'ecommerce_dbt_pipeline',
    default_args=default_args,
    description='E-ticaret analiz modelleri için günlük DBT pipeline',
    schedule_interval='0 10 * * *',  # Her gün saat 10:00
    catchup=False,
    tags=['dbt', 'ecommerce', 'analytics'],
)


def log_start():
    """Pipeline başlangıcı loglama"""
    logging.info("E-Ticaret DBT Pipeline başlatıldı")
    logging.info(f"Çalışma zamanı: {datetime.now()}")


def log_completion():
    """Pipeline tamamlanma loglama"""
    logging.info("E-Ticaret DBT Pipeline başarıyla tamamlandı")
    logging.info(f"Tamamlanma zamanı: {datetime.now()}")


# Task 1: Pipeline başlangıç bildirimi
start_task = PythonOperator(
    task_id='start_pipeline',
    python_callable=log_start,
    dag=dag,
)

# Task 2: Staging modellerini çalıştır
dbt_run_staging = BashOperator(
    task_id='dbt_run_staging',
    bash_command='cd /opt/airflow/dbt_project && dbt run --profiles-dir . --target dev --select staging.*',
    dag=dag,
)

# Task 3: Model 1 - Monthly Product Sales (Her ürünün aylık satış analizi)
dbt_run_monthly_product_sales = BashOperator(
    task_id='dbt_run_monthly_product_sales',
    bash_command='cd /opt/airflow/dbt_project && dbt run --profiles-dir . --target dev --select monthly_product_sales',
    dag=dag,
)

# Task 4: Model 2 - Monthly Category Performance (Kategori bazlı aylık performans)
dbt_run_monthly_category_performance = BashOperator(
    task_id='dbt_run_monthly_category_performance',
    bash_command='cd /opt/airflow/dbt_project && dbt run --profiles-dir . --target dev --select monthly_category_performance',
    dag=dag,
)

# Task 5: DBT test - Model testlerini çalıştır
dbt_test = BashOperator(
    task_id='dbt_test',
    bash_command='cd /opt/airflow/dbt_project && dbt test --profiles-dir . --target dev',
    dag=dag,
)

# Task 6: Pipeline tamamlanma bildirimi
end_task = PythonOperator(
    task_id='complete_pipeline',
    python_callable=log_completion,
    dag=dag,
)

# Task bağımlılıkları - Sıralı çalışma
(
    start_task
    >> dbt_run_staging
    >> dbt_run_monthly_product_sales  # İlk model
    >> dbt_run_monthly_category_performance  # İkinci model (ilk modele bağımlı)
    >> dbt_test
    >> end_task
)

