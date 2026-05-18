-- =====================================================
-- BAGIAN 3.3: QUERY OLTP (Online Transaction Processing)
-- Database: d_kos_kosan
-- Purpose: Transaksi harian untuk operasional kos-kosan
-- Date: May 2024
-- =====================================================

-- =====================================================
-- CLEANUP: RESET OLTP TEST DATA (Optional - sebelum re-run Query 1)
-- =====================================================

-- Uncomment jika ingin reset data sebelum re-run
/*
ROLLBACK;
DELETE FROM maintenance_history WHERE request_id IN (SELECT id FROM maintenance_request WHERE penyewa_id IN (SELECT id FROM penyewa WHERE ktp LIKE '327102200115%'));
DELETE FROM maintenance_request WHERE penyewa_id IN (SELECT id FROM penyewa WHERE ktp LIKE '327102200115%');
DELETE FROM pembayaran WHERE kontrak_id IN (SELECT id FROM kontrak_sewa WHERE penyewa_id IN (SELECT id FROM penyewa WHERE ktp LIKE '327102200115%'));
DELETE FROM kontrak_sewa WHERE penyewa_id IN (SELECT id FROM penyewa WHERE ktp LIKE '327102200115%');
DELETE FROM penyewa WHERE ktp LIKE '327102200115%';
UPDATE kamar SET status = 'kosong' WHERE id = 1;
UPDATE kamar SET status = 'maintenance' WHERE id = 9;
UPDATE kamar SET status = 'kosong' WHERE id = 3;
*/

-- =====================================================
-- QUERY OLTP 1: CHECKIN PENYEWA BARU
-- =====================================================
-- Scenario: Penyewa baru checkin dengan kamar 103
-- Expected: Penyewa baru + Kontrak + Pembayaran auto-create + Kamar jadi terisi

BEGIN;

-- Step 1: Insert penyewa baru (dengan KTP unik)
INSERT INTO penyewa (kos_id, nama, email, telp, ktp, status)
VALUES (1, 'Reza Muhammad', 'reza.m@email.com', '081988776655', '3271022001150999', 'aktif')
ON CONFLICT (ktp) DO NOTHING;

-- Step 2: Insert kontrak sewa (trigger auto-create pembayaran)
INSERT INTO kontrak_sewa (kamar_id, penyewa_id, tanggal_mulai, durasi_bulan, harga_per_bulan, deposit, status)
SELECT
    k.id,
    p.id,
    '2024-05-15'::DATE,
    6,
    1500000,
    3000000,
    'aktif'
FROM kamar k
CROSS JOIN penyewa p
WHERE k.nomor = '103'
  AND p.ktp = '3271022001150999'
  AND NOT EXISTS (
      SELECT 1 FROM kontrak_sewa cs
      WHERE cs.penyewa_id = p.id
        AND cs.kamar_id = k.id
        AND cs.status = 'aktif'
  );

-- Step 3: Update kamar jadi terisi
UPDATE kamar
SET status = 'terisi'
WHERE nomor = '103'
  AND status != 'terisi';

COMMIT;

-- Verify Query 1:
SELECT 'Penyewa baru:' AS info, id, nama, status FROM penyewa WHERE ktp = '3271022001150999'
UNION ALL
SELECT 'Kamar 103:', id, nomor, status FROM kamar WHERE nomor = '103';

---

-- =====================================================
-- QUERY OLTP 2: PROSES PEMBAYARAN SEWA
-- =====================================================
-- Scenario: Ahmad Rizki (kontrak_id=1) bayar sewa bulan ke-5
-- Expected: Status pembayaran berubah dari unpaid/overdue jadi paid

UPDATE pembayaran
SET
    status       = 'paid',
    tanggal_bayar = CURRENT_DATE,
    metode_bayar  = 'transfer',
    bukti_bayar   = '{"bank": "BCA", "no_ref": "20240505123456"}'::JSONB
WHERE kontrak_id = 1
  AND bulan_ke   = 5
  AND status    != 'paid';

-- Verify Query 2:
SELECT
    pb.id,
    pb.bulan_ke,
    pb.nominal,
    pb.due_date,
    pb.status,
    pb.tanggal_bayar,
    pb.metode_bayar
FROM pembayaran pb
WHERE pb.kontrak_id = 1
ORDER BY pb.bulan_ke;

---

-- =====================================================
-- QUERY OLTP 3: LAPOR KELUHAN MAINTENANCE
-- =====================================================
-- Scenario: Ahmad Rizki (kamar_id=1, penyewa_id=1) lapor pintu rusak
-- Expected: Maintenance request baru dengan status 'open'

INSERT INTO maintenance_request
    (kamar_id, penyewa_id, deskripsi, kategori, status, tanggal_target_selesai, ditanggung_penyewa)
VALUES
    (1, 1, 'Pintu kamar susah ditutup, perlu diperbaiki engselnya', 'normal', 'open',
     CURRENT_DATE + INTERVAL '5 days', FALSE);

-- Verify Query 3:
SELECT
    mr.id,
    k.nomor   AS kamar,
    p.nama    AS penyewa,
    mr.deskripsi,
    mr.kategori,
    mr.status,
    mr.tanggal_lapor,
    mr.tanggal_target_selesai
FROM maintenance_request mr
JOIN kamar   k ON mr.kamar_id   = k.id
JOIN penyewa p ON mr.penyewa_id = p.id
WHERE mr.kamar_id = 1
ORDER BY mr.tanggal_lapor DESC;

---

-- =====================================================
-- QUERY OLTP 4: MULAI PERBAIKAN - UPDATE STATUS KE MAINTENANCE
-- =====================================================
-- Scenario: Teknisi mulai perbaikan AC kamar 303 (kamar_id=9, request_id=1)
-- Expected: Kamar status maintenance + history created + request status in-progress

BEGIN;

-- Update status kamar ke maintenance
UPDATE kamar
SET status = 'maintenance'
WHERE id = 9;

-- Insert maintenance history (tracking pekerjaan teknisi)
INSERT INTO maintenance_history
    (request_id, tanggal_mulai, catatan, teknisi_nama, status)
VALUES
    (1, CURRENT_TIMESTAMP, 'Mulai perbaikan AC kompressor', 'Pak Bambang', 'in-progress');

-- Update status request ke in-progress
UPDATE maintenance_request
SET status = 'in-progress'
WHERE id   = 1
  AND status = 'open';

COMMIT;

-- Verify Query 4:
SELECT k.nomor, k.status, mr.status AS req_status, mh.teknisi_nama, mh.tanggal_mulai
FROM kamar k
JOIN maintenance_request mr ON mr.kamar_id = k.id
JOIN maintenance_history mh ON mh.request_id = mr.id
WHERE k.id = 9
ORDER BY mh.id DESC
LIMIT 1;

---

-- =====================================================
-- QUERY OLTP 5: CHECKOUT PENYEWA DAN UPDATE KAMAR KOSONG
-- =====================================================
-- Scenario: Lina Kusuma (kontrak_id=11, kamar_id=1) checkout
-- Expected: Kontrak berakhir + kamar kosong + maintenance cleaning request

BEGIN;

-- Step 1: Update kontrak → berakhir
UPDATE kontrak_sewa
SET
    potongan_deposit = 0,
    status           = 'berakhir'
WHERE id = 11
  AND status != 'berakhir';

-- Step 2: Update kamar → kosong
UPDATE kamar
SET status = 'kosong'
WHERE id = 1
  AND NOT EXISTS (
      SELECT 1 FROM kontrak_sewa cs
      WHERE cs.kamar_id = 1
        AND cs.status = 'aktif'
  );

-- Step 3: Insert maintenance request untuk cleaning
INSERT INTO maintenance_request
    (kamar_id, penyewa_id, deskripsi, kategori, status, ditanggung_penyewa)
