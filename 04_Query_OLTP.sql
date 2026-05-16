-- =====================================================
-- BAGIAN 3.3: QUERY OLTP (Online Transaction Processing)
-- Transaksi harian untuk operasional kos-kosan
-- =====================================================

-- =====================================================
-- QUERY OLTP 1: CHECKIN PENYEWA BARU (Example dengan data existing)
-- =====================================================
-- Scenario: Penyewa baru datang, kita perlu:
-- 1. Insert data penyewa
-- 2. Update status kamar menjadi 'terisi'
-- 3. Insert kontrak sewa
-- Trigger akan auto-create pembayaran

BEGIN;

-- Step 1: Insert penyewa baru (dengan KTP unik)
-- Gunakan KTP yang belum ada di database
INSERT INTO penyewa (kos_id, nama, email, telp, ktp, status)
VALUES 
(1, 'Reza Muhammad', 'reza.m@email.com', '081988776655', '3271022001150999', 'aktif')
ON CONFLICT (ktp) DO NOTHING;

-- Step 2: Check apakah penyewa sudah ada
-- Ambil penyewa yang baru di-insert atau yang sudah ada dengan KTP tersebut
WITH target_penyewa AS (
    SELECT id FROM penyewa WHERE ktp = '3271022001150999' LIMIT 1
)

-- Step 3: Insert kontrak sewa dengan kamar kosong
INSERT INTO kontrak_sewa (kamar_id, penyewa_id, tanggal_mulai, durasi_bulan, harga_per_bulan, deposit, status)
SELECT 
    (SELECT id FROM kamar WHERE nomor = '103' LIMIT 1),
    tp.id,
    '2024-05-15'::DATE,
    6,
    1500000,
    3000000,
    'aktif'
FROM target_penyewa tp
WHERE NOT EXISTS (
    SELECT 1 FROM kontrak_sewa 
    WHERE penyewa_id = tp.id AND kamar_id = (SELECT id FROM kamar WHERE nomor = '103' LIMIT 1)
);

-- Step 4: Update status kamar jadi terisi
UPDATE kamar SET status = 'terisi' WHERE nomor = '103' AND status != 'terisi';

COMMIT;

-- Verify data terbaru (jalankan setelah commit):
-- SELECT * FROM penyewa WHERE ktp = '3271022001150999';
-- SELECT * FROM kontrak_sewa ORDER BY id DESC LIMIT 1;
-- SELECT * FROM kamar WHERE nomor = '103';
-- SELECT * FROM pembayaran WHERE kontrak_id IN (SELECT id FROM kontrak_sewa ORDER BY id DESC LIMIT 1);

---

-- =====================================================
-- QUERY OLTP 2: PROSES PEMBAYARAN SEWA
-- =====================================================
-- Scenario: Penyewa membayar sewa bulanan
-- Kita update pembayaran status dari unpaid → paid

-- Update pembayaran Ahmad Rizki untuk bulan 5 (yang overdue)
UPDATE pembayaran
SET 
    status = 'paid',
    tanggal_bayar = CURRENT_DATE,
    metode_bayar = 'transfer',
    bukti_bayar = '{"bank": "BCA", "no_ref": "20240505123456"}'
WHERE 
    kontrak_id = 1 
    AND bulan_ke = 5;

-- Verify pembayaran
SELECT 
    p.id,
    p.bulan_ke,
    p.nominal,
    p.due_date,
    p.status,
    p.tanggal_bayar
FROM pembayaran p
WHERE kontrak_id = 1
ORDER BY bulan_ke;

---

-- =====================================================
-- QUERY OLTP 3: LAPOR KELUHAN MAINTENANCE
-- =====================================================
-- Scenario: Penyewa lapor fasilitas rusak

-- Insert maintenance request dari penyewa
INSERT INTO maintenance_request 
(kamar_id, penyewa_id, deskripsi, kategori, status, tanggal_target_selesai, ditanggung_penyewa)
VALUES 
(1, 1, 'Pintu kamar susah ditutup, perlu diperbaiki engselnya', 'normal', 'open', 
 CURRENT_DATE + INTERVAL '5 days', FALSE);

-- Verify maintenance request
SELECT 
    mr.id,
    k.nomor,
    p.nama,
    mr.deskripsi,
    mr.status,
    mr.tanggal_lapor
