-- ============================================================================
-- UTS MANAJEMEN BASIS DATA (MBD) - UIN SUNAN GUNUNG DJATI BANDUNG
-- Nama : Faiz Muhammad Ilham Hariry
-- NIM  : 1247050032
-- Kelas: IF A 24 (Semester 5)
-- ============================================================================

-- ==========================================
-- SOAL 1: PEMBUATAN SCHEMA & TABEL MAHASISWAS
-- ==========================================
CREATE SCHEMA IF NOT EXISTS SALAM;

CREATE TABLE IF NOT EXISTS SALAM.mahasiswas (
    nim VARCHAR(10) PRIMARY KEY,
    email VARCHAR(100) UNIQUE NOT NULL,
    nama VARCHAR(100) NOT NULL,
    jurusan VARCHAR(50) NOT NULL,
    ipk NUMERIC(3,2) CHECK (ipk >= 0.00 AND ipk <= 4.00),
    semester INT CHECK (semester >= 1 AND semester <= 14)
);


-- ==========================================
-- FITUR PEMBEDA 1: AUDIT LOG SYSTEM (DBSecurity)
-- ==========================================
CREATE TABLE IF NOT EXISTS SALAM.activity_logs (
    log_id SERIAL PRIMARY KEY,
    username VARCHAR(50) DEFAULT CURRENT_USER,
    action_type VARCHAR(20) NOT NULL,
    table_name VARCHAR(50) NOT NULL,
    executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    details TEXT
);


-- ==========================================
-- SOAL 2: INSERT & UPDATE DATA AWAL (PRESISI SALAM REAL)
-- ==========================================
INSERT INTO SALAM.mahasiswas (nim, email, nama, jurusan, ipk, semester) 
VALUES (
    '1247050032', 
    '1247050032@student.uingd.ac.id', 
    'Faiz Muhammad Ilham Hariry', 
    'Teknik Informatika', 
    3.71, 
    5
)

ON CONFLICT (nim) DO UPDATE 
SET ipk = 3.71, semester = 5;

SELECT * FROM SALAM.mahasiswas WHERE nim = '1247050032';

-- Catat jejak transaksi ke Audit Log
INSERT INTO SALAM.activity_logs (action_type, table_name, details)
VALUES ('INSERT/UPDATE', 'mahasiswas', 'Inisialisasi data mahasiswa Faiz Muhammad Ilham Hariry (NIM: 1247050032)');

SELECT * FROM SALAM.activity_logs;

-- A. Uji Unique Constraint (Email Dobel -> Harus Gagal)
-- Blok baris ini lalu tekan Ctrl + Enter -> Screenshot Error Red Box
INSERT INTO SALAM.mahasiswas VALUES ('1247050099', '1247050032@student.uingd.ac.id', 'Mbappe Test', 'Teknik Informatika', 3.50, 3);

-- B. Uji Check Constraint IPK (IPK 4.50 -> Harus Gagal)
-- Blok baris ini lalu tekan Ctrl + Enter -> Screenshot Error Red Box
INSERT INTO SALAM.mahasiswas VALUES ('1247050088', 'messi@student.uingd.ac.id', 'Messi Test', 'Teknik Informatika', 4.50, 3);

-- C. Uji Primary Key (NIM Dobel -> Harus Gagal)
-- Email sengaja dibuat beda supaya yang kena PRIMARY KEY, bukan UNIQUE email
-- Blok baris ini lalu tekan Ctrl + Enter -> Screenshot Error Red Box
INSERT INTO SALAM.mahasiswas VALUES ('1247050032', 'email.beda@student.uingd.ac.id', 'Test PK', 'Teknik Informatika', 3.50, 3);




-- ==========================================
-- FITUR PEMBEDA 2: TABEL KEHADIRAN KULIAH (SALAM DASHBOARD INTEGRATION)
-- ==========================================
CREATE TABLE IF NOT EXISTS SALAM.kehadiran_kuliah (
    id SERIAL PRIMARY KEY,
    nim VARCHAR(10) REFERENCES SALAM.mahasiswas(nim) ON DELETE CASCADE,
    matakuliah VARCHAR(100) NOT NULL,
    total_pertemuan INT DEFAULT 8,
    jumlah_hadir INT DEFAULT 8
);

-- Insert data kehadiran sesuai Dashboard SALAM UIN
INSERT INTO SALAM.kehadiran_kuliah (nim, matakuliah, total_pertemuan, jumlah_hadir) VALUES 
('1247050032', 'Intelegensia Buatan', 8, 8),
('1247050032', 'Interaksi Manusia dan Komputer', 8, 8),
('1247050032', 'Jaringan Komputer', 8, 8);


SELECT * FROM SALAM.kehadiran_kuliah;

-- ==========================================
-- FITUR PEMBEDA 3: ANALYTICS VIEW UNTUK ROLE BI_DEV
-- ==========================================
CREATE OR REPLACE VIEW SALAM.vw_rekap_akademik AS
SELECT 
    jurusan,
    COUNT(*) AS total_mahasiswa,
    ROUND(AVG(ipk), 2) AS rata_rata_ipk,
    MAX(ipk) AS ipk_tertinggi
FROM SALAM.mahasiswas
GROUP BY jurusan;

SELECT * FROM SALAM.vw_rekap_akademik;

-- ==========================================
-- SOAL 4: PEMBUATAN USER & ROLE (RBAC - SS 4.1)
-- ==========================================
-- 1. User backend_dev (Role: CRUD Data)
CREATE USER backend_dev WITH PASSWORD 'pass_backend032';
GRANT USAGE ON SCHEMA SALAM TO backend_dev;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA SALAM TO backend_dev;
ALTER DEFAULT PRIVILEGES IN SCHEMA SALAM GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO backend_dev;

