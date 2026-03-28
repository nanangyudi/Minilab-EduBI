# Minilab EduBI

**Proof of Concept Business Intelligence** untuk mahasiswa Program Studi Sistem Informasi.
Mendemonstrasikan pipeline data end-to-end menggunakan stack modern yang ringan dan bisa dijalankan di laptop.

## Stack Teknologi

| Komponen       | Tool              | Versi  |
|----------------|-------------------|--------|
| Data Warehouse | ClickHouse        | 24.3   |
| ETL            | Python + pandas   | 3.11   |
| Transformasi   | dbt Core          | 1.8.7  |
| Dashboard      | Metabase          | 0.50   |
| Source ERP     | PostgreSQL        | 15     |
| Runtime        | Docker Compose    | 2.x    |

## Arsitektur

Proyek ini menerapkan **Medallion Architecture** dengan **ClickHouse** sebagai Data Warehouse:

```
CSV / PostgreSQL(odoo_sim) → ETL Python → ClickHouse Bronze
                                        → dbt → ClickHouse Silver
                                        → dbt → ClickHouse Gold
                                        → Metabase (connect langsung ke ClickHouse)
```

| Layer  | Database ClickHouse | Keterangan                          |
|--------|---------------------|-------------------------------------|
| Bronze | `bronze`            | Raw data, semua kolom String        |
| Silver | `silver`            | Data bersih, tipe & validasi benar  |
| Gold   | `gold`              | Agregasi siap dashboard             |

**Catatan**: PostgreSQL hanya digunakan sebagai simulasi sumber ERP (Odoo) dan metadata Metabase. Data Warehouse sesungguhnya ada di ClickHouse.

Lihat detail di [`docs/architecture.md`](docs/architecture.md).

## Domain Bisnis

**Sales & Customer Insight** — toko elektronik multi-cabang:
- 50 transaksi penjualan (sample)
- 20 customer
- 30 ulasan Google
- Target penjualan bulanan per cabang

Cabang: Pusat, Bandung, Surabaya, Selatan, Yogyakarta.

---

## Cara Menjalankan (Docker)

### Prasyarat
- Docker Desktop terinstall dan berjalan
- Port 3000, 5432, 8123 tidak dipakai aplikasi lain

---

### Opsi A — Satu Perintah (Otomatis)

Jalankan semua 5 tahap pipeline sekaligus:

```bash
git clone https://github.com/nanangyudi/Minilab-EduBI.git
cd Minilab-EduBI
git checkout claude/connect-edubi-repo-Ybjvh
cp .env.example .env
docker compose build
bash scripts/run_pipeline_full.sh
```

Skrip akan menjalankan seluruh pipeline secara otomatis:
infrastructure → Extract → Load Bronze → Transform Silver → Transform Gold → Metabase.

---

### Opsi B — Langkah Manual (Direkomendasikan untuk Belajar)

Jalankan setiap tahap secara terpisah agar proses lebih mudah dipahami.

```bash
# 1. Clone repository
git clone https://github.com/nanangyudi/Minilab-EduBI.git
cd Minilab-EduBI
git checkout claude/connect-edubi-repo-Ybjvh

# 2. Salin konfigurasi
cp .env.example .env

# 3. Build image
docker compose build

# 4. Jalankan infrastructure
docker compose up -d postgres clickhouse
# Tunggu ~15 detik hingga keduanya healthy

# 5. TAHAP 1 + 2 — Extract & Load Bronze
docker compose run --rm app
# → TAHAP 1A: Extract dari Odoo (PostgreSQL odoo_sim)
# → TAHAP 1B: Extract Google Reviews (atau fallback sample)
# → TAHAP 1C: File manual CSV siap di data/raw/
# → TAHAP 2 : Load semua CSV ke ClickHouse bronze.*

# 6. TAHAP 3 + 4 — Transform Silver & Gold
docker compose run --rm dbt
# → TAHAP 3: dbt transform → silver (clean, typed)
# → TAHAP 4: dbt transform → gold  (agregasi KPI)
# → Validasi: dbt test

# 7. TAHAP 5 — Visualisasi Metabase
docker compose up -d metabase
# Buka http://localhost:3000 (tunggu ~2 menit)
```

