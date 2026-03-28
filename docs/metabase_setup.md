# Panduan Setup Metabase

## Koneksi Langsung ke ClickHouse

Berbeda dengan arsitektur sebelumnya, Metabase sekarang **terhubung langsung ke ClickHouse** (Data Warehouse). Tidak ada langkah export tambahan — data Gold di ClickHouse langsung tersedia.

```
ClickHouse gold.* → Metabase (connect langsung via port 8123)
```

---

## Langkah Setup Awal

### 1. Buka Metabase

Buka browser: **http://localhost:3000**

Tunggu loading 1-2 menit. Jika belum muncul:
```bash
docker compose logs metabase
```

### 2. Buat akun admin

Isi form pendaftaran (nama, email, password). Klik **Next**.

### 3. Tambah koneksi ClickHouse

Pada halaman "Add your data", pilih **ClickHouse** dari daftar database.

| Field         | Nilai        |
|---------------|--------------|
| Display name  | `Minilab DW` |
| Host          | `clickhouse` |
| Port          | `8123`       |
| Database name | `gold`       |
| Username      | `default`    |
| Password      | *(kosong)*   |

> **Penting**: Host adalah `clickhouse` (nama service Docker), bukan `localhost`.
> Koneksi ke database `gold` langsung — tabel sudah siap digunakan.

Klik **Save** → **Finish**.

---

## Verifikasi Tabel Tersedia

Pergi ke **Browse Data** → pilih database `Minilab DW`.

Tabel yang tersedia:
| Tabel | Isi |
|---|---|
| `gold_sales_daily` | Revenue & orders harian per cabang |
| `gold_branch_kpi` | KPI ringkasan per cabang |
| `gold_review_summary` | Rating & sentimen per cabang |

---

## Membuat Dashboard Demo

### Question 1: Revenue per Cabang

1. **+ New** → **Question** → `Minilab DW` → `gold_branch_kpi`
2. Klik **Visualize**
3. Pilih **Bar Chart** — X: `branch`, Y: `total_revenue`
4. Simpan: *"Revenue per Cabang"*

### Question 2: Tren Penjualan Harian

1. **+ New** → **Question** → `gold_sales_daily`
2. Summarize: Sum of `total_revenue`, Group by `order_date`
3. Chart type: **Line Chart**
4. Simpan: *"Tren Revenue Harian"*

### Question 3: Rating & Sentimen per Cabang

1. **+ New** → **Question** → `gold_review_summary`
2. Tampilkan: `branch`, `avg_rating`, `pct_positif`, `total_reviews`
3. Chart type: **Table** atau **Bar Chart**
4. Simpan: *"Rating Ulasan per Cabang"*

### Question 4: Pencapaian Target

1. **+ New** → **Question** → `gold_branch_kpi`
2. Tampilkan: `branch`, `total_revenue`, `total_sales_target`, `revenue_achievement_pct`
3. Chart type: **Table**
4. Simpan: *"Pencapaian Target per Cabang"*

### Buat Dashboard

1. **+ New** → **Dashboard** → nama: *"Minilab EduBI — Sales Dashboard"*
2. Klik **Add a question** → pilih 4 question di atas
3. Atur layout dengan drag-and-drop
4. Klik **Save**

---

## Menambah Database Bronze/Silver (opsional)

Untuk eksplorasi tambahan, bisa tambah koneksi ke database lain di ClickHouse:
- Database `silver` → untuk melihat data yang sudah dibersihkan
- Database `bronze` → untuk melihat data mentah

Prosedurnya sama, cukup ubah **Database name** saat setup koneksi.

---

## Refresh Data

Setelah menjalankan ulang pipeline:
```bash
docker compose run --rm app   # ETL ulang
docker compose run --rm dbt   # dbt ulang
```

Data di ClickHouse langsung terupdate. Klik ikon refresh di Metabase untuk menyegarkan tampilan.