VALUES
    (1, NULL, 'Cleaning dan renovation setelah checkout penyewa', 'normal', 'open', FALSE);

COMMIT;

-- Verify Query 5:
SELECT cs.id, cs.status, cs.potongan_deposit FROM kontrak_sewa cs WHERE cs.id = 11;
SELECT k.nomor, k.status FROM kamar k WHERE k.id = 1;

---

-- =====================================================
-- QUERY OLTP 6: CARI KAMAR YANG TERSEDIA UNTUK BOOKING
-- =====================================================
-- Scenario: Calon penyewa cari kamar kosong, budget max Rp 2.500.000
-- Expected: List kamar yang kosong/reserved dengan harga <= 2.5M + fasilitas

SELECT
    k.id,
    k.nomor,
    tk.nama          AS tipe_kamar,
    tk.harga_sewa,
    k.luas,
    k.lantai,
    k.status,
    COALESCE(STRING_AGG(f.nama, ', ' ORDER BY f.nama), 'N/A') AS fasilitas
FROM kamar k
JOIN tipe_kamar tk ON k.tipe_id = tk.id
LEFT JOIN kamar_fasilitas kf ON k.id = kf.kamar_id AND kf.kondisi = 'baik'
LEFT JOIN fasilitas f        ON kf.fasilitas_id = f.id
WHERE k.kos_id       = 1
  AND k.status        IN ('kosong', 'reserved')
  AND tk.harga_sewa  <= 2500000
GROUP BY k.id, k.nomor, tk.nama, tk.harga_sewa, k.luas, k.lantai, k.status
ORDER BY tk.harga_sewa ASC, k.lantai ASC;

---

-- =====================================================
-- QUERY OLTP 7: DETAIL KAMAR DENGAN FASILITAS
-- =====================================================
-- Scenario: Admin/calon penyewa lihat detail kamar 101 + semua fasilitas
-- Expected: Kamar 101 + list fasilitas beserta kondisinya

SELECT
    k.id,
    k.nomor,
    tk.nama              AS tipe_kamar,
    tk.harga_sewa,
    k.luas,
    k.lantai,
    k.status,
    f.nama               AS nama_fasilitas,
    f.kategori           AS kategori_fasilitas,
    kf.kondisi           AS kondisi_fasilitas,
    f.harga_premium
FROM kamar k
JOIN tipe_kamar tk       ON k.tipe_id       = tk.id
LEFT JOIN kamar_fasilitas kf ON k.id        = kf.kamar_id
LEFT JOIN fasilitas f        ON kf.fasilitas_id = f.id
WHERE k.nomor = '101'
ORDER BY f.kategori, f.nama;

---

-- =====================================================
-- QUERY OLTP 8: KONTROL PEMBAYARAN PIUTANG HARIAN
-- =====================================================
-- Scenario: Cek setiap hari pembayaran mana yang overdue/belum dibayar
-- Expected: List pembayaran yang unpaid/overdue dengan durasi keterlambatan

SELECT
    pb.id,
    pb.kontrak_id,
    pen.nama                AS penyewa,
    k.nomor                 AS kamar,
    pb.bulan_ke,
    pb.nominal,
    pb.due_date,
    CEIL(EXTRACT(DAY FROM CURRENT_DATE - pb.due_date))::INT AS hari_telat,
    CASE
        WHEN pb.status = 'paid'              THEN 'LUNAS'
        WHEN CURRENT_DATE > pb.due_date      THEN 'OVERDUE'
        ELSE                                      'PENDING'
    END AS status_pembayaran
FROM pembayaran pb
JOIN kontrak_sewa cs ON pb.kontrak_id  = cs.id
JOIN penyewa pen      ON cs.penyewa_id = pen.id
JOIN kamar k          ON cs.kamar_id   = k.id
WHERE pb.status IN ('unpaid', 'overdue')
  AND cs.status = 'aktif'
