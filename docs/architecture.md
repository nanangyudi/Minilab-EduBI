# Arsitektur Minilab EduBI

## Gambaran Umum

Minilab EduBI menerapkan **Medallion Architecture** (Bronze → Silver → Gold) dengan ClickHouse sebagai Data Warehouse utama yang mendukung koneksi network, sehingga Metabase dapat terhubung langsung.

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
           └────────────────────┴────────────────────────┘
                                │
                     ┌──────────▼──────────┐
                     │   ETL Python        │
                     │   etl/run_pipeline  │
                     └──────────┬──────────┘
                                │
┌───────────────────────────────▼─────────────────────────────────────┐
│                   ClickHouse — Data Warehouse                        │
│                                                                     │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────────────┐  │
│  │   BRONZE     │    │   SILVER     │    │        GOLD          │  │
│  │  (database)  │    │  (database)  │    │     (database)       │  │
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
                                    │         METABASE             │
                                    │   Terhubung langsung ke      │
                                    │   ClickHouse gold database   │
                                    │   http://localhost:3000      │
                                    └─────────────────────────────┘
```

## Layer Penjelasan

### Bronze — Raw Data
- Data masuk **apa adanya**, tanpa transformasi
- Semua kolom bertipe `String` (raw)
- Dibuat oleh: `etl/run_pipeline.py` → `etl/load_csv.py`
- Database ClickHouse: `bronze`

### Silver — Cleaned Data
- Data sudah **dibersihkan**: casting tipe, null ditangani, normalisasi
- Tambah kolom turunan: `order_year`, `order_month`, `sentiment`, `revenue_category`
- Dibuat oleh: `dbt run` → model di `dbt_project/models/silver/`
- Database ClickHouse: `silver`

### Gold — BI-Ready Data
- Data sudah **diagregasi** dan siap untuk dashboard
- Metrik bisnis: KPI, daily revenue, review summary
- Dibuat oleh: `dbt run` → model di `dbt_project/models/gold/`
- Database ClickHouse: `gold`
- **Metabase connect langsung ke sini**

## Stack Teknologi

| Komponen    | Tool                   | Peran                                             |
|-------------|------------------------|---------------------------------------------------|
| Data Warehouse | ClickHouse 24.3     | Database kolumnar, mendukung koneksi network      |
| ETL         | Python + pandas        | Load CSV dan extract dari sumber ke bronze        |
| Transformasi| dbt Core + dbt-clickhouse | SQL transformasi Bronze → Silver → Gold        |
| Visualisasi | Metabase               | Dashboard interaktif, connect ke ClickHouse       |
| Source DB   | PostgreSQL 15          | Simulasi Odoo ERP (odoo_sim schema)               |
| Runtime     | Docker Compose         | Orchestrasi semua service secara lokal            |

## Keputusan Teknis

### Mengapa ClickHouse (bukan DuckDB)?

| Aspek | DuckDB | ClickHouse |
|---|---|---|
| Tipe | Embedded (file-based) | Client-server |
| Koneksi network | ✗ Tidak bisa | ✓ Bisa (port 8123) |
| Metabase connect langsung | ✗ Tidak | ✓ Ya |
| Performa OLAP | Sangat baik | Sangat baik |
| Setup Docker | Rumit (shared file) | Mudah (service biasa) |

ClickHouse dipilih karena **Metabase dapat connect langsung** ke database Gold tanpa perlu jembatan export, sehingga arsitektur lebih sederhana dan mudah dipahami mahasiswa.

### Peran PostgreSQL
PostgreSQL hanya digunakan untuk:
1. Simulasi sumber data Odoo (`odoo_sim` schema)
2. Menyimpan metadata internal Metabase

PostgreSQL **bukan** bagian dari Data Warehouse.
