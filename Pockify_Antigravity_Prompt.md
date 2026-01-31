# 🚀 POCKIFY - TikTok & Instagram Video Downloader App
## Antigravity AI Development Prompt

---

## 📋 PROJE ÖZETI

**Uygulama Adı:** Pockify
**Slogan:** "Cebine Al, Her Yerde İzle" / "Pocket Your Favorites"
**Platform:** Flutter (Android + iOS)
**Kategori:** Tools / Utilities
**Hedef Kitle:** 16-35 yaş, sosyal medya içerik tüketicileri, içerik editörleri

---

## 🎨 MARKA KİMLİĞİ

### Logo Tasarımı
- **İkon Konsepti:** Aşağı ok işareti içeren stilize cep (pocket) şekli
- **Stil:** Minimalist, modern, flat design
- **Şekil:** Rounded square (app icon uyumlu)
- **Ana Element:** Cep + indirme oku kombinasyonu
- **İkon Boyutları:** 512x512, 192x192, 144x144, 96x96, 72x72, 48x48

### Renk Paleti
```
Primary Color:      #6C5CE7 (Soft Purple - güven, yaratıcılık)
Secondary Color:    #A29BFE (Light Purple - modern his)
Accent Color:       #00D9FF (Cyan - dikkat çekici CTA'lar)
Background Dark:    #1A1A2E (Koyu arka plan)
Background Light:   #F8F9FA (Açık mod)
Success:            #00D68F (İndirme başarılı)
Error:              #FF6B6B (Hata durumları)
Text Primary:       #FFFFFF (Koyu modda)
Text Secondary:     #B4B4C7 (İkincil metinler)
```

### Tipografi
```
Headlines:          Poppins Bold / Semi-Bold
Body Text:          Inter Regular / Medium
Numbers/Stats:      SF Pro Display / Roboto Mono
```

