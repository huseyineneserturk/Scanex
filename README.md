# Scanex — Optik Form Okuyucu

Scanex, öğretmenler için geliştirilmiş bir mobil optik form okuyucu uygulamasıdır. PDF olarak optik cevap kağıdı oluşturur, telefon kamerasıyla tarayarak otomatik olarak puanlar ve sonuçları Excel'e aktarır.

## Özellikler

- 📝 **Optik Cevap Kağıdı Oluşturma** — A4 boyutunda, 10-20 soruluk, 5 seçenekli (A-E) optik form PDF'i
- 📷 **Kamera ile Tarama** — OMR (Optik İşaret Okuma) ile cevapları otomatik algılama
- 🔢 **9 Haneli Öğrenci Numarası** — OMR grid ile öğrenci numarası kodlama ve okuma
- ✏️ **İsim Okuma (OCR)** — Google ML Kit ile el yazısı isim tanıma
- 📊 **Sonuç Yönetimi** — Sınav bazlı sonuç görüntüleme ve düzenleme
- 📤 **Excel Dışa Aktarma** — Sonuçları .xlsx dosyası olarak paylaşma
- ♾️ **Tamamen Ücretsiz** — Hiçbir sınırlama veya premium özellik yok

## Teknoloji

- **Flutter/Dart** — Cross-platform mobil uygulama
- **Google ML Kit** — OCR (metin tanıma)
- **Pure Dart Image Processing** — OMR motor (piksel bazlı analiz)
- **SQLite** — Yerel veritabanı
- **Provider** — State yönetimi

## Kurulum

```bash
flutter pub get
flutter run
```

## APK Derleme

```bash
flutter build apk --release
```

APK dosyası `build/app/outputs/flutter-apk/app-release.apk` yolunda oluşur.

## Proje Yapısı

```
lib/
├── core/
│   └── constants/      # Sabitler ve tema
├── models/             # Veri modelleri (Exam, ScanResult, StudentAnswer)
├── providers/          # State yönetimi (ExamProvider)
├── screens/            # UI ekranları
│   ├── home_screen.dart
│   ├── generate_sheet_screen.dart
│   ├── answer_key_screen.dart
│   ├── scan_screen.dart
│   ├── score_review_screen.dart
│   └── results_screen.dart
└── services/           # İş mantığı
    ├── pdf_generator_service.dart
    ├── image_processing_service.dart
    ├── ocr_service.dart
    ├── database_service.dart
    └── export_service.dart
```

## Lisans

MIT