FROM maintenance_request mr
JOIN kamar k ON mr.kamar_id = k.id
JOIN penyewa p ON mr.penyewa_id = p.id
WHERE mr.kamar_id = 1
ORDER BY mr.tanggal_lapor DESC;

---

-- =====================================================
-- QUERY OLTP 4: UPDATE STATUS KAMAR KE MAINTENANCE
-- =====================================================
-- Scenario: Teknisi mulai perbaikan kamar

BEGIN;

-- Update status kamar ke maintenance
UPDATE kamar SET status = 'maintenance' WHERE id = 9;

-- Insert maintenance history (tracking perbaikan)
INSERT INTO maintenance_history 
(request_id, tanggal_mulai, catatan, teknisi_nama, status)
VALUES 
(1, CURRENT_TIMESTAMP, 'Mulai perbaikan AC kompressor', 'Pak Bambang', 'in-progress');

-- Update status request ke in-progress
UPDATE maintenance_request 
SET status = 'in-progress' 
WHERE id = 1;

COMMIT;

---

-- =====================================================
-- QUERY OLTP 5: CHECKOUT PENYEWA DAN UPDATE KAMAR KOSONG
-- =====================================================
-- Scenario: Penyewa checkout, kita perlu:
-- 1. Update kontrak status → berakhir
-- 2. Hitung potongan deposit (jika ada)
-- 3. Update kamar status → kosong
-- 4. Insert maintenance request untuk renovation

BEGIN;

-- Step 1: Update kontrak (penyewa Lina Kusuma yang sudah checked out sebelumnya)
-- Untuk contoh, kita update kontrak yang sudah berakhir
-- (Dalam praktik real-time, update saat checkout)

-- Step 2: Calculate potongan deposit jika ada kerusakan
UPDATE kontrak_sewa 
SET 
    potongan_deposit = 0,  -- Tidak ada kerusakan
    status = 'berakhir'
WHERE id = 11;  -- Kontrak Lina Kusuma

-- Step 3: Update status kamar → kosong
UPDATE kamar SET status = 'kosong' WHERE id = 1;

-- Step 4: Insert maintenance request untuk cleaning/renovation
INSERT INTO maintenance_request 
(kamar_id, penyewa_id, deskripsi, kategori, status, ditanggung_penyewa)
VALUES 
(1, NULL, 'Cleaning dan renovation setelah checkout penyewa', 'normal', 'open', FALSE);

COMMIT;

---

-- =====================================================
-- QUERY OLTP 6: CARI KAMAR YANG TERSEDIA UNTUK BOOKING
-- =====================================================
-- Scenario: Calon penyewa cari kamar kosong dengan kriteria tertentu

SELECT 
    k.id,
    k.nomor,
    tk.nama as tipe_kamar,
    tk.harga_sewa,
    k.luas,
    k.lantai,
    k.status,
    COALESCE(STRING_AGG(f.nama, ', '), 'N/A') as fasilitas
FROM kamar k
JOIN tipe_kamar tk ON k.tipe_id = tk.id
LEFT JOIN kamar_fasilitas kf ON k.id = kf.kamar_id
LEFT JOIN fasilitas f ON kf.fasilitas_id = f.id
WHERE 
    k.kos_id = 1
    AND k.status IN ('kosong', 'reserved')
    AND tk.harga_sewa <= 2500000  -- Filter by budget
GROUP BY k.id, k.nomor, tk.nama, tk.harga_sewa, k.luas, k.lantai, k.status
ORDER BY tk.harga_sewa ASC, k.lantai ASC;

---

-- =====================================================
-- QUERY OLTP 7: GET KAMAR DENGAN FASILITAS DETAIL
-- =====================================================
-- Scenario: Admin/calon penyewa lihat detail kamar + fasilitas

SELECT 
    k.id,
    k.nomor,
    tk.nama as tipe_kamar,
    tk.harga_sewa,
    k.luas,
    k.lantai,
    k.status,
    json_array_length(tk.fasilitas_included) as jumlah_fasilitas_included,
    f.nama as nama_fasilitas,
    f.kategori as kategori_fasilitas,
    kf.kondisi as kondisi_fasilitas,
    f.harga_premium
FROM kamar k
JOIN tipe_kamar tk ON k.tipe_id = tk.id
LEFT JOIN kamar_fasilitas kf ON k.id = kf.kamar_id
LEFT JOIN fasilitas f ON kf.fasilitas_id = f.id
WHERE k.nomor = '101'
ORDER BY f.kategori, f.nama;

---

-- =====================================================
-- QUERY OLTP 8: KONTROL PEMBAYARAN PIUTANG
-- =====================================================
-- Scenario: Setiap hari, cek pembayaran mana yang overdue

SELECT 
    p.id,
    p.kontrak_id,
    cs.id as kontrak_sewa_id,
    pen.nama as penyewa,
    k.nomor as kamar,
    p.bulan_ke,
    p.nominal,
    p.due_date,
    CEIL(EXTRACT(DAY FROM CURRENT_DATE - p.due_date)) as hari_telat,
    CASE 
        WHEN p.status = 'paid' THEN 'LUNAS'
        WHEN CURRENT_DATE > p.due_date THEN 'OVERDUE'
        ELSE 'PENDING'
    END as status_pembayaran
FROM pembayaran p
JOIN kontrak_sewa cs ON p.kontrak_id = cs.id
JOIN penyewa pen ON cs.penyewa_id = pen.id
JOIN kamar k ON cs.kamar_id = k.id
WHERE 
    p.status IN ('unpaid', 'overdue')
    AND cs.status = 'aktif'
ORDER BY p.due_date ASC;

---

-- =====================================================
-- QUERY OLTP 9: LIHAT MAINTENANCE REQUEST YANG BELUM SELESAI
-- =====================================================
-- Scenario: Koordinator maintenance lihat job yang perlu dikerjakan

SELECT 
    mr.id,
    k.nomor as kamar,
    p.nama as penyewa,
    mr.deskripsi,
    mr.kategori,
    mr.status,
    mr.tanggal_lapor,
    mr.tanggal_target_selesai,
    CEIL(EXTRACT(DAY FROM CURRENT_DATE - mr.tanggal_lapor)) as lama_menunggu,
    mr.biaya_estimasi,
    mr.ditanggung_penyewa
FROM maintenance_request mr
JOIN kamar k ON mr.kamar_id = k.id
LEFT JOIN penyewa p ON mr.penyewa_id = p.id
WHERE mr.status IN ('open', 'in-progress')
ORDER BY 
    mr.kategori DESC,  -- Urgent first
    mr.tanggal_lapor ASC;

---

-- =====================================================
-- QUERY OLTP 10: MARK MAINTENANCE COMPLETE
-- =====================================================
-- Scenario: Teknisi report perbaikan selesai

BEGIN;

-- Update maintenance history: set tanggal_selesai
UPDATE maintenance_history
SET 
    tanggal_selesai = CURRENT_TIMESTAMP,
    biaya_aktual = 450000,
    catatan = 'AC sudah diperbaiki, pendingin berfungsi normal',
    status = 'completed'
WHERE request_id = 1
  AND status = 'in-progress';

-- Update maintenance request: set status completed
UPDATE maintenance_request
SET status = 'completed'
WHERE id = 1;

-- Update kamar: ubah status dari maintenance ke kosong
UPDATE kamar SET status = 'kosong' WHERE id = 9;

COMMIT;

---

-- =====================================================
-- QUERY OLTP SUMMARY
-- =====================================================
-- Query OLTP yang dibuat:
-- 1. Checkin Penyewa Baru (INSERT + UPDATE)
-- 2. Proses Pembayaran (UPDATE + SELECT)
-- 3. Lapor Keluhan Maintenance (INSERT + SELECT)
-- 4. Update Status Kamar ke Maintenance (UPDATE multi-table)
-- 5. Checkout Penyewa (UPDATE + INSERT)
-- 6. Cari Kamar Kosong (SELECT dengan JOIN + FILTER)
-- 7. Detail Kamar dengan Fasilitas (SELECT dengan LEFT JOIN)
-- 8. Kontrol Pembayaran Piutang (SELECT dengan CASE)
-- 9. List Maintenance yang Pending (SELECT dengan JOIN)
-- 10. Mark Maintenance Complete (UPDATE multi-table)

-- Semua query relatif simple, focused pada operasional harian.
