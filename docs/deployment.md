# Panduan Deployment Lokal

## Prasyarat

Pastikan software berikut sudah terinstall:

| Software     | Versi Minimum | Cek                     |
|--------------|---------------|-------------------------|
| Docker       | 24.x          | `docker --version`      |
| Docker Compose| 2.x          | `docker compose version`|
| Git          | 2.x           | `git --version`         |

> **Catatan**: Tidak perlu install Python atau dbt di mesin host — semua berjalan di dalam container Docker.

---

## Langkah-langkah Deployment

### 1. Clone repository

```bash
git clone https://github.com/nanangyudi/Minilab-EduBI.git
cd Minilab-EduBI
```

### 2. Buat file konfigurasi `.env`

```bash
cp .env.example .env
```

Untuk PoC standar, nilai default sudah cukup. Edit `.env` jika perlu menyesuaikan password atau port.

### 3. Build Docker image

```bash
docker compose build
```

> Proses ini akan mengunduh base image Python dan menginstall semua dependency. Butuh beberapa menit pertama kali.

### 4. Jalankan PostgreSQL

```bash
docker compose up -d postgres
```

Tunggu hingga PostgreSQL siap (sekitar 10-15 detik). Cek status:

```bash
docker compose ps
# postgres harus menampilkan "healthy"
```

PostgreSQL akan otomatis menjalankan `scripts/init_postgres.sql` yang membuat schema `odoo_sim` dan `analytics` beserta sample data.

### 5. Jalankan ETL Pipeline

```bash
docker compose run --rm app
```

ETL akan:
- Menginisialisasi file DuckDB (`data/warehouse/lab_bi.duckdb`)
- Membuat schema `bronze`, `silver`, `gold` di DuckDB
- Memuat sample CSV ke tabel `bronze.*`

Output yang diharapkan:
```
[Step 1/3] Inisialisasi DuckDB...
[Step 2/3] Load CSV sample ke bronze...
  Loaded   50 baris → bronze.sales
  Loaded   20 baris → bronze.customers
  Loaded   30 baris → bronze.reviews
  Loaded   25 baris → bronze.targets
Pipeline ETL selesai.
```

### 6. Jalankan dbt

```bash
docker compose run --rm dbt
```

dbt akan:
- Membuat Bronze models (mirror dari sumber)
- Membuat Silver models (cleaned)
- Membuat Gold models (aggregated)
- Menjalankan test `not_null` dan `unique`
- Mengekspor Gold ke PostgreSQL schema `analytics`

Output yang diharapkan:
```
... dbt run selesai, 11 model berhasil.
... dbt test selesai, semua test passed.
... Export Gold → PostgreSQL analytics selesai.
```

### 7. Jalankan Metabase

```bash
docker compose up -d metabase
```

Buka browser: **http://localhost:3000**

Proses startup Metabase membutuhkan 1-2 menit. Lihat panduan setup Metabase di `docs/metabase_setup.md`.

---

## Perintah Berguna

```bash
# Lihat status semua service
docker compose ps

# Lihat log service tertentu
docker compose logs postgres
docker compose logs metabase

# Masuk ke container untuk debug
docker compose run --rm app bash
docker compose run --rm dbt bash

# Hentikan semua service
docker compose down

# Hapus semua data (reset penuh)
docker compose down -v
```

---

## Menjalankan Ulang Pipeline

Jika ingin menjalankan ulang ETL dan dbt (misal setelah mengubah data):

```bash
docker compose run --rm app    # ETL ulang
docker compose run --rm dbt    # dbt ulang + export ulang
```

---

## Struktur Port

| Service    | Port Host | Keterangan         |
|------------|-----------|--------------------|
| postgres   | 5432      | Koneksi DB langsung|
| metabase   | 3000      | Dashboard UI       |

---

## Troubleshooting

**ETL gagal: "koneksi DuckDB gagal"**
→ Pastikan volume `minilab_duckdb_data` terbentuk. Cek dengan `docker volume ls`.

**dbt gagal: "file DuckDB tidak ditemukan"**
→ Pastikan step ETL sudah berhasil terlebih dahulu. Volume harus sama.

**Metabase tidak bisa jalan**
→ Metabase butuh beberapa menit untuk startup. Cek log: `docker compose logs metabase`

**Port 5432 sudah dipakai**
→ Edit `docker-compose.yml`, ganti `"5432:5432"` menjadi `"5433:5432"`, lalu update `.env` dengan `PG_PORT=5433`.