-- 2. User bi_dev (Role: Hanya Read/Select)
CREATE USER bi_dev WITH PASSWORD 'pass_bidev032';
GRANT USAGE ON SCHEMA SALAM TO bi_dev;
GRANT SELECT ON ALL TABLES IN SCHEMA SALAM TO bi_dev;
GRANT SELECT ON SALAM.vw_rekap_akademik TO bi_dev;
ALTER DEFAULT PRIVILEGES IN SCHEMA SALAM GRANT SELECT ON TABLES TO bi_dev;

-- 3. User data_engineer (Role: Full Access DDL & DML)
CREATE USER data_engineer WITH PASSWORD 'pass_dataeng032';
GRANT ALL PRIVILEGES ON SCHEMA SALAM TO data_engineer;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA SALAM TO data_engineer;

-- Tabel dummy milik postgres, untuk bukti DROP objek yang bukan buatan data_engineer
CREATE TABLE IF NOT EXISTS SALAM.tb_dummy_postgres (id INT);

-- Jadikan data_engineer owner semua objek di schema SALAM agar bisa CREATE, MODIFY, DROP
ALTER SCHEMA SALAM OWNER TO data_engineer;
ALTER TABLE SALAM.mahasiswas OWNER TO data_engineer;
ALTER TABLE SALAM.activity_logs OWNER TO data_engineer;
ALTER TABLE SALAM.kehadiran_kuliah OWNER TO data_engineer;
ALTER TABLE SALAM.tb_dummy_postgres OWNER TO data_engineer;
ALTER VIEW SALAM.vw_rekap_akademik OWNER TO data_engineer;

-- Objek baru buatan data_engineer otomatis bisa diakses role lain
ALTER DEFAULT PRIVILEGES FOR ROLE data_engineer IN SCHEMA SALAM GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO backend_dev;
ALTER DEFAULT PRIVILEGES FOR ROLE data_engineer IN SCHEMA SALAM GRANT SELECT ON TABLES TO bi_dev;

SELECT current_user;

SELECT schemaname, tablename, tableowner FROM pg_tables WHERE schemaname = 'salam';

-- ==========================================
-- PENGUJIAN HAK AKSES bi_dev (UNTUK SS 4.2)
-- ==========================================
SET ROLE bi_dev;

-- a. SELECT Berhasil (Blok 2 baris ini -> Ctrl+Enter -> SS Hasil)
SELECT * FROM SALAM.mahasiswas;

-- b. DELETE GAGAL (Blok baris ini -> Ctrl+Enter -> SS Error Red Box)
DELETE FROM SALAM.mahasiswas WHERE nim = '1247050032';

RESET ROLE;


-- ==========================================
-- PENGUJIAN HAK AKSES backend_dev (UNTUK SS 4.3)
-- ==========================================
SET ROLE backend_dev;

SELECT current_user;

-- a. INSERT Berhasil (Blok 2 baris ini -> Ctrl+Enter -> SS Updated Rows: 1)
INSERT INTO SALAM.mahasiswas VALUES ('1247050007', 'ronaldo07@student.uingd.ac.id', 'Ronaldo', 'Teknik Informatika', 3.50, 3);

-- a2. SELECT Berhasil
SELECT * FROM SALAM.mahasiswas;

-- a3. UPDATE Berhasil
UPDATE SALAM.mahasiswas SET ipk = 3.60 WHERE nim = '1247050007';

-- a4. DELETE Berhasil
DELETE FROM SALAM.mahasiswas WHERE nim = '1247050007';

-- b. DROP TABLE GAGAL (Blok baris ini -> Ctrl+Enter -> SS Error Red Box)
DROP TABLE SALAM.mahasiswas;

RESET ROLE;

-- =========================================================
-- PENGUJIAN HAK AKSES data_engineer (SOAL SS 4.4)
-- =========================================================
SET ROLE data_engineer;

-- 1. Uji DDL: CREATE TABLE (BERHASIL)
CREATE TABLE SALAM.tb_engineer_test (
    id INT PRIMARY KEY,
    keterangan VARCHAR(50)
);

-- 2. Uji DDL: MODIFY / ALTER TABLE (BERHASIL)
ALTER TABLE SALAM.tb_engineer_test ADD COLUMN dibuat_pada TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

-- 3. Uji DML: INSERT / CRUD (BERHASIL)
INSERT INTO SALAM.tb_engineer_test (id, keterangan) VALUES (1, 'Pengujian Data Engineer');

-- 4. Uji DML: SELECT / CRUD (BERHASIL)
SELECT * FROM SALAM.tb_engineer_test;

-- 5. Uji DDL: DROP TABLE (BERHASIL)
DROP TABLE SALAM.tb_engineer_test;

-- 6. Uji MODIFY objek milik awal postgres: ALTER TABLE mahasiswas (BERHASIL)
ALTER TABLE SALAM.mahasiswas ADD COLUMN no_hp VARCHAR(15);
ALTER TABLE SALAM.mahasiswas ALTER COLUMN no_hp TYPE VARCHAR(20);
ALTER TABLE SALAM.mahasiswas DROP COLUMN no_hp;

-- 7. Uji CRUD pada tabel mahasiswas (BERHASIL)
UPDATE SALAM.mahasiswas SET semester = 5 WHERE nim = '1247050032';
SELECT * FROM SALAM.mahasiswas;

-- 8. Uji DROP objek milik awal postgres (BERHASIL)
DROP TABLE SALAM.tb_dummy_postgres;

-- Reset Peran Kembali ke Superuser
RESET ROLE;