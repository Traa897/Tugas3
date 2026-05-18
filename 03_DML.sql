-- =====================================================
-- BAGIAN 3.2: DML - INSERT SAMPLE DATA
-- Database: d_kos_kosan
-- Purpose: Populate schema dengan data sample
-- Date: May 2024
-- =====================================================

-- =====================================================
-- CLEANUP: DELETE EXISTING DATA (JALANKAN SETELAH DDL)
-- =====================================================

DELETE FROM maintenance_history;
DELETE FROM maintenance_request;
DELETE FROM pembayaran;
DELETE FROM kontrak_sewa;
DELETE FROM kamar_fasilitas;
DELETE FROM kamar;
DELETE FROM penyewa;
DELETE FROM fasilitas;
DELETE FROM tipe_kamar;
DELETE FROM kos;

-- Reset SERIAL sequences
ALTER SEQUENCE kos_id_seq RESTART WITH 1;
ALTER SEQUENCE tipe_kamar_id_seq RESTART WITH 1;
ALTER SEQUENCE kamar_id_seq RESTART WITH 1;
ALTER SEQUENCE penyewa_id_seq RESTART WITH 1;
ALTER SEQUENCE kontrak_sewa_id_seq RESTART WITH 1;
ALTER SEQUENCE pembayaran_id_seq RESTART WITH 1;
ALTER SEQUENCE fasilitas_id_seq RESTART WITH 1;
ALTER SEQUENCE maintenance_request_id_seq RESTART WITH 1;
ALTER SEQUENCE maintenance_history_id_seq RESTART WITH 1;

-- =====================================================
-- 1. INSERT DATA KOS
-- =====================================================

INSERT INTO kos (nama, alamat, kota, pemilik, telp_pemilik) 
VALUES 
('Kos Sejahtera', 'Jl. Merdeka No. 45, RT 02/RW 03', 'Bandung', 'Budi Santoso', '081234567890');

-- =====================================================
-- 2. INSERT DATA TIPE KAMAR
-- =====================================================

INSERT INTO tipe_kamar (kos_id, nama, deskripsi, harga_sewa, fasilitas_included) 
VALUES 
(1, 'Reguler', 'Kamar standar dengan bed dan meja', 1500000, '["listrik", "air", "kamar mandi dalam"]'),
(1, 'Deluxe', 'Kamar lebih luas dengan AC', 2500000, '["listrik", "air", "kamar mandi dalam", "AC", "WiFi"]'),
(1, 'Premium', 'Kamar terbesar dengan fasilitas lengkap', 3500000, '["listrik", "air", "kamar mandi dalam", "AC", "WiFi", "water heater", "lemari es"]');

-- =====================================================
-- 3. INSERT DATA FASILITAS
-- =====================================================

INSERT INTO fasilitas (nama, kategori, harga_premium, deskripsi) 
VALUES 
('AC', 'elektronik', 500000, 'Air Conditioner split unit'),
('WiFi', 'utility', 300000, 'Akses internet unlimited'),
('Water Heater', 'elektronik', 400000, 'Pemanas air listrik'),
('Kulkas', 'elektronik', 300000, 'Lemari es mini'),
('TV', 'elektronik', 200000, 'Televisi 32 inch'),
('Kasur Spring', 'furniture', 250000, 'Kasur berkualitas dengan spring'),
('Meja Belajar', 'furniture', 150000, 'Meja kayu untuk belajar'),
('Lemari Pakaian', 'furniture', 200000, 'Lemari kayu untuk menyimpan pakaian'),
('Sofa', 'furniture', 300000, 'Sofa kecil untuk ruang keluarga'),
('Parkir Motor', 'utility', 200000, 'Area parkir berjauh');

-- =====================================================
-- 4. INSERT DATA KAMAR (16 kamar di 3 lantai)
-- =====================================================

INSERT INTO kamar (kos_id, tipe_id, nomor, luas, lantai, status, catatan) 
VALUES 
(1, 1, '101', 12.0, 1, 'terisi', 'Kamar depan dekat teras'),
(1, 1, '102', 12.0, 1, 'terisi', 'Dekat kamar mandi umum'),
(1, 1, '103', 12.0, 1, 'kosong', 'Baru reno, siap huni'),
(1, 1, '104', 12.0, 1, 'terisi', NULL),
(1, 2, '105', 18.0, 1, 'terisi', 'Kamar corner dengan jendela besar'),
(1, 2, '106', 18.0, 1, 'kosong', 'Dalam persiapan pembersihan'),
(1, 1, '201', 12.0, 2, 'terisi', NULL),
(1, 1, '202', 12.0, 2, 'reserved', 'Dipesan sampai minggu depan'),
(1, 1, '203', 12.0, 2, 'maintenance', 'Perbaikan AC sedang berlangsung'),
(1, 1, '204', 12.0, 2, 'kosong', NULL),
(1, 2, '205', 18.0, 2, 'terisi', 'Dekat tangga'),
(1, 2, '206', 18.0, 2, 'terisi', 'Dekat balkon'),
(1, 3, '301', 24.0, 3, 'terisi', 'Suite room dengan living area'),
(1, 3, '302', 24.0, 3, 'kosong', 'Belum ada penyewa'),
(1, 2, '303', 18.0, 3, 'terisi', NULL),
(1, 2, '304', 18.0, 3, 'kosong', NULL);

