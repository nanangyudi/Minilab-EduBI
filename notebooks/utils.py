"""
notebooks/utils.py
Minilab EduBI — Fase 2 Helper Utilities

Menyediakan fungsi bantu untuk koneksi ke ClickHouse, MLflow,
dan utilitas umum yang digunakan di semua notebook Fase 2.

Penggunaan:
    import sys; sys.path.insert(0, '/home/jovyan/work/notebooks')
    from utils import get_ch_client, read_sql, mlflow_setup
"""

import os
import pandas as pd
import clickhouse_connect
import mlflow


# ─────────────────────────────────────────────────────────────────────────────
# ClickHouse
# ─────────────────────────────────────────────────────────────────────────────

def get_ch_client():
    """
    Membuat koneksi ke ClickHouse menggunakan environment variables.

    Returns:
        clickhouse_connect.Client

    Env vars:
        CH_HOST     (default: localhost)
        CH_PORT     (default: 8123)
        CH_USER     (default: default)
        CH_PASSWORD (default: '')
    """
    return clickhouse_connect.get_client(
        host=os.getenv("CH_HOST", "localhost"),
        port=int(os.getenv("CH_PORT", "8123")),
        username=os.getenv("CH_USER", "default"),
        password=os.getenv("CH_PASSWORD", ""),
    )


def read_sql(query: str, client=None) -> pd.DataFrame:
    """
    Menjalankan query SQL ke ClickHouse dan mengembalikan DataFrame.

    Args:
        query:  String SQL yang akan dieksekusi
        client: clickhouse_connect.Client (opsional; dibuat otomatis jika None)

    Returns:
        pd.DataFrame
    """
    if client is None:
        client = get_ch_client()
    return client.query_df(query)


# ─────────────────────────────────────────────────────────────────────────────
# MLflow
# ─────────────────────────────────────────────────────────────────────────────

def mlflow_setup(experiment_name: str) -> str:
    """
    Konfigurasi MLflow tracking URI dan buat/set experiment.

    Args:
        experiment_name: Nama experiment MLflow

    Returns:
        experiment_id (str)

    Env vars:
        MLFLOW_TRACKING_URI (default: http://localhost:5000)
    """
    tracking_uri = os.getenv("MLFLOW_TRACKING_URI", "http://localhost:5000")
    mlflow.set_tracking_uri(tracking_uri)
    mlflow.set_experiment(experiment_name)
    exp = mlflow.get_experiment_by_name(experiment_name)
    return exp.experiment_id if exp else None


# ─────────────────────────────────────────────────────────────────────────────
# Utilitas umum
# ─────────────────────────────────────────────────────────────────────────────

def show_ch_tables(schema: str = "silver", client=None) -> pd.DataFrame:
    """
    Menampilkan daftar tabel di schema ClickHouse.

    Args:
        schema: Nama database/schema (bronze | silver | gold)
        client: clickhouse_connect.Client (opsional)

    Returns:
        pd.DataFrame dengan kolom name, engine, total_rows, total_bytes
    """
    query = f"""
    SELECT
        name,
        engine,
        formatReadableQuantity(total_rows)   AS total_rows,
        formatReadableSize(total_bytes)       AS total_bytes
    FROM system.tables
    WHERE database = '{schema}'
    ORDER BY name
    """
    return read_sql(query, client)


def info(df: pd.DataFrame) -> pd.DataFrame:
    """
    Ringkasan kolom DataFrame: dtype, null count, null%, unique count.

    Args:
        df: DataFrame yang ingin dianalisis

    Returns:
        pd.DataFrame ringkasan
    """
    stats = pd.DataFrame({
        "dtype":      df.dtypes,
        "null_count": df.isna().sum(),
        "null_pct":   (df.isna().mean() * 100).round(2),
        "unique":     df.nunique(),
    })
    return stats
