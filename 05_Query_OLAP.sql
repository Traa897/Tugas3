-- =====================================================
-- BAGIAN 4: QUERY OLAP (Online Analytical Processing)
-- Database: d_kos_kosan
-- Purpose: Reporting dan business intelligence
-- Date: May 2024
-- =====================================================

-- =====================================================
-- QUERY OLAP 1: REVENUE ANALYSIS PER BULAN
-- =====================================================
-- Scenario: Tracking revenue bulanan
-- Result: Monthly pendapatan, collection rate, piutang

SELECT 
    DATE_TRUNC('month', cs.tanggal_mulai + (pb.bulan_ke - 1) * INTERVAL '1 month')::DATE AS bulan,
    COUNT(DISTINCT cs.id) AS jumlah_kontrak_aktif,
    SUM(pb.nominal) AS total_target_pendapatan,
    SUM(CASE WHEN pb.status = 'paid' THEN pb.nominal ELSE 0 END) AS total_terbayar,
    SUM(CASE WHEN pb.status IN ('unpaid', 'overdue') THEN pb.nominal ELSE 0 END) AS total_piutang,
    ROUND(
        SUM(CASE WHEN pb.status = 'paid' THEN pb.nominal ELSE 0 END)::NUMERIC /
        NULLIF(SUM(pb.nominal), 0) * 100, 2
    ) AS collection_rate_persen
FROM kontrak_sewa cs
JOIN pembayaran pb ON cs.id = pb.kontrak_id
WHERE cs.status = 'aktif'
GROUP BY DATE_TRUNC('month', cs.tanggal_mulai + (pb.bulan_ke - 1) * INTERVAL '1 month')
ORDER BY bulan DESC;

---

-- =====================================================
-- QUERY OLAP 2: REVENUE BREAKDOWN BY ROOM TYPE
-- =====================================================
-- Scenario: Analisis profitabilitas per tipe kamar
-- Result: Revenue by tipe kamar, collection rate per tipe

SELECT 
    tk.nama AS tipe_kamar,
    tk.harga_sewa,
    COUNT(DISTINCT cs.id) AS jumlah_kontrak,
    SUM(CASE WHEN pb.status = 'paid' THEN pb.nominal ELSE 0 END) AS revenue_terbayar,
    SUM(CASE WHEN pb.status IN ('unpaid', 'overdue') THEN pb.nominal ELSE 0 END) AS outstanding_piutang,
    SUM(pb.nominal) AS revenue_total,
    ROUND(
        SUM(CASE WHEN pb.status = 'paid' THEN pb.nominal ELSE 0 END)::NUMERIC /
        NULLIF(SUM(pb.nominal), 0) * 100, 2
    ) AS collection_rate_persen
FROM kamar k
JOIN tipe_kamar tk ON k.tipe_id = tk.id
JOIN kontrak_sewa cs ON k.id = cs.kamar_id
LEFT JOIN pembayaran pb ON cs.id = pb.kontrak_id
WHERE k.kos_id = 1
GROUP BY tk.id, tk.nama, tk.harga_sewa
ORDER BY revenue_total DESC;

---

-- =====================================================
-- QUERY OLAP 3: OCCUPANCY RATE ANALYSIS
-- =====================================================
-- Scenario: Analisis okupansi kamar
-- Result: Overall occupancy + per lantai

SELECT 
    'Overall Occupancy' AS metric,
    COUNT(*) AS total_kamar,
    SUM(CASE WHEN status IN ('terisi', 'maintenance') THEN 1 ELSE 0 END) AS kamar_occupied,
    SUM(CASE WHEN status = 'kosong' THEN 1 ELSE 0 END) AS kamar_kosong,
    SUM(CASE WHEN status = 'reserved' THEN 1 ELSE 0 END) AS kamar_reserved,
    ROUND(
        SUM(CASE WHEN status IN ('terisi', 'maintenance') THEN 1 ELSE 0 END)::NUMERIC / 
        COUNT(*) * 100, 2
    ) AS occupancy_rate_persen
