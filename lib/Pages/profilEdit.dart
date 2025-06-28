import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloudinary/cloudinary.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

//pages
import 'profil.dart';

class profilEdit extends StatelessWidget {
  final String userId;

  const profilEdit({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: Colors.black), // Sol tarafta geri ok ikonu
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => Profil(
                        userId: userId,
                      )), // Yeni sayfaya yönlendirme
            );
          },
        ),
        title: Text(""),
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(child: contentProfilEdit()),
    );
  }
}

class contentProfilEdit extends StatefulWidget {
  const contentProfilEdit({super.key});

  @override
  State<contentProfilEdit> createState() => _contentProfilEditState();
}

class _contentProfilEditState extends State<contentProfilEdit> {
  /* DEGISKENLER (START) */
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _isimController = TextEditingController();
  final TextEditingController _soyisimController = TextEditingController();
  final TextEditingController _meslekController = TextEditingController();
  final TextEditingController _hakkindaController = TextEditingController();
  final TextEditingController _telefonController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _notificationsEnabled = false;

  String? _profilResmiUrl;

  //sifre guncelleme degiskenleri
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmNewPasswordController =
      TextEditingController();
  /* DEGISKENLER (END) */

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /* FONKSIYONLAR (START) */
  // Sifre güncelleme fonksiyonu
  Future<void> _updatePassword() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (_currentPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty ||
        _confirmNewPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lütfen tüm alanları doldurun.')),
      );
      return;
    }

    if (_newPasswordController.text != _confirmNewPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Yeni şifreler eşleşmiyor.')),
      );
      return;
    }

    try {
      // Kullanıcının mevcut şifresini doğrulama
      AuthCredential credential = EmailAuthProvider.credential(
          email: user!.email!, password: _currentPasswordController.text);

      await user.reauthenticateWithCredential(credential);

      // Yeni şifreyi güncelleme
      await user.updatePassword(_newPasswordController.text);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Şifre başarıyla güncellendi!')),
      );

      // Alanları temizleme
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmNewPasswordController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Şifre güncellenirken bir hata oluştu: $e')),
      );
    }
  }

  //isaret bilgisi
  Future<void> _updateIsaret(bool value) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('Kullanici')
            .doc(user.uid)
            .update({
          'isaret': value ? '1' : '0', // İşaret durumu güncelleniyor
        });

        setState(() {
          _notificationsEnabled = value; // Ekranda durumu güncelle
        });
        /*
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('İşaret durumu başarıyla güncellendi!')),
        );*/
      } catch (e) {
        /* ScaffoldMessenger.of(context).showSnackBar(
          
          SnackBar(
              content:
                  Text('İşaret durumu güncellenirken bir hata oluştu: $e')),
        );*/
      }
    }
  }

  //Aktif olan kullanicini bilgilerini getiren fonksiyon
  Future<void> _loadUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('Kullanici')
          .doc(user.uid)
          .get();

      print("Ad: " + snapshot['isim']);

      setState(() {
        _isimController.text = snapshot['isim'] ?? '';
        _soyisimController.text = snapshot['soyisim'] ?? '';
        _meslekController.text = snapshot['meslek'] ?? '';
        _hakkindaController.text = snapshot['hakkinda'] ?? '';
        _telefonController.text = snapshot['telefon'] ?? '';
        _profilResmiUrl = snapshot['resim'];
        _emailController.text = snapshot['email'] ?? 'none@gmail.com';
        _notificationsEnabled = snapshot['isaret'] == '1';
      });
    }
  }

  //kullanici bilgilerini guncelleyen fonksiyon
