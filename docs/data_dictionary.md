# Data Dictionary

## bronze.sales_orders

| Kolom        | Tipe    | Deskripsi                        |
|--------------|---------|----------------------------------|
| id           | INTEGER | ID order dari Odoo               |
| name         | VARCHAR | Nomor referensi order (SO/xxxxx) |
| partner_id   | VARCHAR | ID & nama customer               |
| date_order   | VARCHAR | Tanggal order dibuat             |
| amount_total | DOUBLE  | Total nilai order                |
| state        | VARCHAR | Status order (draft/sale/done)   |

## bronze.customers

| Kolom      | Tipe    | Deskripsi              |
|------------|---------|------------------------|
| id         | INTEGER | ID partner dari Odoo   |
| name       | VARCHAR | Nama customer          |
| email      | VARCHAR | Alamat email           |
| phone      | VARCHAR | Nomor telepon          |
| city       | VARCHAR | Kota                   |
| country_id | VARCHAR | ID & nama negara       |

## bronze.google_reviews

| Kolom   | Tipe    | Deskripsi                   |
|---------|---------|-----------------------------|
| author  | VARCHAR | Nama penulis review         |
| rating  | INTEGER | Rating bintang (1-5)        |
| text    | VARCHAR | Isi teks review             |
| time    | INTEGER | Unix timestamp review       |

## silver.* (akan diisi seiring pengembangan)

## gold.* (akan diisi seiring pengembangan)
