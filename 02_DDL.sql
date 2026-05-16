-- =====================================================
-- BAGIAN 3.1: DDL - CREATE DATABASE DAN TABLES
-- Database: KosTrack (Sistem Manajemen Kos-Kosan)
-- =====================================================

-- Database d_kos_kosan sudah ada
-- Jalankan query ini langsung di database d_kos_kosan

-- =====================================================
-- TABEL 1: KOS (Data Induk Kos-Kosan)
-- =====================================================
CREATE TABLE kos (
    id SERIAL PRIMARY KEY,
    nama VARCHAR(100) NOT NULL,
    alamat TEXT NOT NULL,
    kota VARCHAR(50) NOT NULL,
    provinsi VARCHAR(50),
    pemilik VARCHAR(100),
    telp_pemilik VARCHAR(20),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- =====================================================
-- TABEL 2: TIPE_KAMAR (Kategori Harga Kamar)
-- =====================================================
CREATE TABLE tipe_kamar (
    id SERIAL PRIMARY KEY,
    kos_id INT NOT NULL REFERENCES kos(id) ON DELETE CASCADE,
    nama VARCHAR(50) NOT NULL,
    deskripsi TEXT,
    harga_sewa DECIMAL(10,2) NOT NULL CHECK (harga_sewa > 0),
    fasilitas_included JSONB,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(kos_id, nama)
);

-- =====================================================
-- TABEL 3: KAMAR (Unit Kamar)
-- =====================================================
CREATE TABLE kamar (
    id SERIAL PRIMARY KEY,
    kos_id INT NOT NULL REFERENCES kos(id) ON DELETE CASCADE,
    tipe_id INT NOT NULL REFERENCES tipe_kamar(id) ON DELETE RESTRICT,
    nomor VARCHAR(10) NOT NULL,
    luas DECIMAL(5,2),
    lantai INT,
    status VARCHAR(20) NOT NULL DEFAULT 'kosong' 
        CHECK (status IN ('kosong', 'terisi', 'maintenance', 'reserved')),
    catatan TEXT,
    foto_dokumen JSONB,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(kos_id, nomor)
);

-- =====================================================
-- TABEL 4: PENYEWA (Data Penghuni)
-- =====================================================
CREATE TABLE penyewa (
    id SERIAL PRIMARY KEY,
    kos_id INT NOT NULL REFERENCES kos(id) ON DELETE CASCADE,
    nama VARCHAR(100) NOT NULL,
    email VARCHAR(100),
    telp VARCHAR(20),
    ktp VARCHAR(20) UNIQUE,
    tgl_lahir DATE,
    alamat_asal TEXT,
    nama_emergency VARCHAR(100),
    telp_emergency VARCHAR(20),
    status VARCHAR(20) NOT NULL DEFAULT 'aktif' 
        CHECK (status IN ('aktif', 'non-aktif', 'blacklist')),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- =====================================================
-- TABEL 5: KONTRAK_SEWA (Perjanjian Sewa)
-- =====================================================
CREATE TABLE kontrak_sewa (
    id SERIAL PRIMARY KEY,
    kamar_id INT NOT NULL REFERENCES kamar(id) ON DELETE RESTRICT,
    penyewa_id INT NOT NULL REFERENCES penyewa(id) ON DELETE RESTRICT,
    tanggal_mulai DATE NOT NULL,
    tanggal_akhir DATE,
    durasi_bulan INT NOT NULL CHECK (durasi_bulan > 0),
    harga_per_bulan DECIMAL(10,2) NOT NULL CHECK (harga_per_bulan > 0),
    deposit DECIMAL(10,2) DEFAULT 0,
    potongan_deposit DECIMAL(10,2) DEFAULT 0,
    status VARCHAR(20) NOT NULL DEFAULT 'aktif' 
        CHECK (status IN ('aktif', 'berakhir', 'dibatalkan')),
    catatan TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    CHECK (tanggal_mulai < tanggal_akhir)
);

-- =====================================================
-- TABEL 6: PEMBAYARAN (Transaksi Pembayaran)
-- =====================================================
CREATE TABLE pembayaran (
    id SERIAL PRIMARY KEY,
    kontrak_id INT NOT NULL REFERENCES kontrak_sewa(id) ON DELETE CASCADE,
    bulan_ke INT NOT NULL,
    nominal DECIMAL(10,2) NOT NULL CHECK (nominal > 0),
    metode_bayar VARCHAR(30) DEFAULT 'cash',
    tanggal_bayar DATE,
    due_date DATE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'unpaid' 
        CHECK (status IN ('paid', 'unpaid', 'overdue')),
    bukti_bayar JSONB,
    catatan TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- =====================================================
-- TABEL 7: FASILITAS (Amenities)
-- =====================================================
CREATE TABLE fasilitas (
    id SERIAL PRIMARY KEY,
    nama VARCHAR(100) NOT NULL UNIQUE,
    kategori VARCHAR(50),
    harga_premium DECIMAL(10,2) DEFAULT 0,
    deskripsi TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

-- =====================================================
-- TABEL 8: KAMAR_FASILITAS (Many-to-Many Relationship)
-- =====================================================
CREATE TABLE kamar_fasilitas (
    kamar_id INT NOT NULL REFERENCES kamar(id) ON DELETE CASCADE,
    fasilitas_id INT NOT NULL REFERENCES fasilitas(id) ON DELETE CASCADE,
    kondisi VARCHAR(20) NOT NULL DEFAULT 'baik' 
        CHECK (kondisi IN ('baik', 'rusak', 'maintenance')),
    catatan TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    PRIMARY KEY(kamar_id, fasilitas_id)
);

-- =====================================================
-- TABEL 9: MAINTENANCE_REQUEST (Laporan Keluhan)
-- =====================================================
CREATE TABLE maintenance_request (
    id SERIAL PRIMARY KEY,
    kamar_id INT NOT NULL REFERENCES kamar(id) ON DELETE CASCADE,
    penyewa_id INT REFERENCES penyewa(id) ON DELETE SET NULL,
    deskripsi TEXT NOT NULL,
    kategori VARCHAR(30) NOT NULL DEFAULT 'normal' 
        CHECK (kategori IN ('urgent', 'normal')),
    status VARCHAR(20) NOT NULL DEFAULT 'open' 
        CHECK (status IN ('open', 'in-progress', 'completed', 'cancelled')),
    tanggal_lapor TIMESTAMP DEFAULT NOW(),
    tanggal_target_selesai DATE,
    biaya_estimasi DECIMAL(10,2),
    biaya_repair DECIMAL(10,2),
    ditanggung_penyewa BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- =====================================================
-- TABEL 10: MAINTENANCE_HISTORY (Riwayat Perbaikan)
-- =====================================================
CREATE TABLE maintenance_history (
    id SERIAL PRIMARY KEY,
    request_id INT NOT NULL REFERENCES maintenance_request(id) ON DELETE CASCADE,
    tanggal_mulai TIMESTAMP NOT NULL,
    tanggal_selesai TIMESTAMP,
    catatan TEXT,
    teknisi_nama VARCHAR(100),
    biaya_aktual DECIMAL(10,2),
    status VARCHAR(20) NOT NULL DEFAULT 'in-progress' 
        CHECK (status IN ('in-progress', 'completed')),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    CHECK (tanggal_selesai >= tanggal_mulai OR tanggal_selesai IS NULL)
);

-- =====================================================
-- INDEXES (Optimasi Query)
-- =====================================================

-- Index untuk frequent queries
CREATE INDEX idx_kamar_kos_id ON kamar(kos_id);
CREATE INDEX idx_kamar_tipe_id ON kamar(tipe_id);
CREATE INDEX idx_kamar_status ON kamar(status);

CREATE INDEX idx_penyewa_kos_id ON penyewa(kos_id);
CREATE INDEX idx_penyewa_status ON penyewa(status);

CREATE INDEX idx_kontrak_kamar_id ON kontrak_sewa(kamar_id);
CREATE INDEX idx_kontrak_penyewa_id ON kontrak_sewa(penyewa_id);
CREATE INDEX idx_kontrak_status ON kontrak_sewa(status);

CREATE INDEX idx_pembayaran_kontrak_id ON pembayaran(kontrak_id);
CREATE INDEX idx_pembayaran_status ON pembayaran(status);
CREATE INDEX idx_pembayaran_tanggal ON pembayaran(tanggal_bayar);

CREATE INDEX idx_maintenance_kamar_id ON maintenance_request(kamar_id);
CREATE INDEX idx_maintenance_status ON maintenance_request(status);
CREATE INDEX idx_maintenance_tanggal ON maintenance_request(tanggal_lapor);

CREATE INDEX idx_kamar_fasilitas_fasilitas_id ON kamar_fasilitas(fasilitas_id);

-- Composite index untuk query kompleks
CREATE INDEX idx_pembayaran_kontrak_status ON pembayaran(kontrak_id, status);
CREATE INDEX idx_kontrak_kamar_status ON kontrak_sewa(kamar_id, status);

-- =====================================================
-- TRIGGERS (Business Logic)
-- =====================================================

-- Trigger 1: Auto-update tanggal_akhir kontrak berdasarkan durasi
CREATE OR REPLACE FUNCTION update_tanggal_akhir()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.tanggal_akhir IS NULL AND NEW.durasi_bulan IS NOT NULL THEN
        NEW.tanggal_akhir := NEW.tanggal_mulai + (NEW.durasi_bulan || ' months')::INTERVAL;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_tanggal_akhir
BEFORE INSERT OR UPDATE ON kontrak_sewa
FOR EACH ROW
EXECUTE FUNCTION update_tanggal_akhir();

-- Trigger 2: Auto-create pembayaran ketika kontrak dibuat
CREATE OR REPLACE FUNCTION create_pembayaran_otomatis()
RETURNS TRIGGER AS $$
DECLARE
    i INT;
    bulan_date DATE;
BEGIN
    IF NEW.status = 'aktif' THEN
        FOR i IN 1..NEW.durasi_bulan LOOP
            bulan_date := NEW.tanggal_mulai + ((i-1) || ' months')::INTERVAL;
            INSERT INTO pembayaran (kontrak_id, bulan_ke, nominal, due_date, status)
            VALUES (NEW.id, i, NEW.harga_per_bulan, bulan_date, 'unpaid');
        END LOOP;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_create_pembayaran
AFTER INSERT ON kontrak_sewa
FOR EACH ROW
EXECUTE FUNCTION create_pembayaran_otomatis();

-- Trigger 3: Update status pembayaran ke 'overdue' jika lewat due date
CREATE OR REPLACE FUNCTION update_status_overdue()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE pembayaran
    SET status = 'overdue'
    WHERE kontrak_id = NEW.kontrak_id 
        AND status = 'unpaid' 
        AND due_date < CURRENT_DATE;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_overdue_check
AFTER INSERT ON pembayaran
FOR EACH ROW
EXECUTE FUNCTION update_status_overdue();

-- Trigger 4: Update updated_at columns
CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_kamar BEFORE UPDATE ON kamar
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER trg_update_penyewa BEFORE UPDATE ON penyewa
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER trg_update_kontrak BEFORE UPDATE ON kontrak_sewa
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER trg_update_pembayaran BEFORE UPDATE ON pembayaran
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER trg_update_maintenance_request BEFORE UPDATE ON maintenance_request
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

-- =====================================================
-- SAMPLE VIEWS (Untuk analisis)
-- =====================================================

-- View: Kamar dengan status dan penyewa saat ini
CREATE VIEW v_kamar_status AS
SELECT 
    k.id,
    k.nomor,
    tk.nama as tipe_kamar,
    k.status,
    p.nama as penyewa_aktif,
    cs.tanggal_mulai,
    cs.tanggal_akhir,
    k.updated_at
FROM kamar k
JOIN tipe_kamar tk ON k.tipe_id = tk.id
LEFT JOIN kontrak_sewa cs ON k.id = cs.kamar_id AND cs.status = 'aktif'
LEFT JOIN penyewa p ON cs.penyewa_id = p.id
ORDER BY k.nomor;

-- View: Pembayaran yang belum dibayar
CREATE VIEW v_pembayaran_unpaid AS
SELECT 
    p.id,
    cs.id as kontrak_id,
    pen.nama as penyewa,
    k.nomor as kamar,
    p.bulan_ke,
    p.nominal,
    p.due_date,
    p.status,
    CASE WHEN p.due_date < CURRENT_DATE THEN 'OVERDUE' ELSE 'PENDING' END as prioritas
FROM pembayaran p
JOIN kontrak_sewa cs ON p.kontrak_id = cs.id
JOIN penyewa pen ON cs.penyewa_id = pen.id
JOIN kamar k ON cs.kamar_id = k.id
WHERE p.status IN ('unpaid', 'overdue')
ORDER BY p.due_date ASC;

-- View: Maintenance open dan in-progress
CREATE VIEW v_maintenance_active AS
SELECT 
    mr.id,
    k.nomor as kamar,
    p.nama as penyewa,
    mr.deskripsi,
    mr.kategori,
    mr.status,
    mr.tanggal_lapor,
    mr.tanggal_target_selesai,
    CEIL(EXTRACT(DAY FROM CURRENT_DATE - mr.tanggal_lapor)) as hari_menunggu
FROM maintenance_request mr
JOIN kamar k ON mr.kamar_id = k.id
LEFT JOIN penyewa p ON mr.penyewa_id = p.id
WHERE mr.status IN ('open', 'in-progress')
ORDER BY mr.kategori DESC, mr.tanggal_lapor ASC;

-- =====================================================
-- DONE! Database schema sudah siap.
-- =====================================================