-- =====================================================
-- 5. INSERT DATA PENYEWA (24 penyewa)
-- =====================================================

INSERT INTO penyewa (kos_id, nama, email, telp, ktp, status) 
VALUES 
(1, 'Ahmad Rizki', 'ahmad.rizki@gmail.com', '081234567890', '3271022001010001', 'aktif'),
(1, 'Siti Nurhaliza', 'siti.n@email.com', '081234567892', '3271022002010002', 'aktif'),
(1, 'Budi Hermawan', 'budi.h@gmail.com', '081234567894', '3271022001110003', 'aktif'),
(1, 'Eka Putri', 'eka.putri89@email.com', '081234567896', '3271022003020004', 'aktif'),
(1, 'Farah Diba', 'farah.diba@email.com', '081234567898', '3271022002110005', 'aktif'),
(1, 'Guntur Subiantoro', 'guntur.sub@gmail.com', '081234567900', '3271022001050006', 'aktif'),
(1, 'Hendra Wijaya', 'hendra.w@email.com', '081234567902', '3271022000090007', 'aktif'),
(1, 'Ika Saputri', 'ika.saputri@email.com', '081234567904', '3271022003050008', 'aktif'),
(1, 'Joko Pratama', 'joko.p@gmail.com', '081234567906', '3271022001080009', 'aktif'),
(1, 'Krisna Murti', 'krisna.m@email.com', '081234567908', '3271022002030010', 'aktif'),
(1, 'Lina Kusuma', 'lina.kusuma@email.com', '081234567910', '3271022000120011', 'non-aktif'),
(1, 'Mimin Suryanto', 'mimin.s@gmail.com', '081234567912', '3271022001070012', 'non-aktif'),
(1, 'Nadia Azzahra', 'nadia.azzahra@email.com', '081234567914', '3271022002040013', 'non-aktif'),
(1, 'Oster Siahaan', 'oster.s@email.com', '081234567916', '3271022000110014', 'non-aktif'),
(1, 'Priyanto Eka', 'priyanto.e@gmail.com', '081234567918', '3271022001060015', 'non-aktif'),
(1, 'Rina Samsuri', 'rina.samsuri@email.com', '081234567920', '3271022003030016', 'blacklist'),
(1, 'Supriyanto Adil', 'supriyanto.a@gmail.com', '081234567922', '3271022000100017', 'aktif'),
(1, 'Tini Kusniawati', 'tini.kusniawati@email.com', '081234567924', '3271022002080018', 'aktif'),
(1, 'Uji Subagja', 'uji.subagja@email.com', '081234567926', '3271022001040019', 'aktif'),
(1, 'Vina Rahmawati', 'vina.r@email.com', '081234567928', '3271022003010020', 'aktif'),
(1, 'Wahyu Santoso', 'wahyu.s@email.com', '081234567930', '3271022000020021', 'aktif'),
(1, 'Xenius Pratama', 'xenius.p@gmail.com', '081234567932', '3271022001120022', 'aktif'),
(1, 'Yenny Wijaya', 'yenny.w@email.com', '081234567934', '3271022002110023', 'aktif'),
(1, 'Zulfikri Apandi', 'zulfikri.a@gmail.com', '081234567936', '3271022000070024', 'aktif');

-- =====================================================
-- 6. INSERT DATA KAMAR_FASILITAS (Relasi many-to-many)
-- =====================================================

