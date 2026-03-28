# Arsitektur Minilab EduBI

## Medallion Architecture

```
[Sumber Data]          [Bronze]           [Silver]           [Gold]
Odoo (XML-RPC)  ---->  Raw tables  ---->  Cleaned  ---->  Aggregated / BI-ready
Google Reviews  ---->  (as-is)            Validated        Metrics & KPIs
CSV files       ---->                     Enriched         Dashboard-ready
```

## Layer

### Bronze
- Data mentah dari sumber, tidak ada transformasi
- Disimpan di schema `bronze` dalam DuckDB
- Diisi oleh script ETL (`etl/load_csv.py`, `etl/extract_odoo.py`, dll)

### Silver
- Data sudah dibersihkan: null handling, tipe data konsisten, duplikat dihapus
- Relasi antar tabel mulai dibangun
- Diisi oleh dbt models di `dbt_project/models/silver/`

### Gold
- Data siap untuk BI dan dashboard
- Aggregasi, metrik bisnis, denormalisasi
- Diisi oleh dbt models di `dbt_project/models/gold/`
- Dikonsumsi oleh Metabase

## Stack Teknologi

| Komponen   | Tool            | Fungsi                          |
|------------|-----------------|---------------------------------|
| Storage    | DuckDB          | Database lokal, in-process      |
| ETL        | Python (pandas) | Ekstrak & load data mentah      |
| Transform  | dbt Core        | Transformasi SQL Bronze→Gold    |
| Visualisasi| Metabase        | Dashboard & eksplorasi data     |
