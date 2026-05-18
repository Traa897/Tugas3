
DROP INDEX IF EXISTS idx_kontrak_sewa_penyewa_status;
DROP INDEX IF EXISTS idx_pembayaran_kontrak_status;
DROP INDEX IF EXISTS idx_kamar_kos_id_status;
DROP INDEX IF EXISTS idx_penyewa_id;


--Explain Analyze sebelum di optimasi 
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
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
    (CURRENT_DATE - op.bulan_paling_lama) AS hari_telat_terlama,
    op.total_terbayar,
    op.jumlah_bulan_terbayar,
    CASE 
        WHEN (CURRENT_DATE - op.bulan_paling_lama) > 90 THEN 'CRITICAL'
        WHEN (CURRENT_DATE - op.bulan_paling_lama) > 30 THEN 'WARNING'
        ELSE 'PENDING'
    END AS collection_priority
FROM penyewa p
INNER JOIN kontrak_sewa cs ON p.id = cs.penyewa_id AND cs.status = 'aktif'
INNER JOIN kamar k ON cs.kamar_id = k.id
INNER JOIN outstanding_payments op ON cs.id = op.kontrak_id
WHERE op.total_piutang > 0
ORDER BY op.total_piutang DESC, 
         (CURRENT_DATE - op.bulan_paling_lama) DESC;


-- Buat index baru untuk optimasi query
CREATE INDEX idx_kontrak_sewa_penyewa_status 
    ON kontrak_sewa(penyewa_id, status);

CREATE INDEX idx_pembayaran_kontrak_status_due 
    ON pembayaran(kontrak_id, status, due_date);

CREATE INDEX idx_kamar_kos_id_status
    ON kamar(kos_id, status);


-- EXPLAIN ANALYZE setelah optimasi
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
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
    (CURRENT_DATE - op.bulan_paling_lama) AS hari_telat_terlama,
    op.total_terbayar,
    op.jumlah_bulan_terbayar,
    CASE 
        WHEN (CURRENT_DATE - op.bulan_paling_lama) > 90 THEN 'CRITICAL'
        WHEN (CURRENT_DATE - op.bulan_paling_lama) > 30 THEN 'WARNING'
        ELSE 'PENDING'
    END AS collection_priority
FROM penyewa p
INNER JOIN kontrak_sewa cs ON p.id = cs.penyewa_id AND cs.status = 'aktif'
INNER JOIN kamar k ON cs.kamar_id = k.id
INNER JOIN outstanding_payments op ON cs.id = op.kontrak_id
WHERE op.total_piutang > 0
ORDER BY op.total_piutang DESC,
         (CURRENT_DATE - op.bulan_paling_lama) DESC;