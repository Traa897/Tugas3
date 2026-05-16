-- =====================================================
-- BAGIAN 3.4: QUERY OLAP (Online Analytical Processing)
-- Analytics dan Reporting untuk Business Intelligence
-- =====================================================

-- =====================================================
-- QUERY OLAP 1: REVENUE ANALYSIS - TOTAL PENDAPATAN BULANAN
-- =====================================================
-- Scenario: Lihat trend pendapatan per bulan, apa saja revenue/month

WITH monthly_revenue AS (
    SELECT 
        DATE_TRUNC('month', p.due_date)::DATE as bulan,
        SUM(CASE WHEN p.status = 'paid' THEN p.nominal ELSE 0 END) as revenue_terbayar,
        SUM(p.nominal) as revenue_target,
        COUNT(CASE WHEN p.status = 'paid' THEN 1 END) as jumlah_pembayaran_terbayar,
        COUNT(*) as jumlah_pembayaran_total
    FROM pembayaran p
    GROUP BY DATE_TRUNC('month', p.due_date)
)
SELECT 
    bulan,
    revenue_terbayar,
    revenue_target,
    revenue_target - revenue_terbayar as piutang,
    ROUND(100.0 * revenue_terbayar / NULLIF(revenue_target, 0), 2) as collection_rate_persen,
    jumlah_pembayaran_terbayar,
    jumlah_pembayaran_total
FROM monthly_revenue
ORDER BY bulan DESC;

---

-- =====================================================
-- QUERY OLAP 2: REVENUE BY KAMAR TYPE
-- =====================================================
-- Scenario: Kamar tipe mana yang paling menguntungkan?

SELECT 
    tk.id,
    tk.nama as tipe_kamar,
    tk.harga_sewa as harga_per_bulan,
    COUNT(DISTINCT k.id) as jumlah_kamar,
    COUNT(DISTINCT cs.id) as kontrak_aktif,
    SUM(CASE WHEN p.status = 'paid' THEN p.nominal ELSE 0 END) as total_revenue_terbayar,
    ROUND(AVG(CASE WHEN p.status = 'paid' THEN p.nominal ELSE NULL END), 0) as avg_payment,
    COUNT(CASE WHEN p.status IN ('unpaid', 'overdue') THEN 1 END) as piutang_count
FROM tipe_kamar tk
LEFT JOIN kamar k ON tk.id = k.tipe_id
LEFT JOIN kontrak_sewa cs ON k.id = cs.kamar_id AND cs.status = 'aktif'
LEFT JOIN pembayaran p ON cs.id = p.kontrak_id
WHERE tk.kos_id = 1
GROUP BY tk.id, tk.nama, tk.harga_sewa
ORDER BY total_revenue_terbayar DESC;

---

-- =====================================================
-- QUERY OLAP 3: OCCUPANCY RATE ANALYSIS
-- =====================================================
-- Scenario: Berapa % kamar yang terisi? Trend occupancy?

WITH kamar_status_count AS (
    SELECT 
        COUNT(CASE WHEN status = 'terisi' THEN 1 END) as kamar_terisi,
        COUNT(CASE WHEN status = 'kosong' THEN 1 END) as kamar_kosong,
        COUNT(CASE WHEN status = 'maintenance' THEN 1 END) as kamar_maintenance,
        COUNT(CASE WHEN status = 'reserved' THEN 1 END) as kamar_reserved,
        COUNT(*) as total_kamar
    FROM kamar
    WHERE kos_id = 1
)
SELECT 
    kamar_terisi,
    kamar_kosong,
    kamar_maintenance,
    kamar_reserved,
    total_kamar,
    ROUND(100.0 * kamar_terisi / total_kamar, 2) as occupancy_rate_persen,
    ROUND(100.0 * kamar_kosong / total_kamar, 2) as vacancy_rate_persen,
    CASE 
        WHEN ROUND(100.0 * kamar_terisi / total_kamar, 2) >= 80 THEN 'SANGAT BAIK'
        WHEN ROUND(100.0 * kamar_terisi / total_kamar, 2) >= 60 THEN 'BAIK'
        WHEN ROUND(100.0 * kamar_terisi / total_kamar, 2) >= 40 THEN 'CUKUP'
        ELSE 'PERLU IMPROVEMENT'
    END as occupancy_status
FROM kamar_status_count;

---

-- =====================================================
-- QUERY OLAP 4: KAMAR YANG SERING KOSONG
-- =====================================================
-- Scenario: Identifikasi kamar mana yang susah disewakan?

