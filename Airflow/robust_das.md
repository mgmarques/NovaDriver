# Copy Into Pattern
For a **production-grade Snowflake pipeline**. Moving from `write_pandas` to a proper **`COPY INTO` + staging pattern** gives you:
*  Much better scalability (handles millions/billions of rows)
*  Lower Snowflake credit usage
*  Better retry/recovery (files are staged)
*  Auditability (you can track loaded files)

---
# Architecture (What we’re building)

For each table:
1. Extract from Postgres
2. Save as CSV
3. Upload to **S3**
4. Snowflake loads via `COPY INTO`
5. (Optional) clean S3 or keep for audit

---

# Prerequisites (One-time setup)

## 1. Create S3 Stage in Snowflake
```sql
CREATE STAGE my_s3_stage
URL='s3://your-bucket/snowflake/'
CREDENTIALS=(AWS_KEY_ID='XXX' AWS_SECRET_KEY='XXX');
```

Note: Better (recommended): use IAM role instead of keys

---
## 2. File Format

```sql
CREATE FILE FORMAT my_csv_format
TYPE = CSV
FIELD_OPTIONALLY_ENCLOSED_BY = '"'
SKIP_HEADER = 1;
```

---
# Airflow DAG (S3 + COPY INTO)
This version:
*  Airflow 2.7+
*  Dynamic mapping
*  S3 staging
*  COPY INTO
*  Production-safe

```python
from datetime import datetime, timedelta
from airflow.sdk import dag, task
from airflow.providers.postgres.hooks.postgres import PostgresHook
from airflow.providers.snowflake.hooks.snowflake import SnowflakeHook
from airflow.providers.amazon.aws.hooks.s3 import S3Hook
import pandas as pd
import tempfile
import os

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

S3_BUCKET = "your-bucket"
S3_PREFIX = "snowflake_stage/"
SNOWFLAKE_STAGE = "@my_s3_stage"

@dag(
    dag_id='postgres_to_snowflake_copy_into',
    default_args=default_args,
    schedule=timedelta(days=1),
    catchup=False
)
def etl():

    @task
    def get_max_ids(tables: list[str]) -> dict:
        sf = SnowflakeHook(snowflake_conn_id='snowflake')
        result = {}

        with sf.get_conn() as conn:
            with conn.cursor() as cur:
                for t in tables:
                    cur.execute(f"SELECT MAX(ID_{t.upper()}) FROM {t.upper()}")
                    val = cur.fetchone()[0]
                    result[t] = val if val else 0

        return result

    @task
    def extract_to_s3(table: str, max_id: int) -> str | None:

        pg = PostgresHook(postgres_conn_id='postgres')
        s3 = S3Hook(aws_conn_id='aws_default')

        pk = f"id_{table}"

        query = f"""
            SELECT *
            FROM {table}
            WHERE {pk} > %s
        """

        df = pd.read_sql(query, pg.get_conn(), params=(max_id,))

        if df.empty:
            return None

        # Normalize columns
        df.columns = [c.upper() for c in df.columns]

        # Fix datetime
        for col in df.select_dtypes(include=['datetimetz']).columns:
            df[col] = df[col].dt.tz_convert(None)

        # Save temp file
        tmp = tempfile.NamedTemporaryFile(delete=False, suffix=".csv")
        df.to_csv(tmp.name, index=False)

        file_key = f"{S3_PREFIX}{table}/{os.path.basename(tmp.name)}"

        # Upload to S3
        s3.load_file(
            filename=tmp.name,
            key=file_key,
            bucket_name=S3_BUCKET,
            replace=True
        )

        return file_key

    @task
    def copy_into(table: str, s3_key: str | None):

        if not s3_key:
            return f"No data for {table}"

        sf = SnowflakeHook(snowflake_conn_id='snowflake')

        with sf.get_conn() as conn:
            with conn.cursor() as cur:

                copy_sql = f"""
                    COPY INTO {table.upper()}
                    FROM {SNOWFLAKE_STAGE}/{s3_key.replace(S3_PREFIX, '')}
                    FILE_FORMAT = my_csv_format
                """

                cur.execute(copy_sql)

        return f"{table} loaded"

    max_ids = get_max_ids(TABLES)

    s3_files = extract_to_s3.expand(
        table=TABLES,
        max_id=[max_ids[t] for t in TABLES]
    )

    copy_into.expand(
        table=TABLES,
        s3_key=s3_files
    )

etl_dag = etl()
```

---
# Why This Is Better

### Performance
* Snowflake loads **in parallel internally**
* Much faster than `write_pandas`

### Cost
* Fewer queries → fewer credits

### Reliability
* Files in S3 = retryable + auditable

---
# Common Pitfalls
## 1. Stage path mismatch
If this fails:

```
file not found
```

Note: Your stage path must match:

```
s3://your-bucket/snowflake/
```

---
## 2. Permissions
Make sure Snowflake can read S3:
* IAM role OR keys

---
## 3. Case sensitivity
Still critical:

```
TABLE → UPPERCASE
COLUMNS → UPPERCASE
```

---
# Next Step (Recommended)
Now that you have COPY INTO, the **real production move** is:

Note: Add a **MERGE (UPSERT)** layer

So instead of:

```
append only
```

You get:

```
insert + update (CDC-like behavior)
```
