# Minilab EduBI — Olist Brazilian E-Commerce

**Branch: `fase2/olist-ecommerce`**

Studi kasus adaptasi pipeline Minilab EduBI untuk dataset publik
[Olist Brazilian E-Commerce](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) dari Kaggle.
Dataset ini memiliki ~100.000 pesanan, 8 file CSV relasional, dan mencakup metrik pengiriman
yang tidak ada di dataset toko elektronik standard.

---

## Perbandingan: Toko Elektronik vs Olist

| Aspek | Toko Elektronik (`fase2/data-mining`) | Olist (`fase2/olist-ecommerce`) |
|-------|--------------------------------------|--------------------------------|
| Sumber data | PostgreSQL + CSV manual | 8 CSV dari Kaggle |
| Granularitas | 1 order = 1 produk | 1 order = banyak item |
| Customer ID | Tetap per customer | `customer_unique_id` (customer_id berubah tiap order) |
| Dimensi geografis | Branch (cabang fisik) | `seller_state` (negara bagian penjual) |
| Status order | done / cancelled | delivered→done, canceled→cancelled |
| Ulasan | Google Reviews (terpisah) | Terintegrasi di `order_reviews` |
| Metrik pengiriman | Tidak ada | delivery_days, is_delayed |
| Skala | 200 transaksi | ~100.000 transaksi |
| Target penjualan | Ada (per cabang/bulan) | Tidak ada |

---

## Stack Teknologi

Sama dengan branch `fase2/data-mining` — tidak ada perubahan stack.

| Komponen       | Tool              | Versi  |
|----------------|-------------------|--------|
| Data Warehouse | ClickHouse        | 24.3   |
| ETL            | Python + pandas   | 3.11   |
| Transformasi   | dbt Core          | 1.8.7  |
| Dashboard      | Metabase          | 0.59.4 |
| Runtime        | Docker Compose    | 2.x    |
| Notebook       | Jupyter Lab       | 4.x    |
| ML Framework   | scikit-learn      | 1.4+   |
| Experiment Track | MLflow          | 2.14.3 |

---

## Cara Menjalankan

### Prasyarat

1. Docker Desktop terinstall dan berjalan
2. Download dataset Olist dari Kaggle → ekstrak ke `data/raw/olist/`:
   ```
   data/raw/olist/
   ├── olist_orders_dataset.csv
   ├── olist_order_items_dataset.csv
   ├── olist_order_payments_dataset.csv
   ├── olist_order_reviews_dataset.csv
   ├── olist_customers_dataset.csv
   ├── olist_sellers_dataset.csv
   ├── olist_products_dataset.csv
   └── product_category_name_translation.csv
   ```

### Langkah Manual (Direkomendasikan untuk Belajar)

```bash
# 1. Clone repository dan pindah ke branch ini
git clone https://github.com/nanangyudi/Minilab-EduBI.git
cd Minilab-EduBI
git checkout fase2/olist-ecommerce

# 2. Salin konfigurasi
cp .env.example .env
# DATASET=olist sudah diset sebagai default di docker-compose.yml

# 3. Build image
docker compose build

# 4. Jalankan infrastructure
docker compose up -d clickhouse
# Tunggu ~10 detik hingga healthy

# 5. TAHAP 2 — Load Olist Bronze
docker compose run --rm app
# → Inisialisasi database bronze/silver/gold di ClickHouse
# → Load 8 file CSV Olist ke bronze.olist_* (pastikan file sudah ada di data/raw/olist/)

# 6. TAHAP 3 + 4 — Transform Silver & Gold
docker compose run --rm dbt
# → Bronze Olist mirror models
# → Silver: JOIN 6 tabel → silver.silver_sales (dengan delivery_days, is_delayed)
# → Silver: silver_reviews (dari order_reviews)
# → Silver: silver_customers (deduplikasi via customer_unique_id)
# → Gold: gold_sales_daily (per seller_state)
# → Gold: gold_seller_kpi (KPI per seller_state)
# → Gold: gold_delivery_kpi (metrik pengiriman per seller_state × kategori)
# → Gold: gold_review_summary (ulasan per customer_state)
# → Validasi: dbt test

# 7. TAHAP 5 — Visualisasi Metabase (opsional)
docker compose --profile bi up -d metabase
# Buka http://localhost:3000 (tunggu ~2 menit)
```

### Catatan: PostgreSQL Tidak Diperlukan

