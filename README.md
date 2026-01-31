# GoalMoney - Flutter Mobile App

**Aplikasi Tabungan Berbasis Goal**

Aplikasi mobile untuk membantu pengguna menabung dengan cara yang terstruktur dan menyenangkan melalui sistem goal-based savings.

---

## 📋 Daftar Isi

1. [Pendahuluan](#-pendahuluan)
2. [Fitur Utama](#-fitur-utama)
3. [Persyaratan Sistem](#-persyaratan-sistem)
4. [Instalasi](#-instalasi)
5. [Konfigurasi](#-konfigurasi)
6. [Struktur Proyek](#-struktur-proyek)
7. [Arsitektur](#-arsitektur)
8. [Panduan Penggunaan](#-panduan-penggunaan)
9. [Development Guide](#-development-guide)
10. [Troubleshooting](#-troubleshooting)

---

## 📖 Pendahuluan

GoalMoney adalah aplikasi mobile yang membantu Anda:

- Membuat goal tabungan dengan target dan deadline
- Melacak progress tabungan secara visual
- Mendapatkan motivasi melalui sistem gamifikasi (badges)
- Melihat analitik dan rekomendasi pintar
- Mengelola penarikan dana dengan mudah

---

## ✨ Fitur Utama

### 🎯 Goal Management

- Buat goal tabungan dengan nama, target, dan deadline
- Track progress dengan visual progress bar
- Kategori goal: digital atau cash

### 💰 Deposit & Withdraw

- Deposit ke goal dengan berbagai metode
- Withdraw ke e-wallet (DANA, GoPay, OVO)
- Available balance untuk overflow

### 🏆 Gamifikasi & Badges

- 16 badges untuk dicollect
- Streak tracking (berapa hari konsisten nabung)
- Motivasi melalui achievements

### 📊 Analytics Dashboard

- Grafik tren tabungan bulanan (Line Chart)
- Perbandingan progress goals (Bar Chart)
- Distribusi kategori (Pie Chart)
- Streak calendar heatmap

### 🤖 Smart Recommendations

- Saran nabung harian/mingguan
- Urgency indicator berdasarkan deadline
- Tips personalisasi

### 📄 Laporan

- Export ke PDF dan Excel
- Filter berdasarkan periode
- Ringkasan lengkap

---

## 💻 Persyaratan Sistem

### Development Environment

| Tool                     | Versi   |
| ------------------------ | ------- |
| Flutter SDK              | 3.10.0+ |
| Dart SDK                 | 3.0.0+  |
| Android Studio / VS Code | Latest  |

### Target Platform

| Platform | Minimum Version      |
| -------- | -------------------- |
| Android  | API 21 (Android 5.0) |
| iOS      | iOS 12.0             |

---

## 🚀 Instalasi

### 1. Clone Repository

```bash
git clone <repository-url>
cd GoalMoney-app
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Konfigurasi API

Edit file `lib/core/api_client.dart`:

```dart
static const String baseUrl = 'http://YOUR_API_URL:8000';
```

### 4. Konfigurasi Firebase (Optional)

1. Buat project di [Firebase Console](https://console.firebase.google.com/)
2. Download `google-services.json` (Android)
3. Letakkan di `android/app/`
4. Download `GoogleService-Info.plist` (iOS)
5. Letakkan di `ios/Runner/`

### 5. Run App

```bash
# Development
flutter run

# Build APK
flutter build apk --release

# Build iOS
flutter build ios --release
```

---

## ⚙️ Konfigurasi

### File `lib/core/api_client.dart`

```dart
class ApiClient {
  static const String baseUrl = 'http://localhost:8000';
  // Untuk emulator Android: 'http://10.0.2.2:8000'
  // Untuk device fisik: 'http://YOUR_IP:8000'
}
```

### Firebase Setup

File `android/app/build.gradle`:

```gradle
dependencies {
    implementation platform('com.google.firebase:firebase-bom:32.0.0')
    implementation 'com.google.firebase:firebase-messaging'
}
```

---

## 📁 Struktur Proyek

```
GoalMoney-app/
├── lib/
│   ├── main.dart                 # Entry point
│   ├── core/                     # Core utilities
│   │   ├── api_client.dart       # HTTP client (Dio)
│   │   ├── constants.dart        # App constants
│   │   └── photo_storage_service.dart
│   ├── models/                   # Data models
│   │   ├── user.dart
│   │   ├── goal.dart
│   │   ├── transaction.dart
│   │   ├── withdrawal.dart
│   │   ├── badge.dart
│   │   └── notification.dart
│   ├── providers/                # State management
│   │   ├── auth_provider.dart
│   │   ├── goal_provider.dart
│   │   ├── transaction_provider.dart
│   │   ├── badge_provider.dart
│   │   └── theme_provider.dart
│   ├── screens/                  # UI screens
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   └── register_screen.dart
│   │   ├── dashboard/
│   │   │   └── dashboard_screen.dart
│   │   ├── goals/
│   │   │   ├── goal_list_screen.dart
│   │   │   ├── goal_detail_screen.dart
│   │   │   └── add_goal_screen.dart
│   │   ├── transactions/
│   │   │   └── add_transaction_screen.dart
│   │   ├── withdrawals/
│   │   │   └── withdrawal_screen.dart
│   │   ├── profile/
│   │   │   └── profile_screen.dart
│   │   ├── reports/
│   │   │   └── report_screen.dart
│   │   ├── badges/
│   │   │   └── badge_screen.dart
│   │   └── analytics/
│   │       ├── analytics_screen.dart
│   │       └── streak_calendar_screen.dart
│   └── widgets/                  # Reusable widgets
│       ├── summary_card.dart
│       └── recommendation_card.dart
├── assets/
│   └── images/
│       └── logo.png
├── android/                      # Android native code
├── ios/                          # iOS native code
├── pubspec.yaml                  # Dependencies
└── README.md                     # This file
```

---

## 🏗️ Arsitektur

### State Management: Provider

Aplikasi menggunakan **Provider** untuk state management.

```
┌───────────────────────────────────────────────────┐
│                    MyApp                          │
│  ┌─────────────────────────────────────────────┐  │
│  │             MultiProvider                   │  │
│  │  ┌─────────────────────────────────────┐   │  │
│  │  │ AuthProvider                        │   │  │
│  │  │ GoalProvider                        │   │  │
│  │  │ TransactionProvider                 │   │  │
│  │  │ BadgeProvider                       │   │  │
│  │  │ ThemeProvider                       │   │  │
│  │  └─────────────────────────────────────┘   │  │
│  └─────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────┘
```

### Data Flow

```
User Action → Provider Method → API Call → Update State → Rebuild UI
```

### Dependencies

| Package            | Version | Purpose            |
| ------------------ | ------- | ------------------ |
| provider           | ^6.1.1  | State management   |
| dio                | ^5.3.3  | HTTP client        |
| shared_preferences | ^2.2.2  | Local storage      |
| image_picker       | ^1.1.2  | Foto profil        |
| intl               | ^0.19.0 | Formatting         |
| fl_chart           | ^0.69.2 | Charts             |
| firebase_core      | ^3.8.0  | Firebase           |
| firebase_messaging | ^15.1.6 | Push notifications |
| pdf                | ^3.11.0 | PDF generation     |
| excel              | ^4.0.6  | Excel generation   |

---

## 📱 Panduan Penggunaan

### 1. Registrasi & Login

1. Buka aplikasi
2. Tap "Daftar" untuk membuat akun baru
3. Isi nama, email, dan password
4. Setelah registrasi, otomatis login

### 2. Membuat Goal

1. Dari Dashboard, tap "Add Goal"
2. Isi detail goal:
   - Nama goal (contoh: "Beli Laptop")
   - Target amount (contoh: Rp 10.000.000)
   - Deadline (opsional)
   - Deskripsi (opsional)
3. Tap "Simpan"

### 3. Deposit ke Goal

1. Dari Dashboard, tap "My Goals"
2. Pilih goal yang ingin diisi
3. Tap tombol "+" atau "Deposit"
4. Masukkan nominal dan metode
5. Tap "Simpan"

### 4. Melihat Badges

1. Dari Dashboard, tap "Badges"
2. Lihat badges yang sudah earned (berwarna)
3. Lihat badges yang belum earned (abu-abu)
4. Tap badge untuk detail

### 5. Melihat Analytics

1. Dari Dashboard, tap "Analytics"
2. Lihat tren tabungan bulanan
3. Lihat perbandingan progress goals
4. Tap "📅" untuk streak calendar

### 6. Menarik Dana

1. Dari Dashboard, tap "Withdraw"
2. Pilih sumber: Available Balance atau Goal
3. Masukkan nominal dan tujuan
4. Isi nomor akun e-wallet
5. Tap "Request Withdrawal"

### 7. Export Laporan

1. Dari Dashboard, tap "Laporan"
2. Pilih periode
3. Tap "PDF" atau "Excel" untuk export

---

## 🛠️ Development Guide

### Menambah Screen Baru

1. Buat file di `lib/screens/[feature]/`
2. Import di file yang membutuhkan
3. Tambahkan route jika perlu

```dart
// lib/screens/example/example_screen.dart
import 'package:flutter/material.dart';

class ExampleScreen extends StatelessWidget {
  const ExampleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Example')),
      body: const Center(child: Text('Hello')),
    );
  }
}
```

### Menambah Provider Baru

1. Buat file di `lib/providers/`
2. Extend `ChangeNotifier`
3. Register di `main.dart`

```dart
// lib/providers/example_provider.dart
import 'package:flutter/material.dart';

class ExampleProvider extends ChangeNotifier {
  List<String> _items = [];
  List<String> get items => _items;

  void addItem(String item) {
    _items.add(item);
    notifyListeners();
  }
}
```

```dart
// main.dart
MultiProvider(
  providers: [
    // ... existing providers
    ChangeNotifierProvider(create: (_) => ExampleProvider()),
  ],
)
```

### Menambah Model Baru

1. Buat file di `lib/models/`
2. Tambahkan factory `fromJson`
3. Tambahkan method `toJson` jika perlu

```dart
// lib/models/example.dart
class Example {
  final int id;
  final String name;

  Example({required this.id, required this.name});

  factory Example.fromJson(Map<String, dynamic> json) {
    return Example(
      id: json['id'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
  };
}
```

### Memanggil API

Gunakan `ApiClient` untuk HTTP requests:

```dart
import '../core/api_client.dart';

class MyProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  Future<void> fetchData() async {
    try {
      final response = await _api.dio.get('/endpoint');
      if (response.data['success'] == true) {
        // Handle success
      }
    } on DioException catch (e) {
      // Handle error
    }
  }
}
```

---

## 🐛 Troubleshooting

### Build Error: Gradle Failed

```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

### Error: SocketException

Backend API tidak bisa diakses. Pastikan:

1. Server PHP running
2. URL di `api_client.dart` benar
3. Jika emulator: gunakan `10.0.2.2` bukan `localhost`

### Error: MissingPluginException

```bash
flutter clean
flutter pub get
flutter run
```

### Dark Mode Not Working

Pastikan `ThemeProvider` sudah di-register di `main.dart`.

### Push Notification Not Working

1. Pastikan Firebase configured
2. Cek `google-services.json` ada di `android/app/`
3. Request notification permission

---

## 📝 Code Style

- Gunakan `const` untuk widgets yang tidak berubah
- Gunakan `final` untuk variabel yang tidak di-reassign
- Nama file: `snake_case.dart`
- Nama class: `PascalCase`
- Nama variabel/method: `camelCase`

---

## 📞 Kontak

Untuk pertanyaan atau bantuan, hubungi tim development.

---

**© 2024 GoalMoney. All rights reserved.**
