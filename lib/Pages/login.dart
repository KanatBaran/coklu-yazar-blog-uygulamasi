import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

//page import
import 'home.dart';
import 'singUp.dart';

/* GIRIS SAYFASI (START) */
class Login extends StatelessWidget {
  const Login({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(""),
        backgroundColor: Colors.white,
      ),
      body: contentLogin(),
    );
  }
}

class contentLogin extends StatefulWidget {
  const contentLogin({super.key});

  @override
  State<contentLogin> createState() => _contentLoginState();
}

class _contentLoginState extends State<contentLogin> {
  //giris icin degiskenler
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  /* Fonksiyonlar */
  //Giris Fonksiyonu
  void loginAccount() async {
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Home()),
      );
    } catch (e) {
      print("Giriş Hatası: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text("Giriş yapılamadı. Lütfen bilgilerinizi kontrol edin.")),
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

  /* ./Fonksiyonlar */

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
              
              'E-Posta ile Giriş Yap!',
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
              Text(
                "E-Posta",
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
                    hintText: "E-Postanızı Girin",
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
            height: 30,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: loginAccount,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.green,
                ),
                child: Text("Giriş Yap"),
              ),
            ],
          ),
          SizedBox(
            height: 30,
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
          Divider(
            color: Colors.grey,
            thickness: 1,
            height: 40,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Hesabın yok mu? ",
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
                      MaterialPageRoute(builder: (context) => SingUp()),
                    );
                  },
                  child: Text(
                    "Kayıt Ol",
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
/* GIRIS SAYFASI (END) */
