# RealFans için laptop referansları

Araştırma tarihi: **23 Ekim 2026**.

Amaç: Türkiye hedefi için savunulabilir bir başlangıç cihaz grubu seçmek; dış geometri, soğutma yerleşimi ve gerçek test verisi için kullanılabilecek kaynakları toplamak. Bu çalışma herhangi bir cihaz için doğrulanmış soğutma kazancı iddia etmez.

Araştırma öncesi yerel çalışma ağacı temizdi ve GitHub `dev` dalıyla aynı `61500e2a0589644b289e27d1b9c7ce3b08a0d65f` commit'indeydi. Projenin `README.md` ve `ana_mantik.md` dosyaları GitHub üzerinden yeniden okundu. Bu belge dışında CAD, elektronik veya hesap dosyası değiştirilmedi.

## 1. Türkiye'de hangi laptoplar kullanılıyor?

Bu taramada güncel, kamuya açık ve güvenilir **model bazında Türkiye kullanım adedi** veya eksiksiz laptop satış sıralaması bulunamadı. Satılan cihazlar ile kullanımda olan cihazlar aynı nüfusu temsil etmez. Mağaza sıralaması, yorum adedi veya forum görünürlüğü ülke geneline yaygınlık kanıtı olarak kullanılmadı.

- Euromonitor'un **2025** Türkiye bilgisayar ve çevre birimleri raporunun açık özetinde Lenovo kategori lideri olarak anılıyor. Kapsam yalnızca laptoplar değil; model veya ThinkPad serisi payı çıkarmıyor. Raporun tamamı açık erişim değil. [Rapor özeti](https://www.euromonitor.com/computers-and-peripherals-in-turkey/report)
- **29 Nisan 2026** tarihli haberde, Lenovo'nun açıkladığı IDC kaynaklı **2025 toplam PC payı %24,4** olarak aktarılıyor. Bu, 2026 model bazında kullanım sayımı değildir; doğrudan IDC tablosu bu taramada edinilmedi. [Açıklamayı aktaran haber](https://perakende.org/lenovo-6-yildir-turkiye-pc-pazarindaki-liderligini-surduruyor/)
- Arçelik'in **2025 faaliyet raporu**, Türkiye'de oyuncu bilgisayarlarının dizüstü kategorisinin **%37,5**'ini oluşturduğunu belirtiyor. Belge basılı sayfa **101**, PDF sayfa **105**. Bu sektör göstergesi Monster'ın marka veya model payını vermiyor. [Faaliyet raporu](https://news-content.foreks.com/attachments/kap/4028328d9c4c12c8019c7440ad7f7628.pdf#page=105)

Sonuç: Monster'ı oyuncu laptopu örneği olarak araştırmak makul. "Türkiye'de en çok Monster kullanılıyor" sonucu mevcut kaynaklardan çıkarılamaz. İlk adaylar aşağıda **belge erişimi ve farklı soğutma düzenlerini temsil etmesi** nedeniyle seçildi.

## 2. Başlangıç adayları

| Cihaz | Üretici verisi / erişilebilir belge | RealFans için kullanım |
|---|---|---|
| **ThinkPad T14 Gen 5 Intel**, 21ML/21MM | **315,9 × 223,7 × 17,7 mm**. PSREF; resmî bakım kılavuzu; alt görünüş ve parça değiştirme belgeleri. Üretici arka egzozu açıkça anlatıyor. | Küçük iş laptopu ve **arka egzoz** referansı. Mevcut sağ-sol kanatların her laptopa yeterli olduğunu varsaymamak için iyi karşı örnek. |
| **Monster Abra A5 V21.6** | **359,5 × 238 × 22,7 mm**. Üretici **iki fan ve dört bakır ısı borusu** belirtiyor. Resmî Türkçe kullanım kılavuzu bağlantısı var. | Fiziksel erişim sağlanırsa 15,6 inç oyuncu laptopu başlangıç adayı. Bu araştırmada kesin giriş/egzoz koordinatları ve akış yönleri doğrulanmadı. |
| **Monster Tulpar T5 V23.1.2** | **359,5 × 238 × 27,1 mm**. Üretici **iki fan ve altı ısı borusu** belirtiyor. Özgün inceleme, platformu **Clevo NP50SND** olarak tanımlıyor. | Yeni model tercihi olarak değil, belgeli eski bir yüksek yük / çok açıklıklı kasa referansı olarak yararlı. |

### ThinkPad kaynak paketi

- [T14 Gen 5 Intel PSREF](https://psref.lenovo.com/syspool/Sys/PDF/ThinkPad/ThinkPad_T14_Gen_5_Intel/ThinkPad_T14_Gen_5_Intel_Spec.PDF): açılan PDF tarihi **6 Mayıs 2026**; dış ölçüler PDF sayfa **6**. U ve H serisi işlemci seçenekleri bulunuyor. İlk deneyde tam makine tipi/modeli ve işlemci varyantı kaydedilmeli.
- [Lenovo Intel tanıtım dokümanı](https://techtoday.lenovo.com/sites/default/files/2024-03/ThinkPad-T14-Gen5-Datasheet-ww-en.pdf): PDF sayfa **2**, egzoz fanının arkaya alındığını belirtiyor.
- [Ortak Hardware Maintenance Manual](https://download.lenovo.com/pccbbs/mobiles_pdf/t14g5_t16g3_p14sg5_hmm_en.pdf): T14 Gen 5 / T16 Gen 3 / P14s Gen 5 ailesi için doğrudan resmî bağlantı. Yaklaşık 96,6 MB; web okuyucusu tamamını işleyemedi. Bu nedenle bu belgede kılavuzun incelenmemiş iç sayfalarına dayanan ölçü veya FRU numarası kullanılmadı.
- [Resmî alt görünüş çizimleri](https://download.lenovo.com/manual/thinkpad_t14g5_t16g3_p14sg5/ug/html_en/en/Bottom_view.html).
- [Resmî parça sökme/değiştirme sayfası](https://support.lenovo.com/au/en/solutions/ht516591-removal-and-replacement-videos-thinkpad-t14-gen-5-21ml-21mm): termal fan grubu için kaynak.

T14 Gen 5 AMD ayrı bir termal profil olarak ele alınmalı. Aynı dış boyut, aynı iç fan davranışı anlamına gelmez. [AMD PSREF](https://psref.lenovo.com/syspool/Sys/PDF/ThinkPad/ThinkPad_T14_Gen_5_AMD/ThinkPad_T14_Gen_5_AMD_Spec.PDF).

### Monster kaynak paketi

- [Abra A5 V21.6 resmî ürün bilgileri](https://www.monsternotebook.com.tr/abra/monster-abra-a5-v21-6/): boyutlar, kasa ve üreticinin fan/ısı borusu bilgisi.
- [Abra resmî kılavuz sayfası](https://support.monsternotebook.com/tr/product/abra-a5-v216-156-oyun-bilgisayari/user-manuals/): destek sayfası güncellemesi **18 Mayıs 2026**. Türkçe PDF bağlantısı mevcut; PDF bu taramada açılamadı. İçindeki şekiller doğrulanmış veri sayılmadı.
- [Tulpar T5 V23.1.2 resmî ürün bilgileri](https://www.monsternotebook.com.tr/tulpar/monster-tulpar-t5-v23-1-2/): dış ölçüler ve soğutma donanımı.
- [Technopat'ın özgün T5 V23.1.2 incelemesi, 11 Eylül 2023](https://www.technopat.net/2023/09/11/monster-tulpar-t5-v23-1-2-inceleme/): kendi cihaz testi ve Clevo platform kimliği. Performans modunda RDR2 testinde ortalama CPU/GPU **89/87 °C**; Cyberpunk RT Ultra / DLSS Auto'da **96/87 °C** raporlanıyor. Ortam sıcaklığı, BIOS/fan eğrisi, test süresi ve bakım durumu eşleştirilmeden bu sayılar RealFans kazancının referansı yapılamaz. Tek cihaz testi marka geneline sorun oranı vermez.
- [Medion Deputy P50 / NP50SND üretici kılavuzu](https://cdn.medion.com/downloads/anleitungen/bda_p50_deputy_en.pdf): basılı **22–24. sayfalar**, farklı yüzlerdeki havalandırma açıklıklarını gösteren yardımcı platform belgesi. Medion varyantından Monster'a birebir ölçü veya akış yönü aktarılmamalı.

## 3. Şu an gerçekten elde olan ve olmayan veri

| Girdi | Durum |
|---|---|
| Dış kasa boyutları | Yukarıdaki tam modeller için üretici kaynaklarında var. |
| Portlar ve açıklıkların yaklaşık yerleşimi | Ürün görselleri / kullanıcı ve bakım belgelerinden kısmen elde edilebilir. Ölçülü çizim olarak kabul edilmez. |
| Fan ve termal grubun yerleşimi | ThinkPad servis belgeleri ve Monster'ın donanım bilgileri başlangıç sağlar. Tam cihaz varyantıyla eşleştirme gerekir. |
| Gerçek fan üretici parça numarası / FRU | Bu taramada kesinleştirilmedi. Özellikle aynı ürün ailesindeki varyantlar karıştırılmamalı. |
| Fanın basınç–debi eğrisi | Bu laptoplar için doğrulanmış eğri bulunamadı. Genel bir fan sınıfından kopyalanmamalı. |
| Laptopun basınç–debi davranışı | Ölçülmüş veri edinilmedi. İç fanın katkısı ve fan kontrol durumu birlikte ele alınmalı. |
| Ölçülü iç STEP/CAD veya üretici CFD modeli | Bu taramada bulunamadı. Fotoğraf veya pazarlama görseli böyle bir modelin yerine geçmez. |
| CPU/GPU ısıl davranışı | Özgün inceleme ölçümleri ipucu verir; kendi cihazında kontrollü test ve kalibrasyon gerekir. |

## 4. Projenin dokümanlarıyla bağlantı

`ana_mantik.md` ilk olarak mekanizmaların geniş bir tezgâhta ölçülmesini istiyor. Bu kaynak araştırması o deney aşamasına cihaz seçimi ve geometri bilgisi sağlar. Hazır iç model bulunmadığı için deney aşaması atlanmamalı.

- ThinkPad'in arka egzozu, ana belgedeki **M5 / ayrı arka egzoz prototipi** ihtiyacını somutlaştırıyor.
- Genişliği ayarlamak, alt girişleri veya egzoz yüksekliğini kendiliğinden eşleştirmiyor. Her aday için dış açıklık haritası gerekiyor.
- Mevcut hesap kütüphanesindeki sabit **135 W** referans, bu cihazların ölçülmüş yükü olarak kullanılmamalı.
- Servis kılavuzu elde etmek, hava akışını veya sıcaklık kazancını doğrulamaz.

## 5. İlk veri toplama planı

1. Fiziksel erişimi olan **bir Monster ve bir arka egzozlu ThinkPad** seç; tam model, işlemci/GPU, BIOS ve fan modunu kaydet. Yeni cihaz satın almak bu araştırmanın önkoşulu değil.
2. Dışarıdan ölç: kasa, ayaklar, alt girişlerin alanı ve sınırı, yan/arka açıklıkların yeri ve yüksekliği, conta oturabilecek yüzeyler, portların çevresindeki boşluklar.
3. Aynı cihazda masa, aynı yükseklikte fan kapalı, contasız fan, contalı fan ve ek egzoz modülü durumlarını karşılaştır. Ortam, gerçek CPU/GPU gücü, sıcaklık, performans ve mümkünse fan devri birlikte kaydedilmeli.
4. Akış simülasyonunda ilk hedefi conta kaçağı, plenum basıncı ve girişlere dağılan debi yap. İç laptop davranışını belirsizlik aralığıyla temsil et; basınç/debi ölçümü elde edilirse eşdeğer modeli buna göre kalibre et.
5. Kalibrasyon yapılmayan ayrı bir yük veya ikinci cihazda tahmini sınamadan genel uyumluluk / derece kazancı iddiasına geçme.

Bu araştırma ile **kaynaklı bir geometri ve test başlangıcı** elde edildi. Fan eğrisi, kesin açıklık ölçüleri ve doğrulanmış soğutma performansı hâlâ ölçüm gerektiriyor.
