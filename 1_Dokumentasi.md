# Bagian 1: Identifikasi Masalah

## 1.1 Nama Sistem

**Sistem Manajemen Kos-Kosan "KosTrack"**

---

## 1.2 Latar Belakang Masalah

Pengelolaan kos-kosan di Indonesia menghadapi beberapa tantangan operasional:

1. **Manajemen Kamar yang Kompleks**: Pemilik kos sulit melacak status kamar (kosong, terisi, sedang direnovasi), data penyewa, dan riwayat penghuni.

2. **Pembayaran Sewa Tidak Terpantau**: Sering terjadi keterlambatan pembayaran karena tidak ada sistem reminder otomatis dan pencatatan manual yang sering terjadi kesalahan.

3. **Administrasi Fasilitas Kamar Berantakan**: Data fasilitas kamar (AC, WiFi, water heater) tidak terdokumentasi dengan baik, sehingga sulit membedakan harga sewa berdasarkan fasilitas.

4. **Keluhan dan Maintenance Tidak Terorganisir**: Keluhan penyewa tentang fasilitas rusak tidak terdokumentasi, sehingga perbaikan sering tertunda atau terlupakan.

5. **Laporan Keuangan Manual**: Pemilik kos membuat laporan keuangan manual, rawan kesalahan, dan sulit analisis trend pendapatan.

6. **Kesulitan Analisis Bisnis**: Sulit mengetahui kapan musim sepi/ramai, berapa occupancy rate, dan data penyewa mana yang loyal.

**Solusi yang Ditawarkan:**
Sistem database terintegrasi yang mengelola data kamar, penyewa, pembayaran, fasilitas, maintenance, dan menghasilkan laporan bisnis otomatis.

---

## 1.3 Requirement Utama

### Fitur Fungsional (Minimal 5):

1. **Manajemen Kamar**
   - Tambah/edit/hapus data kamar dengan nomor, tipe, luas, harga sewa
   - Status kamar: kosong, terisi, maintenance, reserved
   - Foto/dokumen kamar (JSONB field)

2. **Manajemen Penyewa**
   - Data penyewa: nama, email, telepon, KTP, data keluarga
   - Tracking riwayat penyewa (siapa saja pernah tinggal di kamar X, berapa lama)
   - Status penyewa: aktif, non-aktif, blacklist

3. **Manajemen Sewa dan Pembayaran**
   - Kontrak sewa: tanggal mulai, durasi, harga, fasilitas included
   - Pencatatan pembayaran: nominal, tanggal, metode, status
   - Reminder keterlambatan pembayaran otomatis

4. **Manajemen Fasilitas**
   - Data fasilitas di kamar: AC, WiFi, water heater, kasur, meja
   - Kategori fasilitas dan harga premium per fasilitas
   - History perubahan fasilitas

5. **Manajemen Maintenance**
   - Keluhan/request perbaikan dari penyewa
   - Status repair: open, in-progress, completed
   - Biaya maintenance (gratis atau dibayar penyewa)
   - History maintenance per kamar

6. **Laporan dan Analitik** (Bonus)
   - Total pendapatan per bulan/tahun
   - Occupancy rate per kamar/bulan
   - Daftar penyewa dengan kemudahan identifikasi yang bayar/belum
   - Analisis durasi tinggal rata-rata
   - Kamar mana yang paling menguntungkan

---

## 1.4 Kebutuhan OLTP (Online Transaction Processing)

Transaksi harian/operasional yang sering terjadi:

1. **Checkin Penyewa Baru**
   - Insert data penyewa baru
   - Update status kamar menjadi "terisi"
   - Insert kontrak sewa
   - Hitung due date pembayaran

2. **Pembayaran Sewa**
   - Input pembayaran dari penyewa
   - Update status pembayaran ("paid"/"unpaid")
   - Insert ke tabel transaksi_pembayaran
   - Generate invoice/bukti pembayaran

3. **Checkout Penyewa**
   - Update status kamar menjadi "kosong"
   - Update tanggal checkout
   - Hitung denda/pengembalian deposit (jika ada)
   - Archive data sewa

4. **Lapor Keluhan/Maintenance**
   - Penyewa lapor fasilitas rusak
   - Insert ke tabel maintenance_request
   - Assign ke pekerja maintenance
   - Update status (open → in-progress → completed)

5. **Update Status Kamar**
   - Ubah status kamar (kosong → maintenance → terisi)
   - Tracking history status change

---

## 1.5 Kebutuhan OLAP (Online Analytical Processing)

Laporan/analisis yang dibutuhkan untuk bisnis insight:

1. **Dashboard Keuangan**
   - Total pendapatan bulan ini vs bulan lalu
   - Breakdown pendapatan per kamar/tipe kamar
   - Prediksi pendapatan 3 bulan ke depan
   - Analisis pembayaran tepat waktu vs terlambat

2. **Analisis Occupancy**
   - Occupancy rate per bulan (berapa % kamar terisi)
   - Kamar mana yang paling sering kosong
   - Rata-rata durasi penyewa tinggal
   - Seasonal pattern (musim ramai/sepi)

3. **Analisis Penyewa**
   - Daftar penyewa aktif
   - Penyewa loyal (stay > 1 tahun)
   - Penyewa problem (sering terlambat bayar, banyak komplain)
   - Segmentasi penyewa berdasarkan durasi tinggal

4. **Analisis Maintenance**
   - Kamar mana yang paling sering rusak
   - Rata-rata waktu response maintenance
   - Total biaya maintenance per kamar/bulan
   - Tren keluhan (fasilitas apa yang paling sering rusak)

5. **Performa Bisnis**
   - Revenue per kamar per tahun
   - Gross margin per kamar (revenue - maintenance cost)
   - Customer retention rate
   - Churn analysis (berapa penyewa yang pergi)

---

## 1.6 Ringkasan Requirement

| Aspek | Detail |
|-------|--------|
| **Domain** | Manajemen Kos-kosan |
| **Tujuan** | Automasi administrasi, tracking pembayaran, analisis bisnis |
| **Stakeholder Utama** | Pemilik kos, penyewa, maintenance staff |
| **Fitur Core** | Kamar, Penyewa, Sewa, Pembayaran, Fasilitas, Maintenance |
| **Volume Data** | ~50-100 penyewa aktif, ~20-30 kamar |
| **Transaksi/hari** | 5-10 transaksi (payment, checkin/checkout, complaint) |
| **Query Analytics** | Minimal 5 report utama per bulan |

---

## 1.7 Konteks Teknis

**Environment:**
- Database: PostgreSQL 12+
- Jenis Query: OLTP (pembayaran, checkin/checkout) + OLAP (reporting, analytics)

**Trade-off Design yang akan dipertimbangkan:**
- Normalisasi vs Denormalisasi untuk performa query
- Surrogate key vs Natural key
- JSON/JSONB untuk flexible fields (fasilitas kamar, dokumen)
- Materialized View untuk reporting performance
- Index strategy untuk query OLTP

---

**Next Step:** Desain Database (ERD, Schema, Trade-off Analysis)
