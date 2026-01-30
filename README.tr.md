# DodoCount

macOS için şık bir Google Analytics 4 ve Search Console menü çubuğu uygulaması.

![macOS](https://img.shields.io/badge/macOS-14.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.0-orange)
![License](https://img.shields.io/badge/Lisans-MIT-green)

## Özellikler

- **Gerçek zamanlı ziyaretçi takibi** - Aktif kullanıcıları doğrudan menü çubuğunuzda görün
- **Google Analytics 4 entegrasyonu** - GA4 mülkleri için tam destek
- **Search Console verileri** - Tıklama, gösterim, TO ve konum takibi
- **Bugün - Dün karşılaştırması** - Kullanıcılar, oturumlar, sayfa görüntüleme, hemen çıkma oranı, süre
- **28 günlük özet** - Trend görselleştirmesi ile genişletilmiş metrikler
- **En çok ziyaret edilen sayfalar ve trafik kaynakları** - Neyin işe yaradığını görün
- **Çoklu mülk desteği** - GA4 mülkleri arasında kolayca geçiş yapın
- **Güzel koyu tema** - macOS estetiğine uygun cam efektli tasarım
- **İstatistik paylaşımı** - Hızlı, detaylı veya Slack formatında istatistikleri kopyalayın
- **Uyarılar** - Trafik artışları, düşüşleri ve hedef başarıları için bildirim alın
- **Global kısayol tuşu** - Cmd+Shift+G ile hızlı erişim
- **Çoklu dil desteği** - İngilizce, Türkçe, Almanca, Fransızca, İspanyolca

## Gereksinimler

- macOS 14.0 veya üstü
- OAuth 2.0 kimlik bilgilerine sahip Google Cloud projesi
- Google Analytics 4 mülkü
- (İsteğe bağlı) Google Search Console sitesi

## Kurulum

1. En son sürümü [Releases](https://github.com/DodoApps/dodocount/releases) sayfasından indirin
2. DodoCount.app dosyasını Uygulamalar klasörüne taşıyın
3. DodoCount'u başlatın

## Yapılandırma

### 1. Google Cloud OAuth Kimlik Bilgileri Oluşturma

1. [Google Cloud Console](https://console.cloud.google.com/apis/credentials) adresine gidin
2. Yeni bir proje oluşturun veya mevcut birini seçin
3. Aşağıdaki API'leri etkinleştirin:
   - Google Analytics Data API
   - Google Analytics Admin API
   - Google Search Console API
4. OAuth 2.0 kimlik bilgileri oluşturun:
   - Uygulama türü: **iOS** (masaüstü uygulamaları için gerekli)
   - Bundle ID: `com.dodocount`
5. İstemci Kimliğinizi kopyalayın

### 2. DodoCount'u Yapılandırma

1. Menü çubuğundaki DodoCount simgesine tıklayın
2. Ayarlar'ı açmak için dişli simgesine tıklayın
3. İstemci Kimliğinizi "Google Cloud" bölümüne yapıştırın
4. Google ile kimlik doğrulaması için "Giriş yap"a tıklayın
5. Açılır listeden GA4 mülkünüzü seçin

## Kullanım

- Panoyu açmak için menü çubuğu simgesine **sol tıklayın**
- Hızlı işlemler için **sağ tıklayın** (istatistik kopyalama, yenileme, ayarlar, çıkış)
- Her yerden panoyu açmak/kapatmak için **Cmd+Shift+G**

## Kaynak Koddan Derleme

```bash
git clone https://github.com/DodoApps/dodocount.git
cd dodocount
open DodoCount.xcodeproj
```

Xcode'da derleyin ve çalıştırın (Xcode 15.0+ gerektirir).

## Katkıda Bulunma

Katkılarınızı bekliyoruz! Pull Request göndermekten çekinmeyin.

## Lisans

MIT Lisansı - detaylar için [LICENSE](LICENSE) dosyasına bakın.

## Telif Hakkı

© 2026 DodoApps

---

**Diğer diller:** [English](README.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | [Español](README.es.md)
