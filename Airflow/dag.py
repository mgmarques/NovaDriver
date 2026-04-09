from datetime import datetime, timedelta
from airflow.sdk import dag, task
from airflow.providers.postgres.hooks.postgres import PostgresHook
from airflow.providers.snowflake.hooks.snowflake import SnowflakeHook
from snowflake.connector.pandas_tools import write_pandas
import pandas as pd

default_args = {
    'owner': 'airflow',
    'start_date': datetime(2024, 1, 1),
    'retries': 0,
    'retry_delay': timedelta(minutes=1),
}

TABLES = [
    'veiculos', 'estados', 'cidades',
    'concessionarias', 'vendedores', 'clientes', 'vendas'
]

@dag(
    dag_id='postgres_to_snowflake_v4',
    default_args=default_args,
    schedule=timedelta(days=1),
    catchup=False
)
def postgres_to_snowflake_etl():

    @task
    def get_max_ids(table_names: list[str]) -> dict:
        """Busca o último ID de cada tabela no Snowflake."""
        sf = SnowflakeHook(snowflake_conn_id='snowflake')
        result = {}

        with sf.get_conn() as conn:
            with conn.cursor() as cur:
                for t in table_names:
                    cur.execute(f"SELECT MAX(ID_{t.upper()}) FROM {t.upper()}")
                    val = cur.fetchone()[0]
                    result[t] = val if val else 0

        return result

    @task
    def generate_carga_id() -> int:
        """Gera um CARGA_ID único baseado em timestamp UTC."""
        return int(datetime.utcnow().strftime("%Y%m%d%H%M%S"))

    @task
    def build_mapping_inputs(max_ids: dict, carga_id: int) -> list[dict]:
        """Cria lista de inputs para dynamic mapping."""
        return [
            {"table_name": table, "max_id": max_ids[table], "carga_id": carga_id}
            for table in TABLES
        ]

    @task
    def extract_and_load(table_name: str, max_id: int, carga_id: int):

        pg = PostgresHook(postgres_conn_id='postgres')
        sf = SnowflakeHook(snowflake_conn_id='snowflake')

        pk = f'id_{table_name}'

        # Extract incremental
        df = pd.read_sql(
            f"""
            SELECT *
            FROM {table_name}
            WHERE {pk} > %s
            """,
            pg.get_conn(),
            params=(max_id,)
        )

        if df.empty:
            return f"No data for {table_name}"

        # Normalize column names para Snowflake
        df.columns = [c.upper() for c in df.columns]

        # Adiciona CARGA_ID
        df["CARGA_ID"] = carga_id

        # Remove timezone de datetimes
        for col in df.select_dtypes(include=['datetimetz']).columns:
            df[col] = df[col].dt.tz_convert(None)

        # Load para Snowflake via write_pandas
        with sf.get_conn() as conn:
            success, nchunks, nrows, _ = write_pandas(
                conn=conn,
                df=df,
                table_name=table_name.upper(),
                quote_identifiers=False,
                auto_create_table=False,
                use_logical_type=True
            )

        return f"{table_name}: {nrows} rows loaded with CARGA_ID {carga_id}"

    # --- DAG logic ---
    max_ids = get_max_ids(TABLES)
    carga_id = generate_carga_id()
    mapping_inputs = build_mapping_inputs(max_ids, carga_id)

    # Dynamic mapping
    extract_and_load.expand_kwargs(mapping_inputs)

postgres_to_snowflake_etl_dag = postgres_to_snowflake_etl()
