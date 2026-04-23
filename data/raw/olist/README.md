# Data Olist Brazilian E-Commerce

Dataset ini tidak disertakan di repositori karena bersumber dari Kaggle.

## Cara Download

1. Buka https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce
2. Klik **Download** (butuh akun Kaggle gratis)
3. Ekstrak semua file CSV ke folder ini (`data/raw/olist/`)

## File yang Dibutuhkan

```
data/raw/olist/
├── olist_orders_dataset.csv
├── olist_order_items_dataset.csv
├── olist_order_payments_dataset.csv
├── olist_order_reviews_dataset.csv
├── olist_customers_dataset.csv
├── olist_sellers_dataset.csv
├── olist_products_dataset.csv
├── olist_geolocation_dataset.csv          ← opsional, tidak dipakai pipeline
└── product_category_name_translation.csv
```

## Tentang Dataset

| Atribut | Nilai |
|---------|-------|
| Sumber | Olist Store, Brazil |
| Periode | Januari 2016 – Agustus 2018 |
| Jumlah Order | ~100.000 |
| Jumlah Customer | ~100.000 unique |
| Jumlah Seller | ~3.000 |
| Jumlah Produk | ~33.000 |

## Skema Relasi

```
olist_customers ──────────┐
                          ↓
olist_orders ─────── olist_order_items ──── olist_products ── product_category_translation
    │                                              │
    ├── olist_order_reviews                   olist_sellers
    └── olist_order_payments
```

## Perbedaan Utama vs Dataset Toko Elektronik (Minilab)

| Aspek | Toko Elektronik | Olist |
|-------|----------------|-------|
| Sumber | PostgreSQL (ERP sim) | CSV flat files |
| Order granularity | 1 order = 1 item | 1 order = banyak item |
| Customer ID | Tetap per customer | `customer_unique_id` (customer_id berubah tiap order) |
| Status | done / cancelled | delivered / shipped / canceled / processing |
| Ulasan | Google Reviews terpisah | Terintegrasi di order_reviews |
| Dimensi utama | Cabang (branch) | Seller state, customer state |
| Delivery data | Tidak ada | Ada (estimated vs actual delivery) |
| Skala | 200 transaksi | 100k+ transaksi |