INSERT INTO kamar_fasilitas (kamar_id, fasilitas_id, kondisi) VALUES
(1, 1, 'baik'), (1, 5, 'baik'), (1, 6, 'baik'), (1, 7, 'baik'),
(2, 6, 'baik'), (2, 7, 'baik'), (2, 8, 'baik'),
(3, 6, 'baik'), (3, 7, 'baik'), (3, 8, 'baik'),
(4, 6, 'rusak'), (4, 7, 'baik'), (4, 5, 'baik'),
(5, 1, 'baik'), (5, 2, 'baik'), (5, 3, 'baik'), (5, 4, 'baik'), (5, 6, 'baik'), (5, 7, 'baik'), (5, 8, 'baik'),
(6, 1, 'baik'), (6, 2, 'baik'), (6, 3, 'baik'), (6, 4, 'baik'), (6, 6, 'baik'),
(7, 6, 'baik'), (7, 7, 'baik'), (7, 8, 'baik'),
(8, 6, 'baik'), (8, 7, 'baik'), (8, 5, 'baik'),
(9, 1, 'rusak'), (9, 6, 'baik'), (9, 7, 'baik'),
(10, 6, 'baik'), (10, 7, 'baik'), (10, 8, 'baik'),
(11, 1, 'baik'), (11, 2, 'baik'), (11, 3, 'baik'), (11, 4, 'baik'), (11, 6, 'baik'), (11, 9, 'baik'),
(12, 1, 'baik'), (12, 2, 'baik'), (12, 3, 'baik'), (12, 4, 'baik'), (12, 6, 'baik'), (12, 7, 'baik'),
(13, 1, 'baik'), (13, 2, 'baik'), (13, 3, 'baik'), (13, 4, 'baik'), (13, 6, 'baik'), (13, 7, 'baik'), (13, 8, 'baik'), (13, 9, 'baik'), (13, 10, 'baik'),
(14, 1, 'baik'), (14, 2, 'baik'), (14, 3, 'baik'), (14, 4, 'baik'), (14, 6, 'baik'), (14, 7, 'baik'),
(15, 1, 'baik'), (15, 2, 'baik'), (15, 3, 'baik'), (15, 4, 'baik'), (15, 6, 'baik'), (15, 10, 'baik'),
(16, 1, 'baik'), (16, 2, 'baik'), (16, 3, 'baik'), (16, 6, 'baik');

-- =====================================================
-- 7. INSERT DATA KONTRAK SEWA (20 kontrak)
-- =====================================================

ALTER TABLE kontrak_sewa DISABLE TRIGGER trg_create_pembayaran;

INSERT INTO kontrak_sewa (kamar_id, penyewa_id, tanggal_mulai, durasi_bulan, harga_per_bulan, deposit, status) 
VALUES 
(1, 1, '2024-01-15', 12, 1500000, 3000000, 'aktif'),
(2, 2, '2024-02-01', 12, 1500000, 3000000, 'aktif'),
(4, 3, '2024-03-10', 6, 1500000, 3000000, 'aktif'),
(5, 4, '2024-01-20', 12, 2500000, 5000000, 'aktif'),
(7, 5, '2024-02-15', 12, 1500000, 3000000, 'aktif'),
(8, 6, '2024-04-01', 1, 1500000, 3000000, 'aktif'),
(11, 7, '2024-01-10', 12, 2500000, 5000000, 'aktif'),
(12, 8, '2024-02-20', 12, 2500000, 5000000, 'aktif'),
(13, 9, '2024-01-05', 12, 3500000, 7000000, 'aktif'),
(15, 10, '2023-12-15', 12, 2500000, 5000000, 'aktif'),
(1, 11, '2023-01-20', 12, 1500000, 3000000, 'berakhir'),
(2, 12, '2023-03-15', 6, 1500000, 3000000, 'berakhir'),
(5, 13, '2023-02-10', 12, 2500000, 5000000, 'berakhir'),
(4, 14, '2023-06-01', 12, 1500000, 3000000, 'dibatalkan'),
(3, 15, '2024-03-01', 12, 1500000, 3000000, 'aktif'),
(6, 16, '2024-04-15', 12, 2500000, 5000000, 'aktif'),
(9, 17, '2024-02-01', 12, 1500000, 3000000, 'aktif'),
(10, 18, '2024-04-01', 6, 1500000, 3000000, 'aktif'),
(14, 19, '2024-01-25', 12, 3500000, 7000000, 'aktif'),
(16, 20, '2024-03-20', 12, 2500000, 5000000, 'aktif');

ALTER TABLE kontrak_sewa ENABLE TRIGGER trg_create_pembayaran;

-- =====================================================
-- 8. INSERT DATA PEMBAYARAN (23 records)
-- =====================================================

