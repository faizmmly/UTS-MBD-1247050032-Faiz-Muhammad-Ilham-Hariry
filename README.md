# UTS Manajemen Basis Data: PostgreSQL & pgAdmin4 dengan Docker

**Nama:** Faiz Muhammad Ilham Hariry
**NIM:** 1247050032
**Kelas:** IF A 24

## Isi Repository

| File | Fungsi |
|---|---|
| `docker-compose.yml` | Mendefinisikan service PostgreSQL 15 dan pgAdmin4 |
| `.env` | Menyimpan username, password, dan port (tidak di-hardcode di compose) |
| `script_uts.sql` | Schema SALAM, tabel, constraint, user/role, dan pengujian hak akses |

## Cara Menjalankan

1. Pastikan Docker Desktop sudah berjalan.
2. Jalankan:
   ```bash
   docker compose up -d
   ```
3. Cek container:
   ```bash
   docker container ls
   ```

## Service dan Port

| Service | Container | Port Host | Akses |
|---|---|---|---|
| PostgreSQL 15 | `postgres_faizmuhammadilham` | `22032` | DBeaver (eksternal) |
| pgAdmin4 | `pgadmin_faizmuhammadilham` | `44032` | http://localhost:44032 |

Koneksi internal dari pgAdmin memakai host `postgres_faizmuhammadilham` dan port `5432`.

## Menjalankan Script SQL

Buka `script_uts.sql` di DBeaver (koneksi `localhost:22032`), lalu jalankan per bagian, bukan sekaligus. `CREATE USER` akan error jika user sudah ada.

## Isi Script

- Schema `SALAM` dan tabel `mahasiswas` (PRIMARY KEY, UNIQUE, CHECK)
- Pengujian constraint yang harus gagal
- User `backend_dev` (CRUD), `bi_dev` (read-only), `data_engineer` (DDL dan DML)
- Fitur pembeda: `activity_logs`, `kehadiran_kuliah`, dan view `vw_rekap_akademik`
