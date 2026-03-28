# Minilab EduBI

**Proof of Concept Business Intelligence** untuk mahasiswa Program Studi Sistem Informasi.
Mendemonstrasikan pipeline data end-to-end menggunakan stack modern yang ringan dan bisa dijalankan di laptop.

## Stack Teknologi

| Komponen    | Tool           | Versi  |
|-------------|----------------|--------|
| Database    | DuckDB         | 1.1.3  |
| ETL         | Python + pandas| 3.11   |
| Transformasi| dbt Core       | 1.8.7  |
| Dashboard   | Metabase       | 0.50   |
| Source DB   | PostgreSQL     | 15     |
| Runtime     | Docker Compose | 2.x    |

## Arsitektur

Proyek ini menerapkan **Medallion Architecture**:

```
CSV / PostgreSQL → ETL Python → DuckDB Bronze → dbt → Silver → Gold → Export → Metabase
```

| Layer  | Keterangan                                 | Tool       |
|--------|--------------------------------------------|------------|
| Bronze | Raw data mentah dari sumber                | Python ETL |
| Silver | Data bersih dengan tipe dan validasi       | dbt        |
| Gold   | Agregasi siap dashboard                    | dbt        |

Lihat detail di [`docs/architecture.md`](docs/architecture.md).

## Domain Bisnis

**Sales & Customer Insight** — toko elektronik multi-cabang dengan entitas:
- Orders / Penjualan (50 transaksi sample)
- Customers (20 customer sample)
- Google Reviews (30 ulasan sample)
- Sales Targets (target bulanan per cabang)

Cabang: Pusat, Bandung, Surabaya, Selatan, Yogyakarta.

---

## Cara Menjalankan (Docker)

### Prasyarat
- Docker Desktop sudah terinstall dan berjalan
- Port 3000 dan 5432 tidak dipakai aplikasi lain

### Langkah-langkah

```bash
# 1. Clone repository
git clone https://github.com/nanangyudi/Minilab-EduBI.git
cd Minilab-EduBI

# 2. Salin konfigurasi
cp .env.example .env

# 3. Build image
docker compose build

# 4. Jalankan PostgreSQL
docker compose up -d postgres
# Tunggu ~15 detik hingga status "healthy"

# 5. Jalankan ETL (sekali jalan)
docker compose run --rm app

# 6. Jalankan dbt (sekali jalan)
docker compose run --rm dbt

# 7. Jalankan Metabase
docker compose up -d metabase
# Buka http://localhost:3000 (tunggu ~2 menit)
```

Lihat panduan lengkap di [`docs/deployment.md`](docs/deployment.md).

---

## Cara Menjalankan (Lokal tanpa Docker)

```bash
# 1. Install dependency
pip install -r requirements.txt

# 2. Salin konfigurasi
cp .env.example .env
# Edit .env: pastikan PG_HOST=localhost jika PostgreSQL jalan lokal

# 3. Jalankan ETL
cd etl && python run_pipeline.py

# 4. Setup dbt
cd ../dbt_project
cp profiles.yml.example profiles.yml
dbt run --profiles-dir .
dbt test --profiles-dir .

# 5. Export Gold ke PostgreSQL
cd ..
python scripts/export_gold_to_postgres.py
```

---

## Struktur Proyek

```
Minilab-EduBI/
│
├── README.md
├── requirements.txt
├── Dockerfile
├── docker-compose.yml
├── .env.example
├── .gitignore
│
├── data/
│   ├── raw/                    ← sample CSV (dikecualikan dari .gitignore)
│   │   ├── sample_sales.csv
│   │   ├── sample_customers.csv
│   │   ├── sample_reviews.csv
│   │   └── sample_targets.csv
│   ├── processed/
│   └── warehouse/
│       └── lab_bi.duckdb       ← dibuat saat runtime
│
├── etl/
│   ├── utils.py                ← helper koneksi DB & logging
│   ├── init_duckdb.py          ← inisialisasi DuckDB + schema
│   ├── load_csv.py             ← load CSV ke bronze DuckDB
│   ├── extract_odoo.py         ← extract dari PG odoo_sim
│   ├── extract_google_reviews.py
│   └── run_pipeline.py         ← orchestrator ETL
│
├── dbt_project/
│   ├── dbt_project.yml
│   ├── profiles.yml.example
│   ├── macros/
│   │   └── generate_schema_name.sql
│   └── models/
│       ├── sources.yml
│       ├── schema.yml           ← tests not_null & unique
│       ├── bronze/
│       │   ├── bronze_sales.sql
│       │   ├── bronze_customers.sql
│       │   ├── bronze_reviews.sql
│       │   └── bronze_targets.sql
│       ├── silver/
│       │   ├── silver_sales.sql
│       │   ├── silver_customers.sql
│       │   ├── silver_reviews.sql
│       │   └── silver_targets.sql
│       └── gold/
│           ├── gold_sales_daily.sql
│           ├── gold_branch_kpi.sql
│           └── gold_review_summary.sql
│
├── scripts/
│   ├── init_postgres.sql        ← seed data PostgreSQL
│   ├── run_etl.sh
│   ├── run_dbt.sh
│   └── export_gold_to_postgres.py
│
├── notebooks/
│   └── exploration.ipynb        ← eksplorasi data DuckDB
│
└── docs/
    ├── architecture.md
    ├── data_dictionary.md
    ├── deployment.md
    └── metabase_setup.md
```

---

## Output Dashboard Metabase

Setelah pipeline selesai, tersedia 3 tabel di PostgreSQL schema `analytics`:

| Tabel                  | Isi                                          |
|------------------------|----------------------------------------------|
| `gold_sales_daily`     | Revenue & orders harian per cabang           |
| `gold_branch_kpi`      | KPI: revenue, orders, avg, pencapaian target |
| `gold_review_summary`  | Rata-rata rating & distribusi sentimen       |

Dashboard yang bisa dibuat di Metabase:
- **Sales Performance**: tren revenue, top cabang, kategori produk
- **Customer Insight**: profil customer, distribusi kota
- **Review Analysis**: rating per cabang, sentimen, ulasan terbaru

Lihat panduan di [`docs/metabase_setup.md`](docs/metabase_setup.md).

---

## Saran Pengembangan Selanjutnya

1. **Tambah data**: Hubungkan ke Odoo asli via XML-RPC (`etl/extract_odoo.py`)
2. **Tambah model dbt**: customer segmentation, product performance, cohort analysis
3. **Scheduling**: Tambah Airflow atau cron untuk pipeline otomatis
4. **Testing lebih lanjut**: Tambah dbt test `accepted_values`, `relationships`
5. **Dokumentasi dbt**: Jalankan `dbt docs generate && dbt docs serve`

---

## Catatan Keterbatasan PoC

- **Data sample**: hanya 50 transaksi, tidak representatif produksi
- **DuckDB single-user**: tidak bisa diakses bersamaan dari beberapa proses
- **Metabase via PostgreSQL**: Gold layer diekspor ke PG karena DuckDB tidak mendukung koneksi network
- **Tidak ada scheduling**: Pipeline dijalankan manual, bukan otomatis
- **Tidak ada autentikasi**: Environment ini hanya untuk demo lokal

---

## Dokumentasi

- [Arsitektur Data](docs/architecture.md)
- [Data Dictionary](docs/data_dictionary.md)
- [Panduan Deployment](docs/deployment.md)
- [Setup Metabase](docs/metabase_setup.md)
