# Minilab EduBI

**Proof of Concept Business Intelligence** untuk mahasiswa Program Studi Sistem Informasi.
Mendemonstrasikan pipeline data end-to-end menggunakan stack modern yang ringan dan bisa dijalankan di laptop.

## Stack Teknologi

### Fase 1 — Business Intelligence Pipeline

| Komponen       | Tool              | Versi  |
|----------------|-------------------|--------|
| Data Warehouse | ClickHouse        | 24.3   |
| ETL            | Python + pandas   | 3.11   |
| Transformasi   | dbt Core          | 1.8.7  |
| Dashboard      | Metabase          | 0.59.4 |
| Source ERP     | PostgreSQL        | 15     |
| Runtime        | Docker Compose    | 2.x    |

### Fase 2 — Data Mining & Analitik Prediktif

| Komponen         | Tool                  | Versi   |
|------------------|-----------------------|---------|
| Notebook         | Jupyter Lab           | 4.x     |
| ML Framework     | scikit-learn          | 1.4+    |
| Frequent Pattern | mlxtend (FP-Growth)   | 0.23+   |
| Experiment Track | MLflow                | 2.14.3  |
| Visualisasi      | matplotlib / plotly   | 3.8+    |

## Arsitektur

Proyek ini menerapkan **Medallion Architecture** dengan **ClickHouse** sebagai Data Warehouse melalui **5 tahap pipeline eksplisit**:

```
TAHAP 1A  Extract Odoo      PostgreSQL odoo_sim → data/raw/odoo_*.csv
TAHAP 1B  Extract Reviews   Google Places API   → data/raw/google_reviews.csv
TAHAP 1C  File Manual       data/raw/sample_*.csv (siap dimuat)
    ↓
TAHAP 2   Load Bronze       data/raw/*.csv → ClickHouse bronze.*
    ↓
TAHAP 3   Transform Silver  dbt → ClickHouse silver.* (clean, typed)
    ↓
TAHAP 4   Transform Gold    dbt → ClickHouse gold.*   (agregasi KPI)
    ↓
TAHAP 5   Visualisasi       Metabase → connect ke ClickHouse gold
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
- **Fase 1**: Port 3000 (Metabase), 5432, 8123 tidak dipakai aplikasi lain
- **Fase 2**: Tambahan port 8888 (Jupyter), 5000 (MLflow) tidak dipakai aplikasi lain

---

### Opsi A — Satu Perintah (Otomatis)

Jalankan semua 5 tahap pipeline sekaligus:

```bash
git clone https://github.com/nanangyudi/Minilab-EduBI.git
cd Minilab-EduBI
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

## Fase 2 — Data Mining (branch: `fase2/data-mining`)

Fase 2 menambahkan kemampuan analitik prediktif di atas pipeline Fase 1.
Semua service berjalan dengan **Docker profile `analytics`**.

### Prasyarat Tambahan Fase 2

- Port 8888 (Jupyter) dan 5000 (MLflow) tidak dipakai aplikasi lain
- MLflow client dan server menggunakan versi yang sama (`2.14.3`) — **jangan upgrade salah satunya saja**
- Folder `experiments/` harus bisa ditulis oleh Docker (di Windows: pastikan drive di-share di Docker Desktop Settings → Resources → File Sharing)

### Menjalankan Fase 2

**1. Pindah ke branch Fase 2:**
```bash
git clone https://github.com/nanangyudi/Minilab-EduBI.git   # jika belum ada
cd Minilab-EduBI
git checkout fase2/data-mining
cp .env.example .env
```

**2. Build image:**
```bash
docker compose build jupyter
```

**3. Jalankan pipeline Fase 1 terlebih dahulu:**
```bash
docker compose up -d postgres clickhouse
docker compose run --rm app
docker compose run --rm dbt
```

**4. Jalankan service Fase 2:**
```bash
docker compose --profile analytics up -d
```

> **Windows**: Jika Jupyter tidak dapat menulis artifact MLflow, jalankan:
> ```powershell
> docker compose --profile analytics up -d jupyter --force-recreate
> ```

**5. Akses:**
- Jupyter Lab : http://localhost:8888 — token: `minilab`
- MLflow UI   : http://localhost:5000

**6. Mulai dari notebook verifikasi:**

Buka `notebooks/00_setup_verification.ipynb` dan jalankan semua cell dari atas ke bawah.
Jika semua cell hijau (tidak error), lanjutkan ke notebook berikutnya.

### Notebook yang Tersedia

| # | Notebook | Teknik | Sumber Data |
|---|----------|--------|-------------|
| 00 | `00_setup_verification.ipynb`     | Cek koneksi ClickHouse & MLflow | — |
| 01 | `01_clustering_customer_rfm.ipynb`| K-Means, RFM Segmentation       | `silver.silver_sales` |
| 02 | `02_classification_order_status.ipynb` | Random Forest, ROC-AUC     | `silver.silver_sales` |
| 03 | `03_regression_revenue_forecast.ipynb` | Linear/Ridge, TimeSeriesSplit | `gold.gold_sales_daily` |
| 04 | `04_association_market_basket.ipynb`   | FP-Growth, Association Rules  | `silver.silver_sales` |