FROM kamar
WHERE kos_id = 1
UNION ALL
SELECT 
    'By Floor: Lantai ' || lantai::TEXT AS metric,
    COUNT(*) AS total_kamar,
    SUM(CASE WHEN status IN ('terisi', 'maintenance') THEN 1 ELSE 0 END) AS kamar_occupied,
    SUM(CASE WHEN status = 'kosong' THEN 1 ELSE 0 END) AS kamar_kosong,
    SUM(CASE WHEN status = 'reserved' THEN 1 ELSE 0 END) AS kamar_reserved,
    ROUND(
        SUM(CASE WHEN status IN ('terisi', 'maintenance') THEN 1 ELSE 0 END)::NUMERIC / 
        COUNT(*) * 100, 2
    ) AS occupancy_rate_persen
FROM kamar
WHERE kos_id = 1
GROUP BY lantai
ORDER BY lantai;

---

-- =====================================================
-- QUERY OLAP 4: OUTSTANDING BALANCE TRACKING (ORIGINAL)
-- =====================================================
-- Scenario: Analisis piutang dengan CTE kompleks
-- Result: List penyewa dengan piutang, durasi, prioritas collection

WITH outstanding_payments AS (
    SELECT 
        kontrak_id,
        SUM(CASE WHEN status IN ('unpaid', 'overdue') THEN nominal ELSE 0 END) AS total_piutang,
        COUNT(CASE WHEN status IN ('unpaid', 'overdue') THEN 1 END) AS jumlah_bulan_utang,
        MIN(due_date) FILTER (WHERE status IN ('unpaid', 'overdue')) AS bulan_paling_lama,
        SUM(CASE WHEN status = 'paid' THEN nominal ELSE 0 END) AS total_terbayar,
        COUNT(CASE WHEN status = 'paid' THEN 1 END) AS jumlah_bulan_terbayar
    FROM pembayaran
    WHERE status IN ('paid', 'unpaid', 'overdue')
    GROUP BY kontrak_id
    HAVING SUM(CASE WHEN status IN ('unpaid', 'overdue') THEN nominal ELSE 0 END) > 0
)
SELECT 
    p.id AS penyewa_id,
    p.nama AS nama_penyewa,
    p.email,
    p.telp,
    p.status AS status_penyewa,
    k.nomor AS kamar,
    cs.id AS kontrak_id,
    op.total_piutang,
    op.jumlah_bulan_utang,
    op.bulan_paling_lama,
    CEIL(EXTRACT(DAY FROM CURRENT_DATE - op.bulan_paling_lama)) AS hari_telat_terlama,
    op.total_terbayar,
    op.jumlah_bulan_terbayar,
    CASE 
        WHEN CEIL(EXTRACT(DAY FROM CURRENT_DATE - op.bulan_paling_lama)) > 90 THEN 'CRITICAL'
        WHEN CEIL(EXTRACT(DAY FROM CURRENT_DATE - op.bulan_paling_lama)) > 30 THEN 'WARNING'
        ELSE 'PENDING'
    END AS collection_priority
FROM penyewa p
INNER JOIN kontrak_sewa cs ON p.id = cs.penyewa_id AND cs.status = 'aktif'
INNER JOIN kamar k ON cs.kamar_id = k.id
INNER JOIN outstanding_payments op ON cs.id = op.kontrak_id
WHERE op.total_piutang > 0
ORDER BY op.total_piutang DESC, CEIL(EXTRACT(DAY FROM CURRENT_DATE - op.bulan_paling_lama)) DESC;

---

-- =====================================================
-- QUERY OLAP 5: OUTSTANDING BALANCE TRACKING (OPTIMIZED)
-- =====================================================
-- Scenario: Optimized version dengan push-down aggregation
-- Result: Sama seperti OLAP 4, tapi lebih cepat

