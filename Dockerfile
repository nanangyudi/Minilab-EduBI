# Dockerfile
# Image untuk service app (ETL) dan dbt dalam Minilab EduBI
# Base: Python 3.11 slim

FROM python:3.11-slim

WORKDIR /app

# Install dependency sistem (untuk psycopg2)
RUN apt-get update && apt-get install -y \
    gcc \
    libpq-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements lebih dulu agar layer ini di-cache Docker
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy seluruh kode proyek
COPY . .

# Pastikan folder data tersedia
RUN mkdir -p data/raw data/processed

CMD ["python", "etl/run_pipeline.py"]