WITH kamar_history AS (
    SELECT 
        k.id,
        k.nomor,
        tk.nama as tipe_kamar,
        tk.harga_sewa,
        k.status,
        COUNT(cs.id) as jumlah_penyewa_total,
        COALESCE(AVG(cs.durasi_bulan), 0) as rata_rata_durasi_bulan,
        MAX(cs.tanggal_akhir) as terakhir_terisi_sampai,
        DATE_PART('day', CURRENT_DATE - MAX(cs.tanggal_akhir)) as hari_sejak_kosong
    FROM kamar k
    JOIN tipe_kamar tk ON k.tipe_id = tk.id
    LEFT JOIN kontrak_sewa cs ON k.id = cs.kamar_id
    WHERE k.kos_id = 1
    GROUP BY k.id, k.nomor, tk.nama, tk.harga_sewa, k.status
)
SELECT 
    id,
    nomor,
    tipe_kamar,
    harga_sewa,
    status,
    jumlah_penyewa_total,
    rata_rata_durasi_bulan,
    terakhir_terisi_sampai,
    COALESCE(CEIL(hari_sejak_kosong), -1) as hari_kosong,
    CASE 
        WHEN status = 'kosong' AND hari_sejak_kosong > 30 THEN 'CRITICAL - Perlu promo'
        WHEN status = 'kosong' AND hari_sejak_kosong > 7 THEN 'WARNING - Perlu update'
        WHEN status = 'kosong' THEN 'NORMAL'
        ELSE 'TERISI'
    END as status_penjualan
FROM kamar_history
ORDER BY 
    CASE WHEN status = 'kosong' THEN 0 ELSE 1 END,
    COALESCE(hari_sejak_kosong, -1) DESC;

---

-- =====================================================
-- QUERY OLAP 5: CUSTOMER SEGMENTATION - PENYEWA BERDASARKAN DURASI
-- =====================================================
-- Scenario: Identifikasi penyewa mana yang loyal, mana yang churn

WITH penyewa_duration AS (
    SELECT 
        p.id,
        p.nama,
        p.email,
        p.telp,
        p.status as status_penyewa,
        COUNT(cs.id) as jumlah_kontrak,
        SUM(cs.durasi_bulan) as total_durasi_tinggal_bulan,
        MAX(cs.tanggal_akhir) as terakhir_checkout,
        DATE_PART('month', CURRENT_DATE - MAX(cs.tanggal_akhir)) as bulan_sejak_checkout,
        ROUND(AVG(cs.durasi_bulan), 2) as rata_rata_durasi_kontrak
    FROM penyewa p
    LEFT JOIN kontrak_sewa cs ON p.id = cs.penyewa_id
    WHERE p.kos_id = 1
    GROUP BY p.id, p.nama, p.email, p.telp, p.status
)
SELECT 
    id,
    nama,
    email,
    telp,
    status_penyewa,
    jumlah_kontrak,
    total_durasi_tinggal_bulan,
    rata_rata_durasi_kontrak,
    CASE 
        WHEN status_penyewa = 'aktif' THEN 'CURRENT'
        WHEN bulan_sejak_checkout <= 3 THEN 'RECENT'
        WHEN bulan_sejak_checkout <= 12 THEN 'WITHIN_1_YEAR'
        ELSE 'OLD'
    END as customer_segment,
    CASE 
        WHEN total_durasi_tinggal_bulan >= 24 THEN 'LOYAL (2+ tahun)'
        WHEN total_durasi_tinggal_bulan >= 12 THEN 'STABLE (1-2 tahun)'
        WHEN total_durasi_tinggal_bulan >= 6 THEN 'MODERATE (6-12 bulan)'
        ELSE 'SHORT_TERM (<6 bulan)'
    END as loyalty_segment
FROM penyewa_duration
ORDER BY status_penyewa DESC, total_durasi_tinggal_bulan DESC;

---

-- =====================================================
-- QUERY OLAP 6: PAYMENT PERFORMANCE - SIAPA YANG BELUM BAYAR?
-- =====================================================
-- Scenario: Generate laporan piutang yang perlu ditagih

