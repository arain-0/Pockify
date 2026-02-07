# Pockify

Sosyal medya içeriklerini kaydet, her zaman eriş.

> **Not:** Bu proje henüz geliştirme aşamasındadır.

## Ekran Görüntüleri

<p align="center">
  <img src="screenshots/splash.png" width="200" />
  <img src="screenshots/home.png" width="200" />
  <img src="screenshots/settings.png" width="200" />
</p>

## Özellikler

- TikTok, Instagram, YouTube, Twitter video kaydetme
- Çevrimdışı izleme
- Kolay kullanımlı arayüz
- Premium özellikleri

## Desteklenen Platformlar

| Platform | Durum |
|----------|-------|
| TikTok | Aktif |
| Instagram | Aktif |
| YouTube | Aktif |
| Twitter/X | Aktif |
| Facebook | Aktif |
| Reddit | Aktif |
| Vimeo | Aktif |

## Kurulum

```bash
# Bağımlılıkları yükle
flutter pub get

# Uygulamayı çalıştır
flutter run
```

## API Yapılandırması

`lib/core/config/api_config.dart` dosyasında RapidAPI key'inizi ayarlayın:

```dart
static const String rapidApiKey = 'YOUR_RAPIDAPI_KEY';
```

## Teknolojiler

- Flutter
- BLoC State Management
- Hive (Local Storage)
- Dio (HTTP Client)

## Lisans

MIT License