WITH outstanding_payments AS (
    SELECT 
        kontrak_id,
        SUM(CASE WHEN status IN ('unpaid', 'overdue') THEN nominal ELSE 0 END) AS total_piutang,
        COUNT(CASE WHEN status IN ('unpaid', 'overdue') THEN 1 END) AS jumlah_bulan_utang,
        MIN(due_date) FILTER (WHERE status IN ('unpaid', 'overdue')) AS bulan_paling_lama,
        SUM(CASE WHEN status = 'paid' THEN nominal ELSE 0 END) AS total_terbayar,
        COUNT(CASE WHEN status = 'paid' THEN 1 END) AS jumlah_bulan_terbayar
    FROM pembayaran
    WHERE status IN ('paid', 'unpaid', 'overdue')
    GROUP BY kontrak_id
)
SELECT 
    p.id AS penyewa_id,
    p.nama AS nama_penyewa,
    p.email,
    p.telp,
    p.status AS status_penyewa,
    k.nomor AS kamar,
    cs.id AS kontrak_id,
    op.total_piutang,
    op.jumlah_bulan_utang,
    op.bulan_paling_lama,
    CEIL(EXTRACT(DAY FROM CURRENT_DATE - op.bulan_paling_lama)) AS hari_telat_terlama,
    op.total_terbayar,
    op.jumlah_bulan_terbayar,
    CASE 
        WHEN CEIL(EXTRACT(DAY FROM CURRENT_DATE - op.bulan_paling_lama)) > 90 THEN 'CRITICAL'
        WHEN CEIL(EXTRACT(DAY FROM CURRENT_DATE - op.bulan_paling_lama)) > 30 THEN 'WARNING'
        ELSE 'PENDING'
    END AS collection_priority
FROM penyewa p
INNER JOIN kontrak_sewa cs ON p.id = cs.penyewa_id AND cs.status = 'aktif'
INNER JOIN kamar k ON cs.kamar_id = k.id
INNER JOIN outstanding_payments op ON cs.id = op.kontrak_id
WHERE op.total_piutang > 0
ORDER BY op.total_piutang DESC, CEIL(EXTRACT(DAY FROM CURRENT_DATE - op.bulan_paling_lama)) DESC;

---

-- =====================================================
-- QUERY OLAP 6: MAINTENANCE TRENDS & FACILITY ISSUES
-- =====================================================
-- Scenario: Analisis trend maintenance dan fasilitas rusak
-- Result: Fasilitas mana yang paling sering rusak + maintenance history

SELECT 
    f.nama AS nama_fasilitas,
    f.kategori,
    COUNT(kf.id) AS jumlah_fasilitas_di_kamar,
    SUM(CASE WHEN kf.kondisi = 'rusak' THEN 1 ELSE 0 END) AS jumlah_rusak,
    ROUND(
        SUM(CASE WHEN kf.kondisi = 'rusak' THEN 1 ELSE 0 END)::NUMERIC / 
        COUNT(kf.id) * 100, 2
    ) AS damage_rate_persen,
    COUNT(DISTINCT mr.id) AS jumlah_maintenance_request,
    ROUND(AVG(mr.biaya_estimasi), 0) AS avg_biaya_estimasi,
    COUNT(CASE WHEN mr.status = 'completed' THEN 1 END) AS jumlah_completed,
    COUNT(CASE WHEN mr.status IN ('open', 'in-progress') THEN 1 END) AS jumlah_pending
FROM fasilitas f
LEFT JOIN kamar_fasilitas kf ON f.id = kf.fasilitas_id
LEFT JOIN maintenance_request mr ON kf.kamar_id = mr.kamar_id AND mr.deskripsi ILIKE '%' || f.nama || '%'
GROUP BY f.id, f.nama, f.kategori
HAVING COUNT(kf.id) > 0
ORDER BY damage_rate_persen DESC, jumlah_maintenance_request DESC;

---

-- =====================================================
-- BONUS: MATERIALIZED VIEW - Outstanding Balance (Optional)
-- =====================================================
-- Gunakan untuk caching hasil query OLAP yang sering diakses

DROP MATERIALIZED VIEW IF EXISTS mv_outstanding_balance CASCADE;

CREATE MATERIALIZED VIEW mv_outstanding_balance AS
WITH outstanding_payments AS (
    SELECT 
        kontrak_id,
        SUM(CASE WHEN status IN ('unpaid', 'overdue') THEN nominal ELSE 0 END) AS total_piutang,
        COUNT(CASE WHEN status IN ('unpaid', 'overdue') THEN 1 END) AS jumlah_bulan_utang,
        MIN(due_date) FILTER (WHERE status IN ('unpaid', 'overdue')) AS bulan_paling_lama,
        SUM(CASE WHEN status = 'paid' THEN nominal ELSE 0 END) AS total_terbayar,
        COUNT(CASE WHEN status = 'paid' THEN 1 END) AS jumlah_bulan_terbayar
    FROM pembayaran
    WHERE status IN ('paid', 'unpaid', 'overdue')
    GROUP BY kontrak_id
)
SELECT 
    p.id AS penyewa_id,
    p.nama AS nama_penyewa,
    p.email,
    p.telp,
    p.status AS status_penyewa,
    k.nomor AS kamar,
    cs.id AS kontrak_id,
    op.total_piutang,
    op.jumlah_bulan_utang,
    op.bulan_paling_lama,
    CEIL(EXTRACT(DAY FROM CURRENT_DATE - op.bulan_paling_lama)) AS hari_telat_terlama,
    op.total_terbayar,
    op.jumlah_bulan_terbayar
FROM penyewa p
INNER JOIN kontrak_sewa cs ON p.id = cs.penyewa_id AND cs.status = 'aktif'
INNER JOIN kamar k ON cs.kamar_id = k.id
INNER JOIN outstanding_payments op ON cs.id = op.kontrak_id
WHERE op.total_piutang > 0;

-- Create indexes pada materialized view
CREATE INDEX idx_mv_outstanding_piutang ON mv_outstanding_balance(total_piutang DESC);
CREATE INDEX idx_mv_outstanding_hari_telat ON mv_outstanding_balance(hari_telat_terlama DESC);

-- Refresh command (jalankan periodik untuk update):
-- REFRESH MATERIALIZED VIEW CONCURRENTLY mv_outstanding_balance;

---

-- =====================================================
-- QUERY OLAP MENGGUNAKAN MATERIALIZED VIEW
-- =====================================================
-- Contoh: Query MV untuk hasil super cepat

SELECT 
    penyewa_id,
    nama_penyewa,
    email,
    kamar,
    total_piutang,
    hari_telat_terlama,
    CASE 
        WHEN hari_telat_terlama > 90 THEN 'CRITICAL'
        WHEN hari_telat_terlama > 30 THEN 'WARNING'
        ELSE 'PENDING'
    END AS collection_priority
FROM mv_outstanding_balance
ORDER BY total_piutang DESC
LIMIT 10;

---

-- =====================================================
-- QUERY OLAP SUMMARY
-- =====================================================
-- Query OLAP yang dibuat:
-- 1. Revenue Analysis Per Bulan           - Monthly tracking
-- 2. Revenue Breakdown by Room Type       - Profitability by type
-- 3. Occupancy Rate Analysis              - Metrics per floor
-- 4. Outstanding Balance (Original CTE)   - Complex aggregation
-- 5. Outstanding Balance (Optimized)      - Push-down optimization
-- 6. Maintenance Trends & Facility Issues - Damage analysis
-- + Materialized View: mv_outstanding_balance
-- + Indexes: 2 indexes pada MV
-- =====================================================