WITH outstanding_balance AS (
    SELECT 
        p.id as penyewa_id,
        p.nama as nama_penyewa,
        p.email,
        p.telp,
        p.status as status_penyewa,
        k.nomor as kamar,
        cs.id as kontrak_id,
        SUM(CASE WHEN pb.status IN ('unpaid', 'overdue') THEN pb.nominal ELSE 0 END) as total_piutang,
        COUNT(CASE WHEN pb.status IN ('unpaid', 'overdue') THEN 1 END) as jumlah_bulan_utang,
        MIN(pb.due_date) as bulan_paling_lama_utang,
        CEIL(EXTRACT(DAY FROM CURRENT_DATE - MIN(pb.due_date))) as hari_telat_terlamaPada,
        SUM(CASE WHEN pb.status = 'paid' THEN pb.nominal ELSE 0 END) as total_terbayar,
        COUNT(CASE WHEN pb.status = 'paid' THEN 1 END) as jumlah_bulan_terbayar
    FROM penyewa p
    JOIN kontrak_sewa cs ON p.id = cs.penyewa_id
    JOIN kamar k ON cs.kamar_id = k.id
    LEFT JOIN pembayaran pb ON cs.id = pb.kontrak_id
    WHERE cs.status = 'aktif'
    GROUP BY p.id, p.nama, p.email, p.telp, p.status, k.nomor, cs.id
    HAVING SUM(CASE WHEN pb.status IN ('unpaid', 'overdue') THEN pb.nominal ELSE 0 END) > 0
)
SELECT 
    penyewa_id,
    nama_penyewa,
    email,
    telp,
    status_penyewa,
    kamar,
    total_piutang,
    jumlah_bulan_utang,
    bulan_paling_lama_utang,
    hari_telat_terlamaPada,
    total_terbayar,
    jumlah_bulan_terbayar,
    CASE 
        WHEN hari_telat_terlamaPada > 90 THEN 'CRITICAL'
        WHEN hari_telat_terlamaPada > 30 THEN 'URGENT'
        ELSE 'PENDING'
    END as collection_priority
FROM outstanding_balance
ORDER BY total_piutang DESC, hari_telat_terlamaPada DESC;

---

-- =====================================================
-- QUERY OLAP 7: MAINTENANCE ANALYTICS - KAMAR MANA YANG PALING SERING RUSAK?
-- =====================================================
-- Scenario: Identifikasi kamar bermasalah dan fasilitas yang sering rusak

WITH maintenance_summary AS (
    SELECT 
        k.id,
        k.nomor as kamar_nomor,
        tk.nama as tipe_kamar,
        COUNT(DISTINCT mr.id) as total_maintenance_requests,
        COUNT(DISTINCT CASE WHEN mr.status = 'completed' THEN mr.id END) as completed_requests,
        COUNT(DISTINCT CASE WHEN mr.status IN ('open', 'in-progress') THEN mr.id END) as pending_requests,
        SUM(mr.biaya_repair) as total_biaya_repair,
        ROUND(AVG(EXTRACT(DAY FROM mr.updated_at - mr.tanggal_lapor)), 2) as rata_rata_hari_perbaikan,
        COUNT(DISTINCT CASE WHEN mr.ditanggung_penyewa THEN mr.id END) as ditanggung_penyewa_count,
        JSON_AGG(DISTINCT mr.deskripsi) as daftar_keluhan
    FROM kamar k
    JOIN tipe_kamar tk ON k.tipe_id = tk.id
    LEFT JOIN maintenance_request mr ON k.id = mr.kamar_id
    WHERE k.kos_id = 1
    GROUP BY k.id, k.nomor, tk.nama
)
SELECT 
    kamar_nomor,
    tipe_kamar,
    total_maintenance_requests,
    completed_requests,
    pending_requests,
    total_biaya_repair,
    rata_rata_hari_perbaikan,
    ditanggung_penyewa_count,
    CASE 
        WHEN total_maintenance_requests >= 5 THEN 'PROBLEMATIC - Perlu investigasi'
        WHEN total_maintenance_requests >= 3 THEN 'NEEDS ATTENTION'
        WHEN total_maintenance_requests >= 1 THEN 'NORMAL'
        ELSE 'EXCELLENT'
    END as kamar_condition_status
FROM maintenance_summary
ORDER BY total_maintenance_requests DESC, total_biaya_repair DESC;

---

-- =====================================================
-- QUERY OLAP 8: TOP MOST DAMAGED FACILITIES
-- =====================================================
-- Scenario: Fasilitas apa yang paling sering rusak? Perlu replacement plan

SELECT 
    f.id,
    f.nama as nama_fasilitas,
    f.kategori,
    COUNT(DISTINCT kf.kamar_id) as kamar_dengan_fasilitas,
    COUNT(DISTINCT CASE WHEN kf.kondisi = 'rusak' THEN kf.kamar_id END) as kamar_rusak,
    COUNT(DISTINCT CASE WHEN kf.kondisi = 'maintenance' THEN kf.kamar_id END) as kamar_maintenance,
    COUNT(DISTINCT CASE WHEN kf.kondisi = 'baik' THEN kf.kamar_id END) as kamar_baik,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN kf.kondisi IN ('rusak', 'maintenance') THEN kf.kamar_id END) 
        / NULLIF(COUNT(DISTINCT kf.kamar_id), 0), 2) as persen_tidak_baik
FROM fasilitas f
LEFT JOIN kamar_fasilitas kf ON f.id = kf.fasilitas_id
GROUP BY f.id, f.nama, f.kategori
ORDER BY persen_tidak_baik DESC, kamar_rusak DESC;

---