Lihat panduan lengkap di [`docs/deployment.md`](docs/deployment.md).

---

## Struktur Proyek

```
Minilab-EduBI/
│
├── README.md
├── requirements.txt
├── Dockerfile              ← image Python + dbt
├── Dockerfile.metabase     ← Metabase + ClickHouse driver
├── docker-compose.yml      ← 5 service: postgres, clickhouse, app, dbt, metabase
├── .env.example
├── .gitignore
│
├── data/
│   ├── raw/
│   │   ├── sample_sales.csv        ← 50 transaksi
│   │   ├── sample_customers.csv    ← 20 customer
│   │   ├── sample_reviews.csv      ← 30 ulasan
│   │   └── sample_targets.csv      ← target bulanan
│   └── processed/
│
├── etl/
│   ├── utils.py              ← koneksi ClickHouse & PostgreSQL
│   ├── init_clickhouse.py    ← buat database bronze/silver/gold
│   ├── load_csv.py           ← load CSV → ClickHouse bronze
│   ├── extract_odoo.py       ← extract dari PG odoo_sim (opsional)
│   ├── extract_google_reviews.py
│   └── run_pipeline.py       ← orchestrator ETL
│
├── dbt_project/
│   ├── dbt_project.yml
│   ├── profiles.yml.example
│   ├── packages.yml
│   ├── macros/
│   │   └── generate_schema_name.sql
│   └── models/
│       ├── sources.yml
│       ├── schema.yml          ← tests not_null & unique
│       ├── bronze/             ← 4 model (mirror dari ClickHouse bronze)
│       ├── silver/             ← 4 model (cleaned, ClickHouse SQL)
│       └── gold/               ← 3 model (aggregated, ClickHouse SQL)
│
├── scripts/
│   ├── init_postgres.sql       ← seed data odoo_sim
│   ├── run_etl.sh              ← jalankan ETL (TAHAP 1+2)
│   ├── run_dbt.sh              ← jalankan dbt (TAHAP 3+4)
│   └── run_pipeline_full.sh    ← jalankan semua 5 tahap sekaligus
│
├── notebooks/
│   └── exploration.ipynb     ← eksplorasi via clickhouse-connect
│
└── docs/
    ├── architecture.md
    ├── data_dictionary.md
    ├── deployment.md
    └── metabase_setup.md
```

---

## Setup Metabase

Setelah pipeline selesai, tambah database di Metabase:

| Field    | Nilai        |
|----------|--------------|
| Type     | ClickHouse   |
| Host     | `clickhouse` |
| Port     | `8123`       |
| Database | `gold`       |
| Username | `default`    |
| Password | *(kosong)*   |

Tabel yang tersedia: `gold_sales_daily`, `gold_branch_kpi`, `gold_review_summary`.

Lihat panduan di [`docs/metabase_setup.md`](docs/metabase_setup.md).

---

## Saran Pengembangan Selanjutnya

1. Hubungkan ke Odoo asli via XML-RPC (`etl/extract_odoo.py`)
2. Tambah model dbt: product performance, cohort analysis, customer segmentation
3. Tambah Airflow untuk scheduling pipeline otomatis
4. Tambah dbt test lebih lanjut: `accepted_values`, `relationships`
5. Jalankan `dbt docs generate && dbt docs serve` untuk dokumentasi model interaktif

---

## Catatan Keterbatasan PoC

- Data sample kecil (50 transaksi), tidak representatif produksi
- Tidak ada scheduling — pipeline dijalankan manual
- ClickHouse default user (tanpa password) — hanya untuk demo lokal
- Tidak ada autentikasi Metabase multi-user

---

## Dokumentasi

- [Arsitektur Data](docs/architecture.md)
- [Data Dictionary](docs/data_dictionary.md)
- [Panduan Deployment](docs/deployment.md)
- [Setup Metabase](docs/metabase_setup.md)
