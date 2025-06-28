import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

//import pages
import 'login.dart';

/* KAYIT OL SAYFASI (START) */
class SingUp extends StatelessWidget {
  const SingUp({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(""),
        backgroundColor: Colors.white,
      ),
      body: contentSingUp(),
    );
  }
}

class contentSingUp extends StatefulWidget {
  const contentSingUp({super.key});

  @override
  State<contentSingUp> createState() => _contentSingUpState();
}

class _contentSingUpState extends State<contentSingUp> {

/** DEGISKENLER (START) */
 // TextEditingController'lar
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController passwordCheckController = TextEditingController();
/** DEGISKENLER (END) */


/** FONKSIYONLAR (START) */

// Firebase Auth ve Firestore ile kayıt işlemi
  void singUpAccount() async {
    String firstName = firstNameController.text.trim();
    String lastName = lastNameController.text.trim();
    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    String passwordCheck = passwordCheckController.text.trim();

    if (firstName.isEmpty || lastName.isEmpty || email.isEmpty || password.isEmpty) {
      // Alanlar boşsa uyarı göster
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lütfen tüm alanları doldurun.")),
      );
      return;
    }

    if(password != passwordCheck)
    {
      //sifreler uyusmuyorsa uyari verir
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Girilen şifreler uyuşmuyor.")),
      );

      return;
    }

    

    try {
      // Firebase Authentication ile kullanıcı oluşturma
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Kullanıcı ID'sini al
      String userId = userCredential.user!.uid;

      // Firestore'da Kullanici koleksiyonuna kullanıcı bilgilerini kaydet
      await FirebaseFirestore.instance.collection('Kullanici').doc(userId).set({
        'email': email,
        'isim': firstName,
        'soyisim': lastName,
        'meslek': '', // İlk kayıtta boş olarak bırakılıyor
        'telefon': '', // İlk kayıtta boş olarak bırakılıyor
        'hakkinda': '', // İlk kayıtta boş olarak bırakılıyor
        'resim': '', // İlk kayıtta boş olarak bırakılıyor
        'rol': '1', // Varsayılan rol
        'isaret': '0',
        'tarih': FieldValue.serverTimestamp(), // Oluşturulma tarihi
      });

      // Başarılı kayıt sonrası giriş sayfasına yönlendir
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Login()),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Kayıt başarılı! Giriş yapabilirsiniz.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Kayıt sırasında bir hata oluştu: $e")),
      );
    }
  }


  // Hizmet Şartları Popup
  void showTermsPopup() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Hizmet Şartları"),
          content:
              Text("Burada Hizmet Şartlarının detaylarını okuyabilirsiniz."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Kapat"),
            ),
          ],
        );
      },
    );
  }

  // Gizlilik Politikası Popup
  void showPrivacyPopup() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Gizlilik Politikası"),
          content: Text(
              "Burada Gizlilik Politikasının detaylarını okuyabilirsiniz."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Kapat"),
            ),
          ],
        );
      },
    );
  }

/** FONKSIYONLAR (END) */

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(
              'BilDemi - Bilgisayar Akademi',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ]),
          SizedBox(
            height: 20,
          ),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(
              'E-Posta ile Kayıt Ol!',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.normal,
              ),
            ),
          ]),
          SizedBox(
            height: 30,
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  "Ad",
                  style: TextStyle(color: Colors.black),
                ),
              ),
              SizedBox(width: 10), // Araya boşluk
              Expanded(
                child: Text(
                  "Soyad",
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: firstNameController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "Adınızı Girin",
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
              SizedBox(width: 10), // Araya boşluk
              Expanded(
                child: TextField(
                  controller: lastNameController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "Soyadınızı Girin",
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            height: 10,
          ),
          Row(
            children: [
              Text(
                "E-Posta Adresi",
                style: TextStyle(color: Colors.black),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "E-Posta adresinizi Girin",
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            height: 10,
          ),
          Row(
            children: [
              Text(
                "Şifre",
                style: TextStyle(color: Colors.black),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "Şifrenizi Girin",
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            height: 10,
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: passwordCheckController,
                  obscureText: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "Şifrenizi Tekrar Girin",
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            height: 15,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: singUpAccount,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.green,
                ),
                child: Text("Kayıt Ol"),
              ),
            ],
          ),
          SizedBox(
            height: 20,
          ),
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: 'Giriş yaptığınız durumda ',
                    style: TextStyle(color: Colors.grey),
                    children: [
                      TextSpan(
                        text: 'Hizmet Şartları',
                        style: TextStyle(
                          color: Colors.black,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = showTermsPopup,
                      ),
                      TextSpan(
                        text: ' ve ',
                        style: TextStyle(color: Colors.grey),
                      ),
                      TextSpan(
                        text: 'Gizlilik Politikasını',
                        style: TextStyle(
                          color: Colors.black,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = showPrivacyPopup,
                      ),
                      TextSpan(
                        text: ' kabul etmiş olursunuz.',
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          SizedBox(
            height: 10,
          ),
          Divider(
            color: Colors.grey,
            thickness: 1,
          ),
          SizedBox(
            height: 10,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Hesabın var mı? ",
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              MouseRegion(
                cursor: SystemMouseCursors.click, // İmleç tipi değişimi
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => Login()),
                    );
                  },
                  child: Text(
                    "Giriş Yap",
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
/* KAYIT OL SAYFASI (END) */
