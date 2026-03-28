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

### 5. Jalankan ETL

```bash
docker compose run --rm app
```

Output yang diharapkan:
```
[Step 1/3] Inisialisasi ClickHouse...
  Database 'bronze' siap.
  Database 'silver' siap.
  Database 'gold' siap.
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

Output yang diharapkan:
```
... dbt run: 11 of 11 OK
... dbt test: passed
```

### 7. Jalankan Metabase

```bash
docker compose up -d metabase
```

Buka **http://localhost:3000** (tunggu 1-2 menit startup).

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
docker compose run --rm app   # ETL ulang
docker compose run --rm dbt   # dbt ulang
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
