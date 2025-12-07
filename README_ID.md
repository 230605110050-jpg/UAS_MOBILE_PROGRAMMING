# 📚 Aplikasi Pembaca Komik

Aplikasi Flutter modern dan kaya fitur untuk membaca manga/komik dengan kemampuan offline, autentikasi pengguna, dan antarmuka Material Design yang indah.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![SQLite](https://img.shields.io/badge/SQLite-07405E?style=for-the-badge&logo=sqlite&logoColor=white)

## ✨ Fitur

### 🎯 Fitur Utama
- **📖 Pembaca Manga**: Pembaca manga lengkap dengan navigasi chapter
- **🔍 Pencarian & Filter**: Cari manga berdasarkan judul dengan filter real-time
- **⭐ Sistem Favorit**: Simpan dan kelola manga favorit
- **📚 Riwayat Membaca**: Lacak progress dan riwayat membaca
- **🔄 Dukungan Offline**: Unduh chapter untuk dibaca offline
- **👤 Autentikasi Pengguna**: Sistem login dan registrasi yang aman

### 🎨 Pengalaman Pengguna
- **🌙 Tema Gelap/Terang**: Dukungan tema adaptif
- **📱 Desain Responsif**: Dioptimalkan untuk mobile dan tablet
- **⚡ Loading Cepat**: Cache gambar dan navigasi yang smooth
- **🔄 Pull-to-Refresh**: Refresh data dengan mudah
- **📊 Paginasi**: Loading efisien untuk daftar manga besar

### 🛠️ Fitur Teknis
- **🏗️ Arsitektur Bersih**: Pemisahan layer UI, logika bisnis, dan data
- **📡 Integrasi REST API**: Komunikasi API yang robust dengan error handling
- **💾 Database Lokal**: SQLite untuk penyimpanan data offline
- **🔐 Penyimpanan Aman**: Kredensial pengguna terenkripsi
- **📦 State Management**: GetX untuk state management reaktif

## 🚀 Tech Stack

### Frontend
- **Flutter** (>=2.17.0) - Framework UI
- **Dart** - Bahasa Pemrograman
- **Material Design** - Sistem Desain

### State Management & Navigasi
- **GetX** (^4.6.5) - State management dan routing

### Networking & Data
- **HTTP** (^1.6.0) - Komunikasi API
- **Cached Network Image** (^3.4.1) - Cache gambar
- **SQLite** (^2.2.0+3) - Database lokal
- **Shared Preferences** - Penyimpanan data sederhana
- **Flutter Secure Storage** (^9.2.4) - Penyimpanan terenkripsi

### Utilitas
- **Path Provider** (^2.0.13) - Akses sistem file
- **File Picker** (^8.0.0) - Pemilihan file
- **Crypto** (^3.0.7) - Fungsi kriptografi

## 📡 Endpoint API

Aplikasi terintegrasi dengan API manga scraper berbasis Laravel yang di-host di Vercel.

### Base URL
```
https://laravel-api-manga-scraper.vercel.app/api/api
```

### Endpoint

#### 1. Ambil Manga Terbaru (Dengan Paginasi)
```http
GET /terbaru/{page}
```

**Parameter:**
- `page` (integer): Nomor halaman (default: 1)

**Response:**
```json
{
  "success": true,
  "data": {
    "current_page": 1,
    "total_page": 10,
    "data": [
      {
        "title": "Judul Manga",
        "ratting": "8.5",
        "chapter": "Chapter 143",
        "img": "https://...",
        "url": "manga-slug"
      }
    ]
  }
}
```

#### 2. Ambil Detail Manga
```http
GET /detail/{slug}
```

**Parameter:**
- `slug` (string): Slug/identifier manga

**Response:**
```json
{
  "success": true,
  "data": {
    "title": "Judul Manga",
    "img": "https://...",
    "ratting": "8.5",
    "short_sinopsis": "Sinopsis...",
    "status": "Ongoing",
    "pengarang": "Nama Penulis",
    "tema": ["Action", "Adventure"],
    "chapter": [
      {
        "url": "chapter-slug",
        "chapter": "Chapter 143",
        "update": "2024-01-15"
      }
    ],
    "mirip": [
      {
        "url": "similar-manga-slug",
        "img": "https://...",
        "title": "Manga Serupa",
        "subtitle": "Action, Adventure"
      }
    ]
  }
}
```

#### 3. Ambil Gambar Chapter
```http
GET /baca/{chapter_slug}
```

**Parameter:**
- `chapter_slug` (string): Slug/identifier chapter

**Response:**
```json
{
  "success": true,
  "data": {
    "img": [
      "https://image1.jpg",
      "https://image2.jpg"
    ],
    "back_chapter": "previous-chapter-slug",
    "next_chapter": "next-chapter-slug"
  }
}
```

## 🛠️ Instalasi & Setup

### Prasyarat
- **Flutter SDK** (>=2.17.0)
- **Dart SDK** (>=2.17.0)
- **Android Studio** atau **VS Code** dengan ekstensi Flutter
- **Simulator Android/iOS** atau perangkat fisik

### Langkah Instalasi

1. **Clone repository**
   ```bash
   git clone https://github.com/username-anda/comic-reader.git
   cd comic-reader
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Konfigurasi untuk platform Anda**

   **Untuk Android:**
   - Pastikan Android SDK sudah dikonfigurasi dengan benar
   - Buat `android/app/src/main/AndroidManifest.xml` jika diperlukan

   **Untuk iOS:**
   - Pastikan Xcode sudah terinstall
   - Jalankan `pod install` di direktori `ios/`

4. **Jalankan aplikasi**
   ```bash
   # Mode debug
   flutter run

   # Build release
   flutter build apk  # Untuk Android
   flutter build ios  # Untuk iOS
   ```

### Setup Development

1. **Aktifkan dukungan Flutter web** (opsional)
   ```bash
   flutter config --enable-web
   ```

2. **Jalankan test**
   ```bash
   flutter test
   ```

3. **Format kode**
   ```bash
   flutter format lib/
   ```

4. **Analisis kode**
   ```bash
   flutter analyze
   ```

## 📁 Struktur Proyek

```
lib/
├── main.dart                    # Titik masuk aplikasi
├── models/                      # Model data
│   ├── manga_detail.dart        # Model detail manga
│   ├── manga_list_item.dart     # Model item list manga
│   └── user_model.dart          # Model user
├── services/                    # Layer logika bisnis
│   ├── api/
│   │   └── manga_api_service.dart # Komunikasi API
│   └── local/                   # Service data lokal
│       ├── auth_service_local.dart
│       ├── favorites_service.dart
│       ├── history_service.dart
│       └── db_helper.dart
├── views/                       # Layer UI
│   ├── auth/                    # View autentikasi
│   │   ├── login_view.dart
│   │   └── register_view.dart
│   ├── manga/                   # View terkait manga
│   │   ├── home_view.dart       # Layar home
│   │   ├── list_view.dart       # List manga dengan pencarian
│   │   ├── detail_view.dart     # Detail manga
│   │   └── reader_view.dart     # Pembaca chapter
│   ├── reader/                  # View khusus reader
│   │   └── account_reader_view.dart
│   ├── author/                  # View author
│   │   ├── account_author_view.dart
│   │   └── author_setting_view.dart
│   └── core/                    # Komponen UI core
│       ├── main_wrapper.dart    # Wrapper aplikasi utama
│       └── placeholder_view.dart
└── widgets/                     # Widget reusable (jika ada)
```

## 📱 Screenshot

### Layar Home
*Layar home yang indah dengan manga unggulan dan section trending*

### List Manga dengan Pencarian
*Fungsi pencarian dengan filter real-time*

### Pembaca Manga
*Pengalaman membaca chapter yang smooth dengan navigasi*

### Profil Pengguna
*Dashboard pengguna dengan favorit dan riwayat membaca*

*Screenshot akan segera ditambahkan*

## 🔧 Konfigurasi

### Konfigurasi API
Update base URL di `lib/services/api/manga_api_service.dart`:
```dart
static const String baseUrl = 'YOUR_API_BASE_URL';
```

### Konfigurasi Database
Aplikasi menggunakan SQLite untuk penyimpanan lokal. File database disimpan di:
- **Android**: `data/data/com.example.comic_reader/databases/`
- **iOS**: Direktori `Documents/`

## 🤝 Kontribusi

1. Fork repository
2. Buat branch fitur Anda (`git checkout -b fitur/FiturHebat`)
3. Commit perubahan Anda (`git commit -m 'Tambah fitur hebat'`)
4. Push ke branch (`git push origin fitur/FiturHebat`)
5. Buat Pull Request

### Panduan Development
- Ikuti best practices Flutter
- Gunakan pesan commit yang bermakna
- Tulis kode yang bersih dan mudah dibaca
- Tambahkan komentar untuk logika kompleks
- Test perubahan Anda secara menyeluruh

## 📄 Lisensi

Proyek ini dilisensikan di bawah Lisensi MIT - lihat file [LICENSE](LICENSE) untuk detail.

## 🙏 Ucapan Terima Kasih

- **Tim Flutter** untuk framework yang amazing
- **Material Design** untuk sistem desain
- **Laravel API Manga Scraper** untuk menyediakan backend API
- **GetX** untuk state management
- **Cached Network Image** untuk cache gambar

## 📞 Dukungan

Jika Anda memiliki pertanyaan atau masalah, silakan:
- Buat issue di GitHub
- Hubungi maintainer
- Periksa dokumentasi

---

**Dibuat dengan ❤️ menggunakan Flutter**