// Kullanıcı bilgilerini güncelleyen fonksiyon
  Future<void> _updateUserData() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (_telefonController.text.isEmpty ||
        _isimController.text.isEmpty ||
        _soyisimController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _hakkindaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('lütfen zorunlu alanları doldurun.')),
      );

      return;
    }

    print("burda2" + user.toString());
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('Kullanici')
            .doc(user.uid)
            .update({
          'isim': _isimController.text,
          'soyisim': _soyisimController.text,
          'meslek': _meslekController.text,
          'hakkinda': _hakkindaController.text,
          'telefon': _telefonController.text,
          'resim': _profilResmiUrl ?? '', // Profil resmi varsa güncelle
        });

        // Başarılı mesajı
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bilgiler başarıyla güncellendi!')),
        );
      } catch (e) {
        // Hata mesajı
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Bilgiler güncellenirken bir hata oluştu: $e')),
        );
      }
    } else {
      // Kullanıcı oturumu açık değilse
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kullanıcı oturumu açık değil!')),
      );
    }
  }

  //Profil resmini resim servise yukleyen fonksiyon
  Future<void> _uploadProfileImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final cloudinary = Cloudinary.signedConfig(
        apiKey: '353584541952588',
        apiSecret: '9x8D8h9idy1gcN6uQ8gy90GeSrU',
        cloudName: 'dvdu0szku',
      );

      final response = await cloudinary.upload(
        file: image.path,
        fileBytes: await image.readAsBytes(),
        resourceType: CloudinaryResourceType.image,
      );

      if (response.isSuccessful) {
        setState(() {
          _profilResmiUrl = response.secureUrl; // Yeni profil resmi URL'si
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profil resmi başarıyla yüklendi!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Resim yükleme başarısız oldu!')),
        );
      }
    }
  }
  /* FONKSIYONLAR (END) */

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _uploadProfileImage, // Resim yükleme fonksiyonu
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: _profilResmiUrl != null
                          ? NetworkImage(_profilResmiUrl!)
                          : AssetImage('assets/images/demoUser.png')
                              as ImageProvider,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.flip_camera_ios,
                          color: Colors.white.withOpacity(0.8),
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(
            height: 25,
          ),

          /* Ad ve Soyad */
          Row(
            children: [
              // Ad
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /** ad */
                    Text(
                      'Ad',
                      style: GoogleFonts.roboto(
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _isimController,
                      decoration: InputDecoration(
                        hintText: 'Adınızı girin',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ad alanı boş bırakılamaz.';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16), // İki alan arasındaki boşluk

              // Soyad
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /** soyad */
                    Text(
                      'Soyad',
                      style: GoogleFonts.roboto(
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _soyisimController,
                      decoration: InputDecoration(
                        hintText: 'Soyadınızı girin',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Soyad alanı boş bırakılamaz.';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(
            height: 10,
          ),

          /** eposta */
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start, // Sola hizalamak için
                  children: [
                    Text(
                      'E-Posta',
                      style: GoogleFonts.roboto(
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    SizedBox(height: 8), // Üst ve alt öğe arasında boşluk
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        hintText: "Degistirilemez",
                        filled: true, // Arka planı doldur
                        fillColor: Colors.grey[200], // Gri renk tonu
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Soyad alanı boş bırakılamaz.';
                        }
                        return null;
                      },
                      readOnly: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(
            height: 20,
          ),

          /** telefon ve meslek */

          Row(
            children: [
              // Telefon Numarası
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /** Telefon Numarası */
                    Text(
                      'Telefon Numarası',
                      style: GoogleFonts.roboto(
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      controller:
                          _telefonController, // Telefon numarası için controller
                      decoration: InputDecoration(
                        hintText: 'Telefon numaranızı girin',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Telefon numarası alanı boş bırakılamaz.';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16), // İki alan arasındaki boşluk

              // Meslek
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /** Meslek */
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Meslek ', // Ana metin (Meslek)
                            style: GoogleFonts.roboto(
                              fontWeight:
                                  FontWeight.normal, // Ana metnin font boyutu
                            ),
                          ),
                          TextSpan(
                            text: '(zorunlu Değil)', // Alt metin
                            style: GoogleFonts.roboto(
                              fontWeight: FontWeight.normal,
                              fontSize: 12, // Alt metnin daha küçük boyutu
                              color: Colors.grey, // Gri renkle vurgulamak için
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _meslekController, // Meslek için controller
                      decoration: InputDecoration(
                        hintText: 'Mesleğinizi girin',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          /** telefon ve meslek */
          
          SizedBox(
            height: 20,
          ),

          /** Hakkinda */
          Column(
            crossAxisAlignment: CrossAxisAlignment.start, // Sola hizala
            children: [
              // Başlık
              Text(
                'Hakkında',
                style: GoogleFonts.roboto(
                  fontWeight: FontWeight.normal,
                ),
              ),
              SizedBox(height: 4),

              // Açıklama
              Text(
                'Kendiniz hakkında birkaç cümle yazabilirsiniz.',
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  color: Colors.grey[600], // Açıklama rengini gri yap
                ),
              ),
              SizedBox(height: 8),

              // Çok satırlı TextFormField
              TextFormField(
                controller:
                    _hakkindaController, // Hakkında metni için controller
                maxLines: 5, // Çok satırlı giriş alanı
                decoration: InputDecoration(
                  hintText: 'Kendinizi tanıtın...',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Hakkında alanı boş bırakılamaz.';
                  }
                  return null;
                },
              ),
            ],
          ),
          /** Hakkinda */

          SizedBox(
            height: 20,
          ),
          /** buton */
          OutlinedButton(
            onPressed: _updateUserData,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.black), // Kenarlık rengi
              backgroundColor: Colors.black, // Dolgu rengi
              foregroundColor: Colors.white, // Yazı rengi
            ),
            child: Text(
              "Bilgileri Güncelle",
              style: GoogleFonts.roboto(
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
          /** buton */
          SizedBox(height: 20,),
           Divider(
            color: Colors.grey, // Çizginin rengi
            thickness: 0.2, // Çizginin kalınlığı
            indent: 8, // Çizginin sol taraftan boşluğu
            endIndent: 8, // Çizginin sağ taraftan boşluğu
          ),
          SizedBox(
            height: 20,
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Genel Ayarlar",
              style: GoogleFonts.roboto(
                fontSize: 20,
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
          /** isaret */
          Row(
            //mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.black,
              ),
              Text(
                'İşaretlediğim yazılar gösterilsin',
                style: GoogleFonts.workSans(
                  fontWeight: FontWeight.normal,
                ),
              ),
              Spacer(), // Boşluk ekleyerek Switch widget'ını sağa taşı
              Switch(
                value: _notificationsEnabled,
                onChanged: (bool value) {
                  _updateIsaret(value); // İşaret durumu güncelleniyor
                },
              ),
            ],
          ),
          /** ./isaret */
          SizedBox(height: 20,),
           Divider(
            color: Colors.grey, // Çizginin rengi
            thickness: 0.2, // Çizginin kalınlığı
            indent: 8, // Çizginin sol taraftan boşluğu
            endIndent: 8, // Çizginin sağ taraftan boşluğu
          ),
          /** Sifre guncelleme bolumu */
          SizedBox(
            height: 20,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Şifre Güncelle",
                style: GoogleFonts.roboto(
                  fontSize: 20,
                  fontWeight: FontWeight.normal,
                ),
              ),
              SizedBox(height: 10),
              // Mevcut Şifre
              TextField(
                controller: _currentPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Mevcut Şifre',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              // Yeni Şifre
              TextField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Yeni Şifre',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              // Yeni Şifre Tekrar
              TextField(
                controller: _confirmNewPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Yeni Şifre Tekrar',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
                Center(
                child: OutlinedButton(
                  onPressed: _updatePassword,
                  style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.black), // Kenarlık rengi
                  backgroundColor: Colors.black, // Dolgu rengi
                  foregroundColor: Colors.white, // Yazı rengi
                  ),
                  child: Text(
                  "Şifreyi Güncelle",
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                  ),
                  ),
                ),
                ),
            ],
          ),
          /** ./Sifre guncelleme bolumu */
        ],
      ),
    );
  }
}
