# 📱 portal_si

Proyek Flutter sederhana yang meniru fitur-fitur dasar dari aplikasi media sosial seperti Instagram/X. Berisi halaman login, register, feed, komentar, dan layanan API modular.

---

## 🚀 Getting Started

Proyek ini adalah titik awal untuk aplikasi Flutter yang terhubung ke backend REST API.

---

## 🛠️ Cara Menjalankan Proyek

### 🔹 Prasyarat

Pastikan kamu telah menyiapkan:

- ✅ **Flutter SDK** (versi stable)
- ✅ **Emulator** atau perangkat fisik Android/iOS
- ✅ **Backend API** aktif dan dapat diakses

### 🔹 Jalankan Aplikasi

```bash
flutter pub get
flutter run
```

### 🔹 Build untuk iOS

> ⚠️ _Perlu perangkat macOS dan Xcode terinstal_

```bash
flutter build ios --release
```

---

## 🧪 Testing

Untuk menjalankan unit test:

```bash
flutter test
```

---

## 📦 Dependencies Utama

Beberapa package penting yang digunakan dalam proyek ini:

- [`http`](https://pub.dev/packages/http) – komunikasi dengan API
- [`flutter_secure_storage`](https://pub.dev/packages/flutter_secure_storage) – token storage aman
- [`provider`](https://pub.dev/packages/provider) – state management (opsional)
- [`cached_network_image`](https://pub.dev/packages/cached_network_image) – gambar dengan placeholder dan caching

ℹ️ Lihat detail lengkap di file [`pubspec.yaml`](./pubspec.yaml)

---

## 📁 Struktur Proyek

```
lib/
├── pages/              # Halaman UI (Login, Register, Feed, dll)
├── services/           # Layanan API terpisah (auth, post, comment, dsb)
├── utils/              # Utilitas seperti validator, date formatter, dsb
├── widgets/            # Widget custom reusable
├── routes.dart         # Manajemen routing
├── main.dart           # Entry point aplikasi
└── app.dart            # Inisialisasi dan konfigurasi awal
```

---

## 💡 Catatan Pengembangan

- Semua service API mengikuti endpoint **REST** yang telah disediakan.
- Penamaan file dan struktur folder mengikuti prinsip **clean architecture** secara sederhana.
- Komentar dan struktur kode dirancang agar **mudah dikembangkan** dan dipelihara ke depannya.

---

## 📬 Kontribusi

Jika kamu ingin berkontribusi, jangan ragu untuk fork repository ini dan kirim pull request!

---