INSERT INTO pembayaran (kontrak_id, bulan_ke, nominal, due_date, status, tanggal_bayar, metode_bayar)
VALUES 
(1, 1, 1500000, '2024-02-15', 'paid', '2024-02-14', 'transfer'),
(1, 2, 1500000, '2024-03-15', 'paid', '2024-03-15', 'transfer'),
(1, 3, 1500000, '2024-04-15', 'paid', '2024-04-16', 'transfer'),
(1, 4, 1500000, '2024-05-15', 'paid', '2024-05-14', 'transfer'),
(1, 5, 1500000, '2024-06-15', 'overdue', NULL, NULL),
(1, 6, 1500000, '2024-07-15', 'unpaid', NULL, NULL),
(2, 1, 1500000, '2024-03-01', 'paid', '2024-03-01', 'transfer'),
(2, 2, 1500000, '2024-04-01', 'paid', '2024-04-01', 'transfer'),
(2, 3, 1500000, '2024-05-01', 'paid', '2024-05-02', 'transfer'),
(2, 4, 1500000, '2024-06-01', 'unpaid', NULL, NULL),
(3, 1, 1500000, '2024-04-10', 'paid', '2024-04-10', 'transfer'),
(3, 2, 1500000, '2024-05-10', 'paid', '2024-05-11', 'transfer'),
(3, 3, 1500000, '2024-06-10', 'unpaid', NULL, NULL),
(4, 1, 2500000, '2024-02-20', 'paid', '2024-02-19', 'transfer'),
(4, 2, 2500000, '2024-03-20', 'paid', '2024-03-20', 'transfer'),
(4, 3, 2500000, '2024-04-20', 'paid', '2024-04-21', 'transfer'),
(4, 4, 2500000, '2024-05-20', 'overdue', NULL, NULL),
(5, 1, 1500000, '2024-03-15', 'paid', '2024-03-15', 'transfer'),
(5, 2, 1500000, '2024-04-15', 'paid', '2024-04-15', 'transfer'),
(5, 3, 1500000, '2024-05-15', 'paid', '2024-05-16', 'transfer'),
(5, 4, 1500000, '2024-06-15', 'unpaid', NULL, NULL),
(6, 1, 2500000, '2024-05-01', 'paid', '2024-05-01', 'transfer'),
(7, 1, 2500000, '2024-02-10', 'paid', '2024-02-10', 'transfer');

-- =====================================================
-- 9. INSERT DATA MAINTENANCE_REQUEST (9 requests)
-- =====================================================

INSERT INTO maintenance_request (kamar_id, penyewa_id, deskripsi, kategori, status, tanggal_target_selesai, biaya_estimasi, ditanggung_penyewa) 
VALUES 
(9, 17, 'AC tidak mendingin, perlu servis atau ganti kompressor', 'urgent', 'in-progress', '2024-05-18', 500000, FALSE),
(4, 3, 'Keran kamar mandi bocor, perlu perbaikan pipa', 'normal', 'open', '2024-05-20', 300000, FALSE),
(4, 3, 'Kasur sudah lumpy dan tidak nyaman, perlu diganti', 'normal', 'open', '2024-05-25', 250000, FALSE),
(13, 9, 'Sofa berlubang dan kembung, perlu dijahit atau diganti', 'normal', 'completed', '2024-05-10', 400000, TRUE),
(16, 20, 'Lemari pakaian goyah dan terasa tidak aman', 'normal', 'open', '2024-05-20', 150000, FALSE),
(5, 4, 'Koneksi WiFi lambat, sinyal lemah', 'normal', 'open', '2024-05-18', 0, FALSE),
(4, 3, 'TV tidak hidup, mungkin perlu servis', 'normal', 'in-progress', '2024-05-15', 200000, FALSE),
(13, 9, 'Air panas tidak keluar, water heater rusak', 'normal', 'open', '2024-05-22', 400000, TRUE),
(1, 1, 'Lampu utama di kamar mati, perlu ganti bohlam', 'normal', 'open', '2024-05-16', 100000, FALSE);

-- =====================================================
-- 10. INSERT DATA MAINTENANCE_HISTORY (2 records)
-- =====================================================

INSERT INTO maintenance_history (request_id, tanggal_mulai, tanggal_selesai, teknisi_nama, biaya_aktual, catatan, status) 
VALUES 
(1, '2024-05-16 08:00:00', NULL, 'Pak Bambang', NULL, 'Mulai perbaikan AC kompressor', 'in-progress'),
(4, '2024-05-08 10:00:00', '2024-05-10 14:30:00', 'Pak Doni', 350000, 'Sofa sudah diperbaiki dan dijahit rapi', 'completed');

-- =====================================================
-- DML INSERTION COMPLETE
-- =====================================================
-- Data Summary:
-- - 1 Kos
-- - 3 Tipe Kamar
-- - 10 Fasilitas
-- - 16 Kamar (unique nomor per lantai)
-- - 24 Penyewa (16 aktif, 5 non-aktif, 1 blacklist)
-- - 70+ Kamar-Fasilitas Relations
-- - 20 Kontrak Sewa (10 aktif, 3 berakhir, 1 dibatalkan)
-- - 23 Pembayaran (17 paid, 4 unpaid, 2 overdue)
-- - 9 Maintenance Requests
-- - 2 Maintenance History
-- =====================================================