-- =====================================================
-- QUERY OLAP 9: REVENUE PER KAMAR - PROFIT ANALYSIS
-- =====================================================
-- Scenario: Kamar mana yang paling profitable? (revenue - maintenance cost)

WITH kamar_financials AS (
    SELECT 
        k.id,
        k.nomor,
        tk.nama as tipe_kamar,
        tk.harga_sewa,
        SUM(CASE WHEN p.status = 'paid' THEN p.nominal ELSE 0 END) as total_revenue,
        COUNT(DISTINCT cs.id) as jumlah_kontrak,
        SUM(mr.biaya_repair) as total_maintenance_cost,
        COUNT(DISTINCT CASE WHEN mr.status = 'completed' THEN mr.id END) as completed_maintenance
    FROM kamar k
    JOIN tipe_kamar tk ON k.tipe_id = tk.id
    LEFT JOIN kontrak_sewa cs ON k.id = cs.kamar_id
    LEFT JOIN pembayaran p ON cs.id = p.kontrak_id
    LEFT JOIN maintenance_request mr ON k.id = mr.kamar_id AND mr.status = 'completed'
    WHERE k.kos_id = 1
    GROUP BY k.id, k.nomor, tk.nama, tk.harga_sewa
)
SELECT 
    nomor,
    tipe_kamar,
    harga_sewa,
    total_revenue,
    COALESCE(total_maintenance_cost, 0) as total_maintenance_cost,
    total_revenue - COALESCE(total_maintenance_cost, 0) as gross_profit,
    ROUND((total_revenue - COALESCE(total_maintenance_cost, 0)) / NULLIF(total_revenue, 0) * 100, 2) as profit_margin_persen,
    jumlah_kontrak,
    completed_maintenance
FROM kamar_financials
ORDER BY gross_profit DESC;

---

-- =====================================================
-- QUERY OLAP 10: COMBINED BUSINESS DASHBOARD QUERY
-- =====================================================
-- Scenario: Dashboard ringkas untuk management

WITH summary_stats AS (
    SELECT 
        (SELECT COUNT(*) FROM kamar WHERE kos_id = 1) as total_kamar,
        (SELECT COUNT(*) FROM kamar WHERE kos_id = 1 AND status = 'terisi') as kamar_terisi,
        (SELECT COUNT(DISTINCT penyewa_id) FROM kontrak_sewa 
         WHERE status = 'aktif' AND kamar_id IN 
         (SELECT id FROM kamar WHERE kos_id = 1)) as penyewa_aktif,
        (SELECT SUM(nominal) FROM pembayaran WHERE status = 'paid' 
         AND kontrak_id IN (SELECT id FROM kontrak_sewa WHERE kamar_id IN 
         (SELECT id FROM kamar WHERE kos_id = 1))) as revenue_terbayar,
        (SELECT SUM(nominal) FROM pembayaran WHERE status IN ('unpaid', 'overdue')
         AND kontrak_id IN (SELECT id FROM kontrak_sewa WHERE kamar_id IN 
         (SELECT id FROM kamar WHERE kos_id = 1))) as piutang,
        (SELECT COUNT(*) FROM maintenance_request WHERE status IN ('open', 'in-progress')
         AND kamar_id IN (SELECT id FROM kamar WHERE kos_id = 1)) as maintenance_pending
)
SELECT 
    total_kamar,
    kamar_terisi,
    ROUND(100.0 * kamar_terisi / total_kamar, 2) as occupancy_persen,
    penyewa_aktif,
    revenue_terbayar,
    piutang,
    revenue_terbayar + piutang as target_revenue,
    ROUND(100.0 * revenue_terbayar / (revenue_terbayar + piutang), 2) as collection_rate_persen,
    maintenance_pending
FROM summary_stats;

---

-- =====================================================
-- QUERY OLAP SUMMARY
-- =====================================================
-- Query OLAP yang dibuat untuk Business Intelligence:
-- 1. Revenue Analysis - Total pendapatan bulanan
-- 2. Revenue by Kamar Type - Kamar mana paling profitable
-- 3. Occupancy Rate Analysis - Tingkat hunian
-- 4. Kamar Kosong Analysis - Identifikasi kamar susah disewakan
-- 5. Customer Segmentation - Penyewa loyal vs churn
-- 6. Payment Performance - Siapa yang belum bayar (aging list)
-- 7. Maintenance Analytics - Kamar & fasilitas bermasalah
-- 8. Top Damaged Facilities - Identifikasi equipment untuk maintenance planning
-- 9. Profit Analysis per Kamar - Kamar mana yang paling menguntungkan
-- 10. Business Dashboard - Ringkasan KPI utama

-- Semua query menggunakan aggregation (SUM, COUNT, AVG), GROUP BY, dan CASE
-- untuk business intelligence yang actionable.
