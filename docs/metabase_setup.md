# Panduan Setup Metabase

## Cara Kerja Metabase di Minilab EduBI

Metabase **tidak** terhubung langsung ke DuckDB (DuckDB tidak mendukung koneksi network).
Sebagai gantinya, hasil **Gold layer** diekspor ke PostgreSQL schema `analytics`, dan Metabase membaca dari sana.

```
DuckDB gold.* → export_gold_to_postgres.py → PG analytics.* → Metabase
```

---

## Langkah Setup Awal

### 1. Buka Metabase

Buka browser dan akses: **http://localhost:3000**

Tunggu loading (1-2 menit pertama kali). Jika belum muncul, cek log:
```bash
docker compose logs metabase
```

### 2. Buat akun admin

Isi form pendaftaran:
- Nama lengkap
- Email (bebas, untuk login lokal)
- Password

Klik **Next**.

### 3. Tambah database

Pada halaman "Add your data", pilih:
- **Database type**: PostgreSQL
- Isi koneksi:

| Field         | Nilai                     |
|---------------|---------------------------|
| Display name  | `Minilab Analytics`       |
| Host          | `postgres`                |
| Port          | `5432`                    |
| Database name | `minilab`                 |
| Username      | `minilab`                 |
| Password      | `minilab123`              |
| Schema        | `analytics`               |

> **Penting**: Hostname adalah `postgres` (nama service Docker), bukan `localhost`.

Klik **Save** → **Finish**.

### 4. Verifikasi tabel tersedia

Pergi ke **Browse Data** → pilih database `Minilab Analytics`.

Tabel yang tersedia di schema `analytics`:
- `gold_sales_daily` — data penjualan harian per cabang
- `gold_branch_kpi` — KPI ringkasan per cabang
- `gold_review_summary` — ringkasan ulasan per cabang

---

## Membuat Dashboard Demo

### Contoh Question 1: Total Revenue per Cabang

1. Klik **+ New** → **Question**
2. Pilih database `Minilab Analytics` → tabel `gold_branch_kpi`
3. Klik **Visualize**
4. Pilih chart type: **Bar Chart**
5. X-axis: `branch`, Y-axis: `total_revenue`
6. Simpan dengan nama "Revenue per Cabang"

### Contoh Question 2: Tren Penjualan Harian

1. **+ New** → **Question** → `gold_sales_daily`
2. Group by: `order_date`
3. Metric: Sum of `total_revenue`
4. Chart type: **Line Chart**
5. Simpan: "Tren Revenue Harian"

### Contoh Question 3: Rating per Cabang

1. **+ New** → **Question** → `gold_review_summary`
2. Show: `branch`, `avg_rating`, `total_reviews`
3. Chart type: **Table** atau **Bar Chart**
4. Simpan: "Rating Ulasan per Cabang"

### Membuat Dashboard

1. Klik **+ New** → **Dashboard**
2. Beri nama: "Minilab EduBI — Sales Dashboard"
3. Klik **Add a question** → pilih question yang sudah dibuat
4. Atur layout drag-and-drop
5. Klik **Save**

---

## Refresh Data

Setiap kali pipeline dijalankan ulang (`docker compose run app` + `docker compose run dbt`), data di PostgreSQL analytics akan diperbarui otomatis oleh `export_gold_to_postgres.py`.

Untuk menyegarkan tampilan di Metabase:
- Klik ikon refresh pada question/dashboard
- Atau tunggu cache Metabase expired (default 24 jam)

---

## Screenshot Panduan

> Lampirkan screenshot hasil dashboard pada laporan praktikum Anda.