### UI Tarzı
- Dark mode varsayılan (kullanıcıların %60'ı tercih ediyor)
- Light mode opsiyonel
- Glassmorphism efektleri (blur, transparency)
- Rounded corners (16px radius)
- Soft shadows
- Micro-interactions ve haptic feedback
- Bottom navigation (tek elle kullanım)

---

## 📱 UYGULAMA MİMARİSİ

### Ekran Yapısı

```
lib/
├── main.dart
├── app/
│   ├── app.dart
│   └── routes.dart
├── core/
│   ├── theme/
│   │   ├── app_colors.dart
│   │   ├── app_theme.dart
│   │   └── app_typography.dart
│   ├── constants/
│   │   └── app_constants.dart
│   └── utils/
│       ├── link_parser.dart
│       └── file_helper.dart
├── features/
│   ├── home/
│   │   ├── home_screen.dart
│   │   └── widgets/
│   ├── downloads/
│   │   ├── downloads_screen.dart
│   │   └── widgets/
│   ├── settings/
│   │   └── settings_screen.dart
│   └── premium/
│       └── premium_screen.dart
├── services/
│   ├── download_service.dart
│   ├── storage_service.dart
│   ├── ad_service.dart
│   └── purchase_service.dart
└── models/
    ├── video_model.dart
    └── download_model.dart
```

### Ana Ekranlar

#### 1. Home Screen (Ana Ekran)
- Üstte Pockify logosu
- Ortada büyük "Link Yapıştır" alanı
- "Yapıştır" butonu (otomatik clipboard algılama)
- Son indirilenler (horizontal scroll)
- Alt navigasyon bar

#### 2. Downloads Screen (İndirilenler)
- Grid veya liste görünümü toggle
- Video thumbnail + bilgi
- Paylaş, sil, tekrar indir butonları
- Arama ve filtreleme
- Çoklu seçim modu

#### 3. Settings Screen (Ayarlar)
- İndirme kalitesi seçimi
- İndirme klasörü
- Tema seçimi (Dark/Light/System)
- Dil seçimi
- Premium durumu
- Gizlilik politikası
- Kullanım şartları
- Uygulama versiyonu
- Destek/İletişim

#### 4. Premium Screen (Premium)
- Mevcut plan durumu
- Plan karşılaştırma tablosu
- Özellik listesi
- Satın alma butonları
- Geri yükleme butonu

---

## ⚙️ TEMEL ÖZELLİKLER

### Free Versiyon
- ✅ Günde 3 video indirme hakkı
- ✅ 720p maksimum kalite
- ✅ TikTok desteği
- ✅ Instagram Reels desteği
- ✅ Watermark ile indirme (uygulama watermark'ı değil, orijinal platform watermark'ı)
- ✅ Temel video oynatıcı
- ⚠️ Interstitial reklamlar (her 2 indirmede 1)
- ⚠️ Banner reklamlar

### Premium Versiyon
- ✅ Sınırsız indirme
- ✅ 1080p / 4K kalite
- ✅ Watermark kaldırma (platform watermark'ı)
- ✅ Batch indirme (birden fazla link)
- ✅ Özel indirme klasörü
- ✅ Öncelikli işleme
- ✅ Reklam yok
- ✅ MP3 çıkarma (ses indirme)
- ✅ Gizli klasör (şifreli)
- ✅ Otomatik yedekleme (Google Drive / iCloud)
- ✅ Öncelikli destek

---

## 💰 FİYATLANDIRMA STRATEJİSİ

### Rakip Analizi Sonuçları
| Rakip | Haftalık | Aylık | Yıllık | Lifetime |
|-------|----------|-------|--------|----------|
| SnapTik | $4.99 | - | - | $29-80 |
| Video Downloader Apps | $3.99 | $8.99 | $17.99 | - |
| 4K Video Downloader | - | - | $15/yıl | $42 |
| Ortalama | $4-5 | $8-10 | $15-20 | $30-80 |

### Pockify Fiyatlandırması (TL)

```
┌─────────────────────────────────────────────────────────────┐
│                     POCKIFY PREMIUM                          │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  🔥 EN POPÜLER                                               │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  YILLIK PLAN                                        │    │
│  │  ₺149.99/yıl                                        │    │
│  │  (₺12.50/ay - %58 tasarruf)                         │    │
│  │  ✓ 3 Günlük Ücretsiz Deneme                         │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                              │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  AYLIK PLAN                                         │    │
│  │  ₺29.99/ay                                          │    │
│  │  ✓ İstediğin zaman iptal et                         │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                              │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  HAFTALIK PLAN                                      │    │
│  │  ₺14.99/hafta                                       │    │
│  │  ✓ 3 Günlük Ücretsiz Deneme                         │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                              │
│  💎 LIFETIME (Ömür Boyu)                                     │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  TEK SEFERLIK                                       │    │
│  │  ₺399.99                                            │    │
│  │  ✓ Bir kere öde, sonsuza kadar kullan               │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### USD Karşılıkları (Global Market)
- Haftalık: $0.99
- Aylık: $2.99
- Yıllık: $9.99
- Lifetime: $24.99

### Reklam Stratejisi
- **Banner Reklamlar:** Ana ekran alt kısmı (320x50)
- **Interstitial:** Her 2 başarılı indirmede 1 (5 saniyelik skip)
- **Rewarded Video:** Ekstra indirme hakkı için opsiyonel
- **Reklam Ağı:** Google AdMob + Meta Audience Network

---

## 🛡️ STORE POLİTİKASI UYUMLULUK (KRİTİK!)

### ÖNEMLİ UYARILAR

Bu uygulama "link yöneticisi" ve "medya organizatörü" olarak konumlandırılmalıdır. Doğrudan "downloader" ifadesi kullanılmamalıdır.

### App Store Açıklaması İçin Güvenli Dil

```
KULLANILMAMASI GEREKEN İFADELER:
❌ "Download TikTok videos"
❌ "Save without watermark"
❌ "Remove watermark"
❌ "Download copyrighted content"
❌ "Bypass restrictions"

KULLANILMASI GEREKEN İFADELER:
✅ "Organize your favorite video links"
✅ "Manage your media collection"
✅ "Save links for later viewing"
✅ "Personal media library"
✅ "Bookmark video content"
✅ "Access your saved content offline"
```

### Zorunlu Disclaimers

```
UYGULAMA İÇİ DISCLAIMER (Açılışta gösterilecek):

"Pockify, kullanıcıların kendi içeriklerini veya izin aldıkları 
içerikleri yönetmeleri için tasarlanmıştır. 

⚠️ Telif hakkı olan içeriklerin izinsiz indirilmesi ve 
dağıtılması yasaktır.

⚠️ Bu uygulama TikTok, Instagram veya herhangi bir sosyal 
medya platformuyla bağlantılı değildir.

⚠️ İçeriklerin yasal kullanımından tamamen kullanıcı sorumludur.

Devam ederek Kullanım Şartlarını ve Gizlilik Politikasını 
kabul etmiş olursunuz."

[Kabul Ediyorum] butonu
```

### Gizlilik Politikası Gereksinimleri
- Toplanan veriler (analytics, crash reports)
- Veri saklama süresi
- Üçüncü taraf paylaşımları (reklam ağları)
- Kullanıcı hakları (silme, dışa aktarma)
- KVKK / GDPR uyumluluğu
- Çocuk güvenliği (13 yaş altı kullanmaz)

---

## 📦 FLUTTER PAKETLERI

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  flutter_bloc: ^8.1.3
  
  # Network
  dio: ^5.4.0
  
  # Storage
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  path_provider: ^2.1.2
  
  # Media
  video_player: ^2.8.2
  chewie: ^1.7.4
  
  # Permissions
  permission_handler: ^11.2.0
  
  # Clipboard
  clipboard: ^0.1.3
  
  # Sharing
  share_plus: ^7.2.1
  
  # Monetization
  google_mobile_ads: ^4.0.0
  in_app_purchase: ^3.1.13
  
  # UI Components
  flutter_svg: ^2.0.9
  cached_network_image: ^3.3.1
  shimmer: ^3.0.0
  lottie: ^3.0.0
  
  # Utils
  url_launcher: ^6.2.3
  package_info_plus: ^5.0.1
  connectivity_plus: ^5.0.2
  
  # Analytics
  firebase_core: ^2.24.2
  firebase_analytics: ^10.8.0
  firebase_crashlytics: ^3.4.8
```

---

## 🔄 UYGULAMA AKIŞI

```
┌──────────────────────────────────────────────────────────┐
│                    UYGULAMA AKIŞI                         │
└──────────────────────────────────────────────────────────┘

1. AÇILIŞ
   │
   ├── Splash Screen (2 saniye) + Logo animasyonu
   │
   ├── İlk açılış mı?
   │   ├── EVET → Onboarding (3 slide)
   │   │          │
   │   │          ├── Slide 1: "Linki Kopyala"
   │   │          ├── Slide 2: "Yapıştır ve İndir"
   │   │          └── Slide 3: "Koleksiyonunu Oluştur"
   │   │
   │   └── HAYIR → Ana Ekrana git
   │
   └── Disclaimer kabul edildi mi?
       ├── HAYIR → Disclaimer göster
       └── EVET → Devam

2. ANA EKRAN
   │
   ├── Clipboard'da link var mı?
   │   └── EVET → "Link algılandı, indirmek ister misin?" toast
   │
   ├── Kullanıcı link yapıştırır
   │   │
   │   ├── Link geçerli mi?
   │   │   ├── HAYIR → Hata mesajı
   │   │   └── EVET → Platform tespiti
   │   │
   │   ├── Premium kullanıcı mı?
   │   │   ├── HAYIR → Günlük limit kontrol (3/gün)
   │   │   │          ├── Limit doldu → Premium teklif
   │   │   │          └── Limit var → Reklam göster → İndir
   │   │   │
   │   │   └── EVET → Direkt indir (reklamız, yüksek kalite)
   │   │
   │   └── İndirme başarılı
   │       └── "İndirilenler" klasörüne kaydet
   │
   └── Bottom Navigation
       ├── Ana Sayfa (aktif)
       ├── İndirilenler
       ├── Premium
       └── Ayarlar

3. İNDİRME SÜRECİ
   │
   ├── Progress göster (circular + percentage)
   │
   ├── Başarılı
   │   ├── Bildirim gönder
   │   ├── Galeriye kaydet
   │   └── "İndirilenler"e ekle
   │
   └── Başarısız
       ├── Retry butonu
       └── Hata detayı (geliştirici için log)

4. PREMIUM AKIŞI
   │
   ├── Plan seç
   ├── App Store / Play Store ödeme
   ├── Doğrulama
   └── Premium özellikler aktif
```

---

## 📝 APP STORE AÇIKLAMASI

### Başlık
**Pockify - Video Link Manager**

### Alt Başlık
Organize & Access Your Favorite Videos

### Açıklama (Türkçe)
```
📱 Pockify ile favori video linklerinizi kolayca yönetin!

Pockify, sosyal medyadaki sevdiğiniz videoların linklerini 
düzenli bir şekilde saklamanızı sağlayan akıllı bir medya 
organizatörüdür.

✨ TEMEL ÖZELLİKLER
• Hızlı link ekleme - sadece yapıştır
• Akıllı kategorizasyon
• Offline erişim için medya yönetimi
• Koyu ve açık tema desteği
• Gizli klasör (şifreli)

🔒 GÜVENLİ & GİZLİ
• Verileriniz cihazınızda kalır
• Hesap gerektirmez
• Tamamen anonim kullanım

⚡ PREMIUM ÖZELLİKLER
• Sınırsız link yönetimi
• Yüksek kalite önizleme
• Reklamsız deneyim
• Bulut yedekleme
• Öncelikli destek

NOT: Bu uygulama telif hakkı sahiplerinin haklarına saygı 
gösterir. Lütfen yalnızca izin aldığınız içerikleri kaydedin.

Sorularınız için: support@pockify.app
```

### Anahtar Kelimeler
```
video,link,manager,organizer,bookmark,save,media,collection,
offline,tiktok,reels,social,content,library,favorites
```

---

## 🔧 TEKNİK NOTLAR

### API Yaklaşımı (Antigravity İçin)
```
Link işleme için web scraping yerine:
1. Kullanıcı linki yapıştırır
2. Uygulama linki parse eder (platform tespiti)
3. Embed URL veya API endpoint'e yönlendirir
4. Medya bilgilerini çeker (thumbnail, duration, title)
5. İndirme URL'si oluşturur
6. Dosyayı cihaza kaydeder

NOT: Doğrudan platform API'ları kullanılmamalı.
Üçüncü parti servisler tercih edilmeli (örn: cobalt.tools API)
```

### Güvenlik
- SSL pinning (network güvenliği)
- ProGuard/R8 obfuscation (Android)
- Jailbreak/Root detection
- API key encryption
- Secure storage for premium status

---

## 📊 HEDEF METRİKLER (6 Ay)

| Metrik | Hedef |
|--------|-------|
| Toplam İndirme | 100,000 |
| DAU (Günlük Aktif) | 15,000 |
| Premium Dönüşüm | %3-5 |
| Aylık Gelir | ₺50,000 - ₺100,000 |
| App Store Rating | 4.5+ |
| Crash-Free Rate | %99.5+ |

---

## ✅ GELİŞTİRME CHECKLIST

### Faz 1: MVP (2-3 Hafta)
- [ ] Proje yapısı kurulumu
- [ ] Tema ve renk paleti implementasyonu
- [ ] Ana ekran UI
- [ ] Link yapıştırma ve parse etme
- [ ] Temel indirme fonksiyonu (TikTok)
- [ ] İndirilenler ekranı
- [ ] Local storage (Hive)
- [ ] Temel navigasyon

### Faz 2: Monetizasyon (1 Hafta)
- [ ] AdMob entegrasyonu
- [ ] In-App Purchase kurulumu
- [ ] Premium ekranı
- [ ] Günlük limit sistemi
- [ ] Reklam gösterim mantığı

### Faz 3: Polish (1 Hafta)
- [ ] Onboarding ekranları
- [ ] Animasyonlar ve micro-interactions
- [ ] Error handling
- [ ] Loading states
- [ ] Empty states
- [ ] Disclaimer ve legal sayfalar

### Faz 4: Test & Launch (1 Hafta)
- [ ] Unit tests
- [ ] Integration tests
- [ ] Beta testing
- [ ] Store görselleri hazırlama
- [ ] Store açıklamaları
- [ ] Submit to stores

---

## 🎯 BAŞARININ ANAHTARLARI

1. **Hız:** İndirme süresi rakiplerden kısa olmalı
2. **Basitlik:** Tek tıkla indirme deneyimi
3. **Güvenilirlik:** Platform değişikliklerine hızlı adaptasyon
4. **Tasarım:** Modern ve kullanıcı dostu arayüz
5. **Fiyatlandırma:** Rekabetçi ama karlı

---

## ⚠️ RİSKLER VE ÖNLEMLER

| Risk | Olasılık | Etki | Önlem |
|------|----------|------|-------|
| Store reddi | Orta | Yüksek | Dili dikkatli kullan, disclaimer ekle |
| Platform API değişikliği | Yüksek | Yüksek | Çoklu servis desteği, hızlı güncelleme |
| Telif hakkı şikayeti | Düşük | Orta | Kullanıcı sorumluluğu disclaimer'ı |
| Reklam geliri düşüklüğü | Orta | Orta | Premium'a yönlendirme |

---

## 📞 DESTEK BİLGİLERİ

- **Email:** support@pockify.app
- **Website:** https://pockify.app
- **Privacy Policy:** https://pockify.app/privacy
- **Terms of Service:** https://pockify.app/terms

---

**Bu döküman Antigravity AI ile Pockify uygulamasının tek seferde oluşturulması için hazırlanmıştır. Tüm teknik detaylar, tasarım kararları ve iş modeli bu prompt'ta yer almaktadır.**

*Son Güncelleme: Ocak 2026*