Berbeda dari dataset toko elektronik, pipeline Olist tidak memerlukan PostgreSQL
(tidak ada ekstrak dari Odoo ERP). Anda bisa skip `docker compose up -d postgres`
kecuali jika menggunakan Metabase (Metabase menyimpan metadata-nya di PostgreSQL).

---

## Arsitektur Pipeline Olist

```
data/raw/olist/*.csv  (8 file, download manual dari Kaggle)
    ↓
TAHAP 2   Load Bronze    CSV → ClickHouse bronze.olist_*  (all-String, raw)
    ↓
TAHAP 3   Silver (dbt)   JOIN 6 tabel → silver.silver_sales
                          delivery_days, is_delayed, customer_unique_id
    ↓
TAHAP 4   Gold (dbt)     silver.silver_sales → gold.*
                          gold_sales_daily, gold_seller_kpi,
                          gold_delivery_kpi, gold_review_summary
    ↓
TAHAP 5   Metabase        Koneksi ke ClickHouse gold.*
```

---

## Tabel Gold yang Tersedia

| Tabel | Keterangan | Dimensi Utama |
|-------|-----------|---------------|
| `gold_sales_daily` | Penjualan harian + metrik pengiriman | seller_state, order_date |
| `gold_seller_kpi` | KPI per negara bagian penjual | seller_state |
| `gold_delivery_kpi` | Ketepatan pengiriman per seller_state × kategori | seller_state, category |
| `gold_review_summary` | Ringkasan ulasan per negara bagian pembeli | customer_state (branch) |

### Setup Metabase

| Field    | Nilai        |
|----------|--------------|
| Type     | ClickHouse   |
| Host     | `clickhouse` |
| Port     | `8123`       |
| Database | `gold`       |
| Username | `default`    |
| Password | *(kosong)*   |

---

## Perubahan Kunci vs Branch Standard

### ETL (Python)
- `etl/run_pipeline.py`: Deteksi `DATASET=olist` → panggil `load_olist.load_all()`, skip Extract Odoo/Reviews
- `etl/load_olist.py`: Loader baru — DDL 8 tabel Bronze, `TRUNCATE + INSERT` dari CSV

### dbt Models
- **Bronze** (8 file baru): Mirror dari `bronze.olist_*` ke dbt models
- **silver_sales**: JOIN 6 tabel, tambah `seller_state`, `delivery_days`, `is_delayed`
- **silver_reviews**: Dari `olist_order_reviews`, dimensi = `customer_state`
- **silver_customers**: Deduplikasi `customer_unique_id` via GROUP BY
- **silver_targets**: Stub kosong (Olist tidak punya data target)
- **gold_sales_daily**: `seller_state` menggantikan `branch`
- **gold_seller_kpi**: KPI per seller_state (pengganti `gold_branch_kpi`)
- **gold_delivery_kpi**: Model baru — metrik pengiriman per seller_state × kategori
- **gold_branch_kpi**: Stub kosong (gunakan `gold_seller_kpi`)

---

## Adaptasi Notebook Data Mining

Notebook `01`–`04` di branch ini masih menggunakan skema toko elektronik standard.
Berikut penyesuaian yang diperlukan untuk analisis Olist:

### NB 01 — Clustering RFM
```python
# Ganti query dari:
SELECT customer_id, order_date, total_price FROM silver.silver_sales WHERE status='done'

# Menjadi (Olist):
SELECT customer_id, order_date, total_price
FROM silver.silver_sales
WHERE status='done' AND customer_id != ''
-- customer_id = customer_unique_id (sudah deduplikasi di silver_sales)
```
Dataset Olist (~100k orders, ~96k unique customers) memberikan clustering yang lebih representatif.

### NB 02 — Klasifikasi
```python
# Target baru: prediksi is_delayed (bukan status done/cancelled)
# Karena cancelled di Olist hanya ~1% — class imbalance sangat ekstrem

# Query Olist:
SELECT seller_state, category, unit_price, freight_value,
       delivery_days, is_delayed
FROM silver.silver_sales
WHERE status='done' AND is_delayed IS NOT NULL
```
Fitur yang relevan: `freight_value`, `seller_state`, `category`, `unit_price`.

### NB 03 — Regresi
```python
# Target baru: prediksi delivery_days (waktu pengiriman)
# Atau: forecasting revenue harian dari gold_sales_daily

# Query Olist:
SELECT order_date, seller_state, avg_delivery_days, total_revenue
FROM gold.gold_sales_daily ORDER BY order_date
```

