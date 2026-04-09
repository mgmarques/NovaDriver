''''
This is a production-grade Snowflake pipeline. Moving from write_pandas to a proper COPY INTO + staging pattern gives you:
* Much better scalability (handles millions/billions of rows)
* Lower Snowflake credit usage
* Better retry/recovery (files are staged)
* Auditability (you can track loaded files)
* Architecture Overview

Instead of pushing rows directly:
* Extract data from Postgres
* Save to CSV files (locally or temp)
* Upload to Snowflake stage (PUT)
* Load using COPY INTO
* (Optional) Clean up staged files

'''
from datetime import datetime, timedelta
from airflow.decorators import dag, task
from airflow.providers.postgres.hooks.postgres import PostgresHook
from airflow.providers.snowflake.hooks.snowflake import SnowflakeHook
import pandas as pd
import tempfile
import os

default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'start_date': datetime(2024, 1, 1),
    'retries': 0,
    'retry_delay': timedelta(minutes=1),
}

STAGE_NAME = "@my_internal_stage"  # must exist in Snowflake

@dag(
    dag_id='postgres_to_snowflake_copy_into',
    default_args=default_args,
    schedule=timedelta(days=1),
    catchup=False
)
def postgres_to_snowflake_etl():

    table_names = ['veiculos', 'estados', 'cidades', 'concessionarias', 'vendedores', 'clientes', 'vendas']

    for table_name in table_names:

        @task(task_id=f'get_max_id_{table_name}')
        def get_max_primary_key(table_name: str):
            with SnowflakeHook(snowflake_conn_id='snowflake').get_conn() as conn:
                with conn.cursor() as cursor:
                    cursor.execute(f"SELECT MAX(ID_{table_name}) FROM {table_name}")
                    result = cursor.fetchone()[0]
                    return result if result else 0

        @task(task_id=f'extract_and_stage_{table_name}')
        def extract_and_stage(table_name: str, max_id: int):

            pg_hook = PostgresHook(postgres_conn_id='postgres')
            sf_hook = SnowflakeHook(snowflake_conn_id='snowflake')

            primary_key = f'ID_{table_name}'

            with pg_hook.get_conn() as pg_conn:
                query = f"""
                    SELECT *
                    FROM {table_name}
                    WHERE {primary_key} > %s
                """
                df = pd.read_sql(query, pg_conn, params=(max_id,))

            if df.empty:
                return None

            # Create temp CSV
            tmp_file = tempfile.NamedTemporaryFile(delete=False, suffix=".csv")
            df.to_csv(tmp_file.name, index=False, header=True)

            file_name = os.path.basename(tmp_file.name)

            # Upload to Snowflake stage
            with sf_hook.get_conn() as conn:
                with conn.cursor() as cursor:
                    cursor.execute(f"PUT file://{tmp_file.name} {STAGE_NAME} AUTO_COMPRESS=TRUE")

            return file_name

        @task(task_id=f'copy_into_{table_name}')
        def copy_into_snowflake(table_name: str, staged_file: str):

            if not staged_file:
                return "No data to load"

            sf_hook = SnowflakeHook(snowflake_conn_id='snowflake')

            with sf_hook.get_conn() as conn:
                with conn.cursor() as cursor:

                    copy_sql = f"""
                        COPY INTO {table_name}
                        FROM {STAGE_NAME}
                        FILES = ('{staged_file}.gz')
                        FILE_FORMAT = (
                            TYPE = 'CSV',
                            FIELD_OPTIONALLY_ENCLOSED_BY = '"',
                            SKIP_HEADER = 1
                        )
                    """
                    cursor.execute(copy_sql)

                    # Optional cleanup
                    cursor.execute(f"REMOVE {STAGE_NAME} PATTERN='.*{staged_file}.*'")

            return f"Loaded {table_name}"

        max_id = get_max_primary_key(table_name)
        staged_file = extract_and_stage(table_name, max_id)
        copy_into_snowflake(table_name, staged_file)


postgres_to_snowflake_etl_dag = postgres_to_snowflake_etl()