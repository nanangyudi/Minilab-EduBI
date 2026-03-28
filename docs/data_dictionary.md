# Data Dictionary — Minilab EduBI

## Bronze Layer

### bronze.sales
Raw data transaksi penjualan dari CSV / Odoo simulation.

| Kolom        | Tipe    | Contoh              | Keterangan                      |
|--------------|---------|---------------------|---------------------------------|
| order_id     | VARCHAR | SO001               | ID unik transaksi               |
| customer_id  | VARCHAR | C001                | Referensi ke tabel customers    |
| product_name | VARCHAR | Laptop Acer Aspire 5| Nama produk                     |
| category     | VARCHAR | Elektronik          | Kategori produk                 |
| quantity     | INTEGER | 1                   | Jumlah unit                     |
| unit_price   | DOUBLE  | 7500000             | Harga per unit (Rp)             |
| total_price  | DOUBLE  | 7500000             | Total harga (Rp)                |
| order_date   | VARCHAR | 2024-01-05          | Tanggal order (string)          |
| branch       | VARCHAR | Pusat               | Nama cabang                     |
| status       | VARCHAR | done                | Status order                    |

### bronze.customers
Raw data master customer.

| Kolom          | Tipe    | Contoh             | Keterangan                   |
|----------------|---------|--------------------|------------------------------|
| customer_id    | VARCHAR | C001               | ID unik customer             |
| name           | VARCHAR | Andi Saputra       | Nama lengkap                 |
| email          | VARCHAR | andi@email.com     | Alamat email                 |
| phone          | VARCHAR | 081234567001       | Nomor telepon                |
| city           | VARCHAR | Jakarta            | Kota domisili                |
| branch         | VARCHAR | Pusat              | Cabang terkait customer      |
| customer_since | VARCHAR | 2021-03-15         | Tanggal pertama menjadi member|

### bronze.reviews
Raw data ulasan dari Google Reviews.

| Kolom       | Tipe    | Contoh          | Keterangan                  |
|-------------|---------|-----------------|------------------------------|
| review_id   | VARCHAR | R001            | ID unik review               |
| author      | VARCHAR | Andi Saputra    | Nama penulis review          |
| rating      | INTEGER | 5               | Rating bintang (1–5)         |
| text        | VARCHAR | Pelayanan...    | Isi teks ulasan              |
| review_date | VARCHAR | 2024-01-08      | Tanggal review               |
| branch      | VARCHAR | Pusat           | Cabang yang direview         |
| source      | VARCHAR | google          | Platform sumber              |

### bronze.targets
Raw data target penjualan bulanan.

| Kolom        | Tipe    | Contoh   | Keterangan                    |
|--------------|---------|----------|-------------------------------|
| target_id    | VARCHAR | T001     | ID unik target                |
| branch       | VARCHAR | Pusat    | Nama cabang                   |
| month        | INTEGER | 1        | Bulan (1–12)                  |
| year         | INTEGER | 2024     | Tahun                         |
| sales_target | DOUBLE  | 45000000 | Target revenue (Rp)           |
| order_target | INTEGER | 25       | Target jumlah transaksi       |

---

## Silver Layer

### silver.silver_sales
Data penjualan yang sudah dibersihkan dan dikastip.

| Kolom            | Tipe        | Keterangan                                   |
|------------------|-------------|----------------------------------------------|
| order_id         | VARCHAR     | ID unik (PK logis)                           |
| customer_id      | VARCHAR     | Referensi customer                           |
| product_name     | VARCHAR     | Nama produk (trimmed)                        |
| category         | VARCHAR     | Kategori produk (trimmed)                    |
| quantity         | INTEGER     | Jumlah unit                                  |
| unit_price       | DECIMAL(12,2)| Harga satuan                                |
| total_price      | DECIMAL(12,2)| Total harga                                 |
| order_date       | DATE        | Tanggal order (tipe DATE)                    |
| order_year       | INTEGER     | Tahun order (derived)                        |
| order_month      | INTEGER     | Bulan order (derived)                        |
| branch           | VARCHAR     | Nama cabang                                  |
| status           | VARCHAR     | Status order (lowercase)                     |
| revenue_category | VARCHAR     | High Value / Mid Value / Low Value           |

### silver.silver_customers
Data customer yang sudah dinormalisasi.

| Kolom              | Tipe    | Keterangan                               |
|--------------------|---------|------------------------------------------|
| customer_id        | VARCHAR | ID unik (PK logis)                       |
| name               | VARCHAR | Nama (trimmed)                           |
| email              | VARCHAR | Email (lowercase, trimmed)               |
| phone              | VARCHAR | Telepon (trimmed)                        |
| city               | VARCHAR | Kota (trimmed)                           |
| branch             | VARCHAR | Cabang (trimmed)                         |
| customer_since     | DATE    | Tanggal bergabung (tipe DATE)            |
| customer_age_years | INTEGER | Lama menjadi customer (tahun)            |

### silver.silver_reviews
Data ulasan yang sudah diparsing.

| Kolom        | Tipe    | Keterangan                                    |
|--------------|---------|-----------------------------------------------|
| review_id    | VARCHAR | ID unik (PK logis)                            |
| author       | VARCHAR | Nama penulis (trimmed)                        |
| rating       | INTEGER | Rating 1–5                                    |
| review_text  | VARCHAR | Isi review (trimmed)                          |
| review_date  | DATE    | Tanggal review (tipe DATE)                    |
| review_year  | INTEGER | Tahun review (derived)                        |
| review_month | INTEGER | Bulan review (derived)                        |
| branch       | VARCHAR | Cabang (trimmed)                              |
| source       | VARCHAR | Sumber (lowercase)                            |
| sentiment    | VARCHAR | Positif (≥4) / Netral (3) / Negatif (≤2)     |

### silver.silver_targets
Data target yang sudah distandarkan.

| Kolom        | Tipe           | Keterangan                        |
|--------------|----------------|-----------------------------------|
| target_id    | VARCHAR        | ID unik (PK logis)                |
| branch       | VARCHAR        | Nama cabang (trimmed)             |
| month        | INTEGER        | Bulan (1–12)                      |
| year         | INTEGER        | Tahun                             |
| sales_target | DECIMAL(14,2)  | Target revenue (Rp)               |
| order_target | INTEGER        | Target jumlah transaksi           |
| period_label | VARCHAR        | Label: "Jan 2024", "Feb 2024"     |

---

## Gold Layer

### gold.gold_sales_daily
Agregasi penjualan harian per cabang.

| Kolom            | Tipe           | Keterangan                      |
|------------------|----------------|---------------------------------|
| order_date       | DATE           | Tanggal (PK logis bersama branch)|
| order_year       | INTEGER        | Tahun                           |
| order_month      | INTEGER        | Bulan                           |
| branch           | VARCHAR        | Cabang                          |
| total_orders     | BIGINT         | Jumlah transaksi                |
| total_revenue    | DECIMAL        | Total revenue (Rp)              |
| avg_order_value  | DECIMAL        | Rata-rata nilai order           |
| total_items_sold | BIGINT         | Total unit terjual              |
| orders_elektronik| BIGINT         | Jumlah order kategori Elektronik|
| orders_aksesoris | BIGINT         | Jumlah order kategori Aksesoris |
| orders_komponen  | BIGINT         | Jumlah order kategori Komponen  |
| rev_elektronik   | DECIMAL        | Revenue Elektronik              |
| rev_aksesoris    | DECIMAL        | Revenue Aksesoris               |
| rev_komponen     | DECIMAL        | Revenue Komponen                |

### gold.gold_branch_kpi
KPI ringkasan per cabang (semua periode).

| Kolom                  | Tipe    | Keterangan                           |
|------------------------|---------|--------------------------------------|
| branch                 | VARCHAR | Nama cabang (PK logis)               |
| total_orders           | BIGINT  | Total transaksi                      |
| total_revenue          | DECIMAL | Total revenue (Rp)                   |
| avg_order_value        | DECIMAL | Rata-rata nilai order                |
| max_order_value        | DECIMAL | Nilai order tertinggi                |
| first_sale_date        | DATE    | Tanggal penjualan pertama            |
| last_sale_date         | DATE    | Tanggal penjualan terakhir           |
| total_sales_target     | DECIMAL | Akumulasi target revenue             |
| total_order_target     | INTEGER | Akumulasi target jumlah order        |
| revenue_achievement_pct| DECIMAL | % pencapaian revenue vs target       |
| avg_rating             | DECIMAL | Rata-rata rating ulasan              |
| total_reviews          | BIGINT  | Total ulasan diterima                |

### gold.gold_review_summary
Ringkasan ulasan per cabang.

| Kolom             | Tipe    | Keterangan                          |
|-------------------|---------|-------------------------------------|
| branch            | VARCHAR | Nama cabang (PK logis)              |
| total_reviews     | BIGINT  | Jumlah ulasan                       |
| avg_rating        | DECIMAL | Rata-rata bintang                   |
| rating_5          | BIGINT  | Jumlah ulasan bintang 5             |
| rating_4          | BIGINT  | Jumlah ulasan bintang 4             |
| rating_3          | BIGINT  | Jumlah ulasan bintang 3             |
| rating_2          | BIGINT  | Jumlah ulasan bintang 2             |
| rating_1          | BIGINT  | Jumlah ulasan bintang 1             |
| sentiment_positif | BIGINT  | Jumlah ulasan sentimen positif      |
| sentiment_netral  | BIGINT  | Jumlah ulasan sentimen netral       |
| sentiment_negatif | BIGINT  | Jumlah ulasan sentimen negatif      |
| pct_positif       | DECIMAL | % ulasan positif dari total         |
