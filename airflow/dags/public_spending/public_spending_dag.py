from datetime import timedelta, datetime
from airflow import DAG
from airflow.operators.bash_operator import BashOperator
from airflow.operators.python_operator import PythonOperator
from airflow.utils.dates import days_ago
import pendulum
from airflow.operators.publicdata_plugin import DownloadFileOperator, PandasToPostgresTransfer

local_tz = pendulum.timezone('America/Sao_Paulo')
"""
USE CORRECT TIMEZONE WHEN SCHEDULING DAGs
'start_date': datetime(2020, 08, 13, 1, tzinfo=local_tz)
"""

default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'start_date': datetime(2020, 8, 14, 1, tzinfo=local_tz),
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5)
}
with DAG(dag_id="medication",
         schedule_interval="@monthly", catchup=False, default_args=default_args) as dag:

    pass
    # download_data_from_government = PythonOperator(
    #     task_id='download_from_website',
    #     provide_context=True,
    #     python_callable=download_from_anvisa.main
    # )
    
    # load_to_postgres = PythonOperator(
    #     task_id='load_to_postgres',
    #     provide_context=True,
    #     python_callable=data_validation.main
    # )

    # validate_data = PythonOperator(
    #     task_id='validate_data',
    #     provide_context=True,
    #     python_callable=load_to_mongodb.main
    # )

    # download_medication_anvisa >> convert_to_parquet >> generate_dataset_to_mobile
    # generate_dataset_to_mobile >> data_validation
    # data_validation >> load_mongodb
