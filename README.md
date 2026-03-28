# Minilab EduBI

PoC Business Intelligence untuk mahasiswa menggunakan:
- DuckDB
- Python
- dbt Core
- Metabase

## Arsitektur
Menggunakan Medallion Architecture:
- Bronze: raw data
- Silver: cleaned data
- Gold: BI-ready data

## Setup

### 1. Install dependency
pip install -r requirements.txt

### 2. Jalankan ETL awal
python etl/init_duckdb.py

### 3. Jalankan dbt
cd dbt_project
dbt run

### 4. Jalankan Metabase
docker run -d -p 3000:3000 metabase/metabase

## Output
Dashboard:
- Sales performance
- Customer insight
- Review analysis