Semua notebook (01–04) mencatat parameter, metrik, dan model ke MLflow secara otomatis.
Hasil eksperimen dapat dilihat di http://localhost:5000.

### Struktur Tambahan Fase 2

```
├── Dockerfile.jupyter          ← JupyterLab (scipy-notebook:python-3.11)
├── requirements-fase2.txt      ← scikit-learn, mlxtend, mlflow==2.14.3, plotly
├── experiments/                ← MLflow artifacts, model registry, SQLite DB
├── notebooks/
│   ├── utils.py                ← helper: get_ch_client(), read_sql(), mlflow_setup()
│   ├── 00_setup_verification.ipynb
│   ├── 01_clustering_customer_rfm.ipynb
│   ├── 02_classification_order_status.ipynb
│   ├── 03_regression_revenue_forecast.ipynb
│   └── 04_association_market_basket.ipynb
└── scripts/
    └── run_fase2.sh            ← shortcut CLI: start/stop/status/logs/pipeline
```

---

## Struktur Proyek

```
Minilab-EduBI/
│
├── README.md
├── requirements.txt
├── Dockerfile              ← image Python + dbt
├── Dockerfile.metabase     ← Metabase v0.59.4 (ClickHouse built-in)
├── docker-compose.yml      ← multi-fase: profiles bi (Metabase) & analytics (Jupyter, MLflow)
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
│   ├── utils.py                    ← helper koneksi (Fase 2)
│   ├── exploration.ipynb           ← eksplorasi via clickhouse-connect
│   ├── 00_setup_verification.ipynb ← cek koneksi service (Fase 2)
│   ├── 01_clustering_customer_rfm.ipynb
│   ├── 02_classification_order_status.ipynb
│   ├── 03_regression_revenue_forecast.ipynb
│   └── 04_association_market_basket.ipynb
│
├── experiments/                    ← MLflow artifacts (Fase 2)
│
└── docs/
    ├── architecture.md
    ├── data_dictionary.md
    ├── deployment.md
    └── metabase_setup.md
```

---

## Setup Metabase

Setelah `docker compose up -d metabase`, buka **http://localhost:3000** (tunggu ~2 menit).
Driver ClickHouse sudah **built-in** di Metabase v0.59.4 — tidak perlu plugin tambahan.

Tambah koneksi database baru:

| Field    | Nilai        |
|----------|--------------|
| Type     | ClickHouse   |
| Host     | `clickhouse` |
| Port     | `8123`       |
| Database | `gold`       |
| Username | `default`    |
| Password | *(kosong)*   |

Tabel yang tersedia di Gold layer:

| Tabel                  | Keterangan                              |
|------------------------|-----------------------------------------|
| `gold_sales_daily`     | Penjualan harian per cabang & kategori  |
| `gold_branch_kpi`      | KPI per cabang: revenue, target, rating |
| `gold_review_summary`  | Ringkasan sentimen ulasan per cabang    |

Lihat panduan di [`docs/metabase_setup.md`](docs/metabase_setup.md).

---

## Roadmap Fase

| Fase | Topik | Branch | Status |
|------|-------|--------|--------|
| 1 | BI Pipeline (ETL → dbt → Metabase) | `main` | ✅ Selesai |
| 2 | Data Mining (Jupyter, MLflow, scikit-learn) | `fase2/data-mining` | 🚧 Aktif — nb 00 & 01 ✅ |
| 3 | ML Deployment (FastAPI + MLflow serving) | `fase3/ml-deployment` | 📋 Planned |
| 4 | Realtime Pipeline (Kafka + Flink) | `fase4/realtime-pipeline` | 📋 Planned |

## Saran Pengembangan Selanjutnya

1. Hubungkan ke Odoo asli via XML-RPC (`etl/extract_odoo.py`)
2. Tambah model dbt: product performance, cohort analysis, customer segmentation
3. Tambah Airflow untuk scheduling pipeline otomatis
4. Tambah dbt test lebih lanjut: `accepted_values`, `relationships`
5. Jalankan `dbt docs generate && dbt docs serve` untuk dokumentasi model interaktif
6. Kembangkan Fase 2: tuning hyperparameter, cross-validation, model comparison
7. Fase 3: expose model terbaik sebagai REST API dengan FastAPI + MLflow serving

---

## Catatan Keterbatasan PoC

- Data sample kecil (50 transaksi), tidak representatif produksi
- Tidak ada scheduling — pipeline dijalankan manual
- ClickHouse default user (tanpa password) — hanya untuk demo lokal
- Tidak ada autentikasi Metabase multi-user
- MLflow menggunakan SQLite backend — tidak direkomendasikan untuk produksi (gunakan PostgreSQL)
- Fase 2 dijalankan sebagai `root` di dalam container untuk kemudahan setup lokal — tidak untuk produksi

---

## Dokumentasi

- [Arsitektur Data](docs/architecture.md)
- [Data Dictionary](docs/data_dictionary.md)
- [Panduan Deployment](docs/deployment.md)
- [Setup Metabase](docs/metabase_setup.md)
