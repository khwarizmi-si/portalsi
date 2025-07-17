# 📱 portal_si

**portal_si** adalah aplikasi mobile sosial media berbasis Flutter yang terinspirasi dari platform seperti Instagram dan X. Aplikasi ini mendukung fitur feed, postingan, komentar, like, notifikasi, dan autentikasi pengguna, serta telah disiapkan untuk platform Android dan iOS.

---

## 🚀 Fitur Utama

- 🔐 **Autentikasi Pengguna**
  - Login, Register
  - Penyimpanan token aman via secure storage

- 🏠 **Dashboard dan Feed**
  - Feed dengan tampilan grid dan tampilan detail post
  - Interaksi: komentar, like, reply

- 💬 **Komentar dan Balasan**
  - Modal komentar interaktif menggunakan `DraggableScrollableSheet`

- 📩 **Notifikasi**
  - Dukungan endpoint notifikasi untuk update pengguna

- 🧑‍🤝‍🧑 **Profil & Avatar**
  - Avatar pengguna dengan fallback jika gambar tidak tersedia

- 🧰 **Layanan Modular**
  - Struktur `service` terpisah per fitur:
    - Post, Comment, Like, Follow, Message, Notification, User, Upload

- 🌐 **Dukungan Multi-Platform**
  - Android, iOS, Web, Windows, macOS, Linux

---

## 📁 Struktur Proyek

```bash
lib/
├── pages/              # Halaman UI (login, register, feed, detail)
├── services/           # Layer service untuk API backend
├── utils/              # Utility seperti validator dan secure storage
├── widgets/            # Komponen UI custom (textfield, avatar, dsb)
├── routes.dart         # Definisi dan navigasi routing
├── app.dart            # Root konfigurasi aplikasi
└── main.dart           # Entry point utama aplikasi
🛠️ Cara Menjalankan Proyek
🔹 Prasyarat
Flutter SDK (versi stable)

Emulator atau perangkat Android/iOS

Backend API aktif dan dapat diakses

🔹 Jalankan Aplikasi
bash
Salin
Edit
flutter pub get
flutter run
🔹 Build untuk iOS
Perlu macOS + Xcode

bash
Salin
Edit
flutter build ios --release
🧪 Testing
bash
Salin
Edit
flutter test
📦 Dependencies Utama
Beberapa package yang digunakan:

http – komunikasi dengan API

flutter_secure_storage – token storage aman

provider – state management (jika digunakan)

cached_network_image – gambar dengan placeholder

Lihat detail lengkap di file pubspec.yaml

💡 Catatan Pengembangan
Semua service API mengikuti endpoint REST yang telah disediakan.

Penamaan file dan folder mengikuti praktik clean architecture sederhana.

Komentar dan struktur kode ditulis agar mudah dikembangkan lebih lanjut.
