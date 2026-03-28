# Arsitektur Minilab EduBI

## Gambaran Umum

Minilab EduBI menerapkan **Medallion Architecture** (Bronze → Silver → Gold) dengan stack teknologi ringan yang cocok dijalankan di laptop mahasiswa.

## Diagram Arsitektur

```
┌─────────────────────────────────────────────────────────────────────┐
│                        SUMBER DATA                                  │
│                                                                     │
│  ┌───────────────┐  ┌──────────────────┐  ┌─────────────────────┐  │
│  │  CSV / Excel  │  │  PostgreSQL       │  │  Google Reviews API │  │
│  │  (sample data)│  │  (odoo_sim schema)│  │  (atau CSV fallback)│  │
│  └───────┬───────┘  └────────┬─────────┘  └──────────┬──────────┘  │
└──────────┼────────────────────┼────────────────────────┼────────────┘
           │                    │                        │
           └────────────────────┴────────────────────────┘
                                │
                     ┌──────────▼──────────┐
                     │   ETL Python        │
                     │   etl/run_pipeline  │
                     └──────────┬──────────┘
                                │
┌───────────────────────────────▼─────────────────────────────────────┐
│                        DuckDB (lab_bi.duckdb)                        │
│                                                                     │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────────────┐  │
│  │   BRONZE     │    │   SILVER     │    │        GOLD          │  │
│  │              │    │              │    │                      │  │
│  │ bronze.sales │───▶│ silver.sales │───▶│ gold.sales_daily     │  │
│  │ bronze.      │    │ silver.      │    │ gold.branch_kpi      │  │
│  │   customers  │───▶│   customers  │    │ gold.review_summary  │  │
│  │ bronze.      │    │ silver.      │───▶│                      │  │
│  │   reviews    │───▶│   reviews    │    │                      │  │
│  │ bronze.      │    │ silver.      │    │                      │  │
│  │   targets    │───▶│   targets    │───▶│                      │  │
│  └──────────────┘    └──────────────┘    └──────────┬───────────┘  │
│       ETL Python          dbt run              dbt run             │
└───────────────────────────────────────────────────────────────────-─┘
                                                       │
                                    ┌──────────────────▼──────────┐
                                    │  export_gold_to_postgres.py │
                                    └──────────────────┬──────────┘
                                                       │
                                    ┌──────────────────▼──────────┐
                                    │ PostgreSQL analytics schema  │
                                    │  analytics.gold_sales_daily  │
                                    │  analytics.gold_branch_kpi   │
                                    │  analytics.gold_review_...   │
                                    └──────────────────┬──────────┘
                                                       │
                                    ┌──────────────────▼──────────┐
                                    │         METABASE             │
                                    │   Dashboard & Visualisasi    │
                                    │   http://localhost:3000      │
                                    └─────────────────────────────┘
```

## Layer Penjelasan

### Bronze — Raw Data
- Data masuk apa adanya, **tanpa transformasi**
- Dibuat oleh: `etl/run_pipeline.py` → `etl/load_csv.py`
- Tabel: `bronze.sales`, `bronze.customers`, `bronze.reviews`, `bronze.targets`
- Format: sesuai file CSV source

### Silver — Cleaned Data
- Data sudah **dibersihkan**: tipe data benar, null ditangani, duplikat dihapus
- Tambah kolom turunan: `order_year`, `order_month`, `sentiment`, `revenue_category`
- Dibuat oleh: `dbt run` → model di `dbt_project/models/silver/`
- Tabel: `silver.silver_*`

### Gold — BI-Ready Data
- Data sudah **diagregasi** dan siap untuk dashboard
- Metrik bisnis: KPI, daily revenue, review summary
- Dibuat oleh: `dbt run` → model di `dbt_project/models/gold/`
- Tabel: `gold.gold_sales_daily`, `gold.gold_branch_kpi`, `gold.gold_review_summary`
- Diekspor ke PostgreSQL schema `analytics` agar bisa dibaca Metabase

## Stack Teknologi

| Komponen    | Tool                  | Peran                                            |
|-------------|-----------------------|--------------------------------------------------|
| Storage     | DuckDB 1.1.3          | Embedded database untuk Bronze/Silver/Gold        |
| ETL         | Python + pandas       | Load CSV dan extract dari sumber ke bronze        |
| Transformasi| dbt Core + dbt-duckdb | SQL transformasi Bronze → Silver → Gold          |
| Visualisasi | Metabase              | Dashboard interaktif untuk demo BI               |
| Source DB   | PostgreSQL 15         | Simulasi Odoo ERP + analytics bridge Metabase    |
| Runtime     | Docker Compose        | Orchestrasi semua service secara lokal           |

## Keputusan Teknis

### Mengapa DuckDB tidak langsung ke Metabase?
DuckDB adalah **embedded database** (file-based), tidak mendukung koneksi network seperti PostgreSQL atau MySQL. Metabase memerlukan koneksi JDBC/network, sehingga DuckDB tidak bisa dijadikan data source Metabase secara langsung.

**Solusi**: Hasil Gold diekspor ke schema `analytics` di PostgreSQL. Metabase membaca dari sini.

### Mengapa satu PostgreSQL untuk dua tujuan?
Untuk PoC mahasiswa, memiliki satu PostgreSQL dengan dua schema (`odoo_sim` dan `analytics`) lebih sederhana dan menghemat resource dibanding dua container terpisah.
