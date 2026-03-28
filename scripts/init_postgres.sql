-- =============================================================
-- init_postgres.sql
-- Inisialisasi PostgreSQL untuk Minilab EduBI
-- Membuat dua schema:
--   odoo_sim  = simulasi sumber data ERP (dibaca oleh ETL)
--   analytics = export hasil Gold dari DuckDB (dibaca Metabase)
-- =============================================================

-- ----------------------
-- Schema odoo_sim
-- ----------------------
CREATE SCHEMA IF NOT EXISTS odoo_sim;

-- Tabel simulasi customer dari Odoo
CREATE TABLE IF NOT EXISTS odoo_sim.res_partner (
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,
    email       VARCHAR(100),
    phone       VARCHAR(20),
    city        VARCHAR(50),
    branch      VARCHAR(50),
    customer_since DATE,
    active      BOOLEAN DEFAULT TRUE,
    created_at  TIMESTAMP DEFAULT NOW()
);

-- Tabel simulasi sales order dari Odoo
CREATE TABLE IF NOT EXISTS odoo_sim.sale_order (
    id              SERIAL PRIMARY KEY,
    name            VARCHAR(20) NOT NULL,
    partner_id      INTEGER REFERENCES odoo_sim.res_partner(id),
    product_name    VARCHAR(100),
    category        VARCHAR(50),
    quantity        INTEGER,
    unit_price      NUMERIC(12,2),
    amount_total    NUMERIC(12,2),
    date_order      DATE,
    branch          VARCHAR(50),
    state           VARCHAR(20) DEFAULT 'done',
    created_at      TIMESTAMP DEFAULT NOW()
);

-- ----------------------
-- Seed data odoo_sim
-- ----------------------
INSERT INTO odoo_sim.res_partner (name, email, phone, city, branch, customer_since) VALUES
('Andi Saputra',    'andi.saputra@email.com',    '081234567001', 'Jakarta',    'Pusat',      '2021-03-15'),
('Budi Santoso',    'budi.santoso@email.com',    '081234567002', 'Bandung',    'Bandung',    '2020-07-22'),
('Citra Dewi',      'citra.dewi@email.com',      '081234567003', 'Jakarta',    'Pusat',      '2022-01-10'),
('Dian Rahmawati',  'dian.rahmawati@email.com',  '081234567004', 'Surabaya',   'Surabaya',   '2019-11-05'),
('Eka Prasetyo',    'eka.prasetyo@email.com',    '081234567005', 'Jakarta',    'Selatan',    '2021-08-30'),
('Fajar Nugroho',   'fajar.nugroho@email.com',   '081234567006', 'Bandung',    'Bandung',    '2022-04-18'),
('Gita Lestari',    'gita.lestari@email.com',    '081234567007', 'Surabaya',   'Surabaya',   '2020-02-14'),
('Hendra Wijaya',   'hendra.wijaya@email.com',   '081234567008', 'Jakarta',    'Pusat',      '2023-06-01'),
('Indah Permata',   'indah.permata@email.com',   '081234567009', 'Yogyakarta', 'Yogyakarta', '2021-12-20'),
('Joko Susilo',     'joko.susilo@email.com',     '081234567010', 'Jakarta',    'Selatan',    '2019-05-09')
ON CONFLICT DO NOTHING;

INSERT INTO odoo_sim.sale_order (name, partner_id, product_name, category, quantity, unit_price, amount_total, date_order, branch, state) VALUES
('SO001', 1, 'Laptop Acer Aspire 5',    'Elektronik', 1, 7500000,  7500000,  '2024-01-05', 'Pusat',      'done'),
('SO002', 2, 'Mouse Wireless Logitech', 'Aksesoris',  2,  350000,   700000,  '2024-01-07', 'Bandung',    'done'),
('SO003', 3, 'Monitor LG 24 inch',      'Elektronik', 1, 2800000,  2800000,  '2024-01-10', 'Pusat',      'done'),
('SO004', 4, 'Keyboard Mechanical',     'Aksesoris',  1,  850000,   850000,  '2024-01-12', 'Surabaya',   'done'),
('SO005', 5, 'Headset Sony',            'Aksesoris',  1, 1200000,  1200000,  '2024-01-15', 'Selatan',    'done'),
('SO006', 6, 'Laptop Asus Vivobook',    'Elektronik', 1, 8200000,  8200000,  '2024-01-18', 'Bandung',    'done'),
('SO007', 7, 'Webcam Logitech C920',    'Aksesoris',  1,  900000,   900000,  '2024-01-20', 'Surabaya',   'done'),
('SO008', 8, 'SSD Samsung 1TB',         'Komponen',   2, 1100000,  2200000,  '2024-01-22', 'Pusat',      'done'),
('SO009', 9, 'RAM DDR4 16GB',           'Komponen',   1,  650000,   650000,  '2024-01-25', 'Yogyakarta', 'done'),
('SO010',10, 'Printer Canon PIXMA',     'Elektronik', 1, 1500000,  1500000,  '2024-01-28', 'Selatan',    'done')
ON CONFLICT DO NOTHING;

-- ----------------------
-- Schema analytics
-- (diisi oleh export_gold_to_postgres.py)
-- ----------------------
CREATE SCHEMA IF NOT EXISTS analytics;

COMMENT ON SCHEMA odoo_sim  IS 'Simulasi sumber data ERP Odoo';
COMMENT ON SCHEMA analytics IS 'Export hasil Gold layer DuckDB untuk Metabase';
