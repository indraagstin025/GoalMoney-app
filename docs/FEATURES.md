# Panduan Fitur - GoalMoney App

Dokumentasi lengkap semua fitur dalam aplikasi GoalMoney.

---

## 📋 Daftar Isi

1. [Dashboard](#1-dashboard)
2. [Goals](#2-goals)
3. [Transactions](#3-transactions)
4. [Withdrawals](#4-withdrawals)
5. [Badges](#5-badges)
6. [Analytics](#6-analytics)
7. [Reports](#7-reports)
8. [Profile](#8-profile)

---

## 1. Dashboard

### Overview

Dashboard adalah halaman utama yang menampilkan ringkasan keuangan Anda.

### Komponen

#### 1.1 Header

- Menampilkan salam (Selamat Pagi/Siang/Malam)
- Nama pengguna
- Foto profil (tap untuk ke halaman Profile)

#### 1.2 Summary Card

| Field             | Deskripsi                           |
| ----------------- | ----------------------------------- |
| Total Tabungan    | Jumlah semua tabungan di semua goal |
| Available Balance | Saldo yang bisa ditarik             |
| Progress          | Persentase pencapaian total         |

#### 1.3 Menu Grid

| Icon | Nama      | Fungsi              |
| ---- | --------- | ------------------- |
| 📋   | My Goals  | Lihat daftar goal   |
| ➕   | Add Goal  | Buat goal baru      |
| 💰   | Withdraw  | Tarik dana          |
| 🏆   | Badges    | Lihat koleksi badge |
| 📊   | Laporan   | Export laporan      |
| 📈   | Analytics | Lihat statistik     |
| 👤   | Profile   | Pengaturan akun     |

---

## 2. Goals

### 2.1 Goal List Screen

Menampilkan semua goal tabungan Anda.

**Informasi Setiap Goal:**

- Nama goal
- Progress bar visual
- Current amount / Target amount
- Hari tersisa sampai deadline

**Actions:**

- Tap goal → Goal Detail
- Swipe left → Delete (dengan konfirmasi)

### 2.2 Add Goal Screen

**Field Input:**
| Field | Required | Deskripsi |
|-------|----------|-----------|
| Nama Goal | Ya | Contoh: "Beli iPhone 15" |
| Target Amount | Ya | Jumlah target tabungan |
| Deadline | Tidak | Tanggal target selesai |
| Deskripsi | Tidak | Catatan tambahan |
| Type | Tidak | digital (default) atau cash |

**Validasi:**

- Nama minimal 3 karakter
- Target minimal Rp 10.000

### 2.3 Goal Detail Screen

**Informasi:**

- Progress percentage
- Current / Target amount
- Remaining amount
- Riwayat transaksi

**Actions:**

- Deposit → Tambah tabungan
- Edit → Ubah detail goal
- Delete → Hapus goal

---

## 3. Transactions

### 3.1 Add Transaction (Deposit)

**Field Input:**
| Field | Required | Deskripsi |
|-------|----------|-----------|
| Amount | Ya | Jumlah deposit |
| Method | Tidak | Metode: Transfer/Cash/E-Wallet |
| Deskripsi | Tidak | Catatan transaksi |

**Perilaku Overflow:**
Jika deposit melebihi target:

1. Goal akan terisi sampai target
2. Kelebihan masuk ke Available Balance
3. Muncul notifikasi "Goal Completed!"

### 3.2 Transaction History

Ditampilkan di Goal Detail:

- Tanggal transaksi
- Jumlah
- Metode pembayaran

---

## 4. Withdrawals

### 4.1 Withdrawal Screen

**Pilih Sumber Dana:**

1. **Available Balance** - Saldo bebas
2. **From Goal** - Dari goal tertentu

**Field Input:**
| Field | Required | Deskripsi |
|-------|----------|-----------|
| Amount | Ya | Jumlah penarikan |
| Method | Ya | DANA/GoPay/OVO/Bank |
| Account Number | Ya | Nomor akun tujuan |
| Notes | Tidak | Catatan |

### 4.2 Withdrawal Methods

| Method        | Format Nomor   |
| ------------- | -------------- |
| DANA          | 08xxxxxxxxxx   |
| GoPay         | 08xxxxxxxxxx   |
| OVO           | 08xxxxxxxxxx   |
| Bank Transfer | Nomor rekening |

### 4.3 Status Withdrawal

| Status   | Warna  | Deskripsi       |
| -------- | ------ | --------------- |
| Pending  | Kuning | Menunggu proses |
| Approved | Hijau  | Sudah diproses  |
| Rejected | Merah  | Ditolak         |

---

## 5. Badges

### 5.1 Badge Screen

**Tabs:**

1. **Earned** - Badge yang sudah didapat
2. **Unearned** - Badge yang belum didapat

**Informasi Badge:**

- Icon emoji
- Nama badge
- Deskripsi
- Tanggal earned (jika sudah)

### 5.2 Daftar Badge

| Icon | Nama               | Requirement              |
| ---- | ------------------ | ------------------------ |
| 🌟   | First Saver        | Deposit pertama          |
| ⚡   | Getting Started    | Streak 3 hari            |
| 🔥   | Week Warrior       | Streak 7 hari            |
| 💪   | Fortnight Fighter  | Streak 14 hari           |
| 💎   | Monthly Master     | Streak 30 hari           |
| 🏆   | Goal Achiever      | Selesaikan 1 goal        |
| 🎖️   | Triple Victory     | Selesaikan 3 goal        |
| 👑   | Goal Master        | Selesaikan 5 goal        |
| 💵   | Hundred Thousander | Total Rp 100.000         |
| 💴   | Half Millionaire   | Total Rp 500.000         |
| 💰   | Millionaire        | Total Rp 1.000.000       |
| 💎   | Multi Millionaire  | Total Rp 5.000.000       |
| 🎯   | Multi Tasker       | 3 goal aktif             |
| 📊   | Regular Saver      | 10x deposit              |
| 📈   | Super Saver        | 50x deposit              |
| 🐦   | Early Bird         | Selesai sebelum deadline |

### 5.3 Cara Mendapat Badge

Badge otomatis diberikan setelah:

1. Anda melakukan deposit
2. Sistem mengecek pencapaian
3. Badge baru muncul dengan animasi

---

## 6. Analytics

### 6.1 Analytics Screen

**Summary Stats:**

- Total Tabungan
- Overall Progress
- Goal Selesai
- Goal Aktif
- Total Deposit

**Charts:**

#### Line Chart - Tren Bulanan

Menampilkan total tabungan per bulan dalam setahun.

#### Bar Chart - Progress Goals

Membandingkan progress masing-masing goal (top 6).

#### Pie Chart - Distribusi Kategori

Kategori berdasarkan target:

- < 500rb (Small)
- 500rb - 2jt (Medium)
- 2jt - 10jt (Large)
- > 10jt (Mega)

### 6.2 Streak Calendar

**Fitur:**

- Heatmap calendar (seperti GitHub)
- Current streak counter
- Longest streak counter
- Monthly summary

**Warna Intensity:**
| Level | Warna | Amount |
|-------|-------|--------|
| 0 | Abu-abu | Tidak ada |
| 1 | Hijau muda | < 100rb |
| 2 | Hijau | 100rb - 500rb |
| 3 | Hijau tua | 500rb - 1jt |
| 4 | Hijau gelap | > 1jt |

### 6.3 Smart Recommendations

**Informasi:**

- Saran nabung harian
- Saran nabung mingguan
- Urgency indicator
- Tips personalisasi

**Urgency Levels:**
| Level | Warna | Kondisi |
|-------|-------|---------|
| Critical | Merah | < 7 hari |
| High | Orange | < 30 hari |
| Medium | Kuning | < 90 hari |
| Normal | Hijau | ≥ 90 hari |

---

## 7. Reports

### 7.1 Report Screen

**Filter:**

- Start Date
- End Date
- Goal tertentu (opsional)

### 7.2 Export Options

| Format | Deskripsi                       |
| ------ | ------------------------------- |
| PDF    | Laporan visual dengan grafik    |
| Excel  | Data spreadsheet untuk analisis |

**Isi Laporan:**

- Ringkasan total
- Detail per goal
- Riwayat transaksi
- Riwayat withdrawal

---

## 8. Profile

### 8.1 Profile Screen

**Informasi:**

- Foto profil (bisa diubah)
- Nama pengguna
- Email
- Member since

### 8.2 Settings

| Setting         | Fungsi                    |
| --------------- | ------------------------- |
| Edit Profile    | Ubah nama & foto          |
| Change Password | Ganti password            |
| Dark Mode       | Toggle tema gelap         |
| Notifications   | Push notification setting |
| Logout          | Keluar dari akun          |

### 8.3 Edit Profile

**Field yang Bisa Diubah:**

- Nama
- Foto profil
- Password (dengan konfirmasi lama)

---

## 💡 Tips Penggunaan

### Untuk Pemula

1. Mulai dengan 1 goal sederhana
2. Set target realistis
3. Deposit secara konsisten

### Untuk Pengguna Aktif

1. Gunakan deadline untuk motivasi
2. Cek Analytics untuk tracking
3. Kejar badges untuk gamifikasi

### Untuk Power Users

1. Export laporan bulanan
2. Monitor streak calendar
3. Ikuti smart recommendations

---

**© 2024 GoalMoney**