### NB 04 — Association Rules (Keunggulan Utama Olist)
```python
# Olist adalah dataset IDEAL untuk Market Basket Analysis!
# Karena 1 order bisa punya BANYAK item → basket per order_id natural

# Query Olist:
SELECT order_id, category
FROM silver.silver_sales
WHERE status='done' AND category != 'unknown'

# Basket = order_id (bukan customer_id seperti di Minilab standard)
# Item   = category (sudah tersedia, tidak perlu derive product_type)

basket = df.groupby('order_id')['category'].apply(list)
MIN_SUPPORT = 0.01  # Bisa lebih rendah karena 100k+ order
```
Dengan 100k+ order, rules yang terbentuk jauh lebih kaya dan representatif.

---

## Pertanyaan Diskusi

1. Mengapa Olist menggunakan `customer_unique_id` untuk analisis RFM, bukan `customer_id`?
2. Pada Olist, mengapa basket per `order_id` lebih natural daripada per `customer_id`?
3. Apa artinya `is_delayed = 1`? Metrik bisnis apa yang bisa dibangun dari ini?
4. Mengapa `seller_state` menjadi dimensi geografis di Olist, berbeda dari `branch` di toko elektronik?
5. Jika ingin menghubungkan ulasan (review_score) dengan performa pengiriman, JOIN apa yang diperlukan?

---

## Struktur Proyek (Perubahan dari Branch Standard)

```
Minilab-EduBI/
├── data/
│   └── raw/
│       └── olist/                         ← Download dari Kaggle (tidak di-commit)
│           ├── README.md                  ← Petunjuk download
│           ├── olist_orders_dataset.csv
│           ├── olist_order_items_dataset.csv
│           └── ...
│
├── etl/
│   ├── load_olist.py                      ← Loader baru untuk 8 tabel Olist
│   └── run_pipeline.py                    ← Ditambah DATASET=olist mode
│
└── dbt_project/
    └── models/
        ├── sources.yml                    ← Ditambah 8 sumber Olist
        ├── schema.yml                     ← Disesuaikan untuk model Olist
        ├── bronze/
        │   ├── bronze_olist_orders.sql    ← 8 file baru (mirror Olist Bronze)
        │   ├── bronze_olist_order_items.sql
        │   ├── bronze_olist_order_payments.sql
        │   ├── bronze_olist_order_reviews.sql
        │   ├── bronze_olist_customers.sql
        │   ├── bronze_olist_sellers.sql
        │   ├── bronze_olist_products.sql
        │   └── bronze_olist_category_translation.sql
        ├── silver/
        │   ├── silver_sales.sql           ← Olist: JOIN 6 tabel, delivery metrics
        │   ├── silver_reviews.sql         ← Olist: dari order_reviews
        │   ├── silver_customers.sql       ← Olist: deduplikasi customer_unique_id
        │   └── silver_targets.sql         ← Stub kosong (tidak berlaku untuk Olist)
        └── gold/
            ├── gold_sales_daily.sql       ← Olist: seller_state sebagai dimensi
            ├── gold_seller_kpi.sql        ← Baru: KPI per seller_state
            ├── gold_delivery_kpi.sql      ← Baru: metrik pengiriman
            ├── gold_review_summary.sql    ← Olist: ulasan per customer_state
            └── gold_branch_kpi.sql        ← Stub kosong (gunakan gold_seller_kpi)
```

---

## Roadmap Fase

| Fase | Topik | Branch | Status |
|------|-------|--------|--------|
| 1 | BI Pipeline (ETL → dbt → Metabase) | `main` | ✅ Selesai |
| 2a | Data Mining — Toko Elektronik | `fase2/data-mining` | ✅ Selesai |
| 2b | Olist E-Commerce Scaffold | `fase2/olist-ecommerce` | ✅ Pipeline siap |
| 3 | ML Deployment (FastAPI + MLflow serving) | `fase3/ml-deployment` | 📋 Planned |
| 4 | Realtime Pipeline (Kafka + Flink) | `fase4/realtime-pipeline` | 📋 Planned |

---

## Dokumentasi

- [Arsitektur Data](docs/architecture.md)
- [Panduan Download Olist](data/raw/olist/README.md)
- [Panduan Deployment](docs/deployment.md)
- [Setup Metabase](docs/metabase_setup.md)
