# Çoklu Blog Uygulaması

Bu proje, Flutter ve Firebase altyapısı kullanarak çoklu yazar desteği, gerçek zamanlı beğeni/yorum sistemi ve zengin metin düzenleyiciyle çalışan, çoklu blog deneyimi sunan bir platform.

## Özellikler

- **Çoklu Yazar Desteği**  
  - Her kullanıcı kendi profilinden yazı ekleyebilir, düzenleyebilir ve silebilir.  
- **Gerçek Zamanlı Veri Güncelleme**  
  - Firebase Firestore ile anlık beğeni ve yorum güncellemeleri.  
- **Zengin Metin Düzenleyici**  
  - Başlık, alt başlık, kalın/italik metin ve bağlantı ekleme imkânı.  
- **Profil Sayfası**  
  - Yazarlara özel profil; profil fotoğrafı, biyografi ve yazı listesi görüntüleme.  
- **Arama & Filtreleme**  
  - Başlığa veya etikete göre hızlı arama.  

## Kullanım

1. Uygulamayı açtığınızda anasayfada en son paylaşılan yazılar listelenir.  
2. Sağ üst köşedeki “+” ikonuna tıklayarak yeni bir yazı oluşturabilirsiniz.  
3. Yazı detay sayfasında beğeni ve yorum yapabilirsiniz.  
4. Profil sayfanızdan eski yazılarınızı görüntüleyip düzenleyebilirsiniz.  
5. Arama çubuğuna yazar adı, başlık veya etiket yazarak içerik araması yapabilirsiniz.

## Proje Yapısı
```
lib/
├─ Components/
│ └─ cardPost.dart # Yazı kartı bileşeni
├─ Pages/
│ ├─ home.dart # Anasayfa
│ ├─ login.dart # Giriş ekranı
│ ├─ post.dart # Yazı detay sayfası
│ ├─ postAdd.dart # Yeni yazı oluşturma
│ ├─ postAddFinal.dart # Yazı önizleme ve yayınlama
│ ├─ postEdit.dart # Yazı düzenleme
│ ├─ profile.dart # Profil görüntüleme
│ ├─ profileEdit.dart # Profil düzenleme
│ ├─ search.dart # Arama sayfası
│ └─ signUp.dart # Kayıt ekranı
├─ function.dart # Ortak yardımcı fonksiyonlar
├─ functionFire.dart # Firebase etkileşim fonksiyonları
└─ main.dart # Uygulama giriş noktası
```

## İletişim
- LinkedIn: [Baran Kanat](https://www.linkedin.com/in/baran-kanat)
