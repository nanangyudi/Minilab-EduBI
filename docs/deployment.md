# Panduan Deployment Lokal

## Prasyarat

| Software      | Versi Minimum | Cek                      |
|---------------|---------------|--------------------------|
| Docker        | 24.x          | `docker --version`       |
| Docker Compose| 2.x           | `docker compose version` |
| Git           | 2.x           | `git --version`          |

> Python dan dbt **tidak perlu** diinstall di mesin host — semua berjalan di dalam container.

---

## Langkah Deployment

### 1. Clone repository

```bash
git clone https://github.com/nanangyudi/Minilab-EduBI.git
cd Minilab-EduBI
git checkout claude/connect-edubi-repo-Ybjvh
```

### 2. Buat file konfigurasi

```bash
cp .env.example .env
```

Nilai default di `.env` sudah cukup untuk PoC lokal.

### 3. Build Docker images

```bash
docker compose build
```

> Build pertama kali membutuhkan beberapa menit karena mengunduh ClickHouse driver untuk Metabase.

### 4. Jalankan PostgreSQL dan ClickHouse

```bash
docker compose up -d postgres clickhouse
```

Tunggu hingga keduanya healthy (~15-20 detik):

```bash
docker compose ps
# postgres   → healthy
# clickhouse → healthy
```

### 5. Jalankan ETL — TAHAP 1 + 2 (Extract & Load Bronze)

```bash
docker compose run --rm app
```

Output yang diharapkan:
```
====================================================
  Minilab EduBI — Data Pipeline
====================================================
┌─────────────────────────────────────────────┐
│  TAHAP 0 — Inisialisasi ClickHouse           │
└─────────────────────────────────────────────┘
  Database bronze siap.
  Database silver siap.
  Database gold siap.
┌─────────────────────────────────────────────┐
│  TAHAP 1A — Extract Odoo (PostgreSQL)        │
└─────────────────────────────────────────────┘
  10 customers → data/raw/odoo_customers.csv
  10 sales     → data/raw/odoo_sales.csv
┌─────────────────────────────────────────────┐
│  TAHAP 1B — Extract Google Reviews           │
└─────────────────────────────────────────────┘
  30 reviews ← sample_reviews.csv (fallback)
┌─────────────────────────────────────────────┐
│  TAHAP 1C — File Manual CSV/XLS              │
└─────────────────────────────────────────────┘
  ✓ sample_sales.csv    (50 baris)
  ✓ sample_targets.csv  (25 baris)
┌─────────────────────────────────────────────┐
│  TAHAP 2 — Load ke Bronze (ClickHouse)       │
└─────────────────────────────────────────────┘
  10 baris → bronze.customers  ← [extracted] odoo_customers.csv
  10 baris → bronze.sales      ← [extracted] odoo_sales.csv
  30 baris → bronze.reviews    ← [sample]    sample_reviews.csv
  25 baris → bronze.targets    ← [sample]    sample_targets.csv
```

> Jika koneksi PostgreSQL gagal, ETL otomatis fallback ke `sample_customers.csv`
> dan `sample_sales.csv`.

### 6. Jalankan dbt — TAHAP 3 + 4 (Transform Silver & Gold)

```bash
docker compose run --rm dbt
```

Output yang diharapkan:
```
┌─────────────────────────────────────────────┐
│  TAHAP 3 — Transform ke Silver (ClickHouse)  │
└─────────────────────────────────────────────┘
  silver_sales       OK
  silver_customers   OK
  silver_reviews     OK
  silver_targets     OK
┌─────────────────────────────────────────────┐
│  TAHAP 4 — Transform ke Gold (ClickHouse)    │
└─────────────────────────────────────────────┘
  gold_sales_daily     OK
  gold_branch_kpi      OK
  gold_review_summary  OK
┌─────────────────────────────────────────────┐
│  Validasi dbt Tests                          │
└─────────────────────────────────────────────┘
  Passed: 14 tests
```

### 7. Jalankan Metabase

```bash
docker compose up -d metabase
```

Buka **http://localhost:3000** (tunggu 1-2 menit startup).

---

## Menjalankan Pipeline Lengkap (Satu Perintah)

Alternatif otomatis yang menjalankan seluruh 5 tahap sekaligus:

```bash
bash scripts/run_pipeline_full.sh
```

Skrip ini secara berurutan:
1. Menjalankan `docker compose up -d postgres clickhouse` (tunggu healthy)
2. Menjalankan `docker compose run --rm app` (TAHAP 1+2: Extract + Load Bronze)
3. Menjalankan `docker compose run --rm dbt` (TAHAP 3+4: Silver + Gold)
4. Menjalankan `docker compose up -d metabase` (TAHAP 5: Visualisasi)
5. Menampilkan instruksi konfigurasi Metabase

> Cocok untuk demo cepat atau reset ulang lingkungan pengembangan.

---

## Perintah Berguna

```bash
# Status semua service
docker compose ps

# Log service tertentu
docker compose logs clickhouse
docker compose logs metabase

# Masuk ke container untuk debug
docker compose run --rm app bash

# Hentikan semua service
docker compose down

# Reset penuh (hapus semua data)
docker compose down -v
```

---

## Menjalankan Ulang Pipeline

```bash
# Jalankan ulang per tahap
docker compose run --rm app   # TAHAP 1+2: Extract + Load Bronze
docker compose run --rm dbt   # TAHAP 3+4: Transform Silver + Gold

# Atau jalankan semua sekaligus
bash scripts/run_pipeline_full.sh
```

---

## Struktur Port

| Service     | Port Host | Keterangan            |
|-------------|-----------|-----------------------|
| postgres    | 5432      | Koneksi PostgreSQL    |
| clickhouse  | 8123      | HTTP interface        |
| clickhouse  | 9000      | Native interface      |
| metabase    | 3000      | Dashboard UI          |

---

## Troubleshooting

**ClickHouse tidak healthy**
→ Cek log: `docker compose logs clickhouse`
→ Pastikan port 8123 dan 9000 tidak dipakai.

**ETL gagal: koneksi ClickHouse**
→ Pastikan `docker compose up -d clickhouse` sudah berjalan dan healthy dulu.

**dbt gagal: "database bronze tidak ditemukan"**
→ Pastikan ETL sudah berhasil (Step 5) sebelum menjalankan dbt.

**Metabase tidak muncul di localhost:3000**
→ Metabase butuh 1-2 menit startup. Cek: `docker compose logs metabase`

**Port sudah dipakai**
→ Edit `docker-compose.yml`, ubah port mapping (misal `"8124:8123"`), lalu update `.env`.
