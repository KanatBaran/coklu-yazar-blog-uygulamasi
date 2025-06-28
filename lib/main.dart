import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

//Page import
import 'Pages/home.dart';
import 'Pages/login.dart'; //bunu kaldir
import 'Pages/singUp.dart'; //bunu kaldir
import 'Pages/profil.dart'; //bunu kaldır
import 'Pages/profilEdit.dart'; //bunu kaldir
import 'pages/postAdd.dart'; //bunu kaldir

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
        options: FirebaseOptions(
            apiKey: "YOURAPIKEY",
            authDomain: "calisma-1-kesfet.firebaseapp.com",
            projectId: "calisma-1-kesfet",
            storageBucket: "calisma-1-kesfet.firebasestorage.app",
            messagingSenderId: "56465108973",
            appId: "YOURAPIID"));
  } else {
    await Firebase.initializeApp();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bildemi - Bilgisayar Akademisi',
      theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.grey[900]!, // Ana renk için koyu gri
            brightness: Brightness.light, // Aydınlık tema için
          ).copyWith(
            primary:  Colors.grey[900]!, // Ana renk

            /*
            onPrimary: Colors.white, // Ana rengin üstündeki yazılar
            secondary: Colors.grey[700], // İkincil renk
            onSecondary: Colors.white, // İkincil rengin üstündeki yazılar
            background: Colors.grey[100], // Arka plan rengi
            surface: Colors.grey[50], // Yüzey rengi (kartlar, dialoglar)
            onSurface: Colors.grey[800], // Yüzeydeki yazı rengi
            */

          ),
          scaffoldBackgroundColor: const Color.fromARGB(255, 255, 255, 255), 
          ),
        home: Home(),
      //home: postAdd(userId: 'X7pjcRABWEZTUQIYjj1baghAP043'),
      //home: Profil(userId: 'X7pjcRABWEZTUQIYjj1baghAP043',),
    );
  }
}