ORDER BY pb.due_date ASC;

---

-- =====================================================
-- QUERY OLTP 9: LIST MAINTENANCE YANG BELUM SELESAI
-- =====================================================
-- Scenario: Koordinator lihat semua job maintenance pending/in-progress
-- Expected: Maintenance yang belum selesai, diurutkan by urgency + tanggal

SELECT
    mr.id,
    k.nomor                  AS kamar,
    p.nama                   AS penyewa,
    mr.deskripsi,
    mr.kategori,
    mr.status,
    mr.tanggal_lapor,
    mr.tanggal_target_selesai,
    CEIL(EXTRACT(DAY FROM CURRENT_DATE - mr.tanggal_lapor))::INT AS lama_menunggu,
    mr.biaya_estimasi,
    mr.ditanggung_penyewa
FROM maintenance_request mr
JOIN kamar k         ON mr.kamar_id   = k.id
LEFT JOIN penyewa p  ON mr.penyewa_id = p.id
WHERE mr.status IN ('open', 'in-progress')
ORDER BY
    CASE mr.kategori WHEN 'urgent' THEN 0 ELSE 1 END,
    mr.tanggal_lapor ASC;

---

-- =====================================================
-- QUERY OLTP 10: MARK MAINTENANCE COMPLETE
-- =====================================================
-- Scenario: Teknisi report perbaikan AC kamar 303 (request_id=1) selesai
-- Expected: History completed + request completed + kamar status kosong

BEGIN;

-- Update maintenance history: set tanggal_selesai
UPDATE maintenance_history
SET
    tanggal_selesai = CURRENT_TIMESTAMP,
    biaya_aktual    = 450000,
    catatan         = 'AC sudah diperbaiki, pendingin berfungsi normal',
    status          = 'completed'
WHERE request_id = 1
  AND status     = 'in-progress';

-- Update status maintenance request → completed
UPDATE maintenance_request
SET
    status       = 'completed',
    biaya_repair = 450000
WHERE id = 1
  AND status != 'completed';

-- Update kamar: ubah dari maintenance ke kosong
UPDATE kamar
SET status = 'kosong'
WHERE id = 9
  AND NOT EXISTS (
      SELECT 1 FROM kontrak_sewa cs
      WHERE cs.kamar_id = 9
        AND cs.status   = 'aktif'
  );

COMMIT;

-- Verify Query 10:
SELECT mr.id, mr.status, mr.biaya_repair,
       mh.status AS history_status, mh.biaya_aktual, mh.tanggal_selesai,
       k.status  AS kamar_status
FROM maintenance_request mr
JOIN maintenance_history mh ON mh.request_id = mr.id
JOIN kamar k                ON k.id          = mr.kamar_id
WHERE mr.id = 1
ORDER BY mh.id DESC
LIMIT 1;

---

-- =====================================================
-- QUERY OLTP SUMMARY
-- =====================================================
-- Query OLTP yang dibuat:
-- 1.  Checkin Penyewa Baru        - INSERT + UPDATE + TRIGGER auto-create
-- 2.  Proses Pembayaran           - UPDATE pembayaran status
-- 3.  Lapor Keluhan Maintenance   - INSERT maintenance request
-- 4.  Mulai Perbaikan Kamar       - UPDATE kamar + INSERT history
-- 5.  Checkout Penyewa            - UPDATE kontrak + kamar + INSERT cleaning
-- 6.  Cari Kamar Kosong           - SELECT dengan JOIN + FILTER
-- 7.  Detail Kamar + Fasilitas    - SELECT dengan LEFT JOIN
-- 8.  Kontrol Pembayaran Piutang  - SELECT dengan CASE WHEN
-- 9.  List Maintenance Pending    - SELECT dengan ORDER BY prioritas
-- 10. Mark Maintenance Complete   - UPDATE multi-table dalam transaksi
-- =====================================================
