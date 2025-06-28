import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'Components/cardPost.dart';
import 'Pages/Post.dart';

import 'dart:async';

/* Gelen Listeye gore yazilari gosteren yapi/fonksiyon */
Widget buildListView({
  required List<Map<String, dynamic>> list,
  required BuildContext context,
  required Future<void> Function() onFavoriteChanged,
  Map<String, String>? categoryNames,
}) {
  // Eğer liste boşsa
  if (list.isEmpty) {
    return FutureBuilder(
      future: Future.delayed(Duration(seconds: 2)),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/loadingBook-s1-nb.gif',
                    width: 250, height: 250),
                SizedBox(height: 16),
                Text(
                  'Yazılar Yükleniyor...',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        } else {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  'Bu bölüm için uygun yazı bulunamadı.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  // Eğer liste doluysa ListView göster
  return ListView.builder(
    itemCount: list.length,
    itemBuilder: (context, index) {
      var article = list[index];

      String yazid = article["yazid"] ?? "Bilinmiyor";
      String baslik = article["baslik"] ?? "Bilinmiyor";
      String icerik = article["icerik"] ?? "Bilinmiyor";
      DateTime tarih =
          (article["tarih"] != null && article["tarih"] is Timestamp)
              ? (article["tarih"] as Timestamp).toDate()
              : DateTime.now();
      String yazar = article["yazar"] ?? "Bilinmiyor";
      String kategoriAdi =
          categoryNames?[article["kategori"].toString()] ?? "Genel";
      String resim = article["resim"] ?? "";
      String yazarResim = article["yazarResim"] ?? "";

      int begeniSayisi = article["begeniSayisi"] is int
          ? article["begeniSayisi"]
          : int.tryParse(article["begeniSayisi"] ?? '0') ?? 0;
      bool isLiked = article["isLiked"] ?? false;

      bool reklam;
      int randomAdCount = Random().nextInt(2) + 1;
      return Column(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => Post(
                    yazid: yazid,
                    baslik: baslik,
                    icerik: icerik,
                    tarih: tarih,
                    yazar: yazar,
                    kategoriAdi: kategoriAdi,
                    resim: resim,
                    yazarProfilResim: yazarResim,
                  ),
                ),
              );
            },
            child: cardPost(
              yazarId: article["yazarId"],
              yaziId: yazid,
              yazar: yazar,
              yazarProfilResim: yazarResim,
              baslik: baslik,
              icerik: icerik,
              resim: resim,
              tarih: tarih,
              kategoriAdi: kategoriAdi,

              // beğeni işlemleri için
              begeniSayisi: begeniSayisi,
              isLiked: isLiked,

              // onFavoriteChanged Callback'i cardPost'a geçiliyor
              onFavoriteChanged: onFavoriteChanged,
            ),
          ),
          Divider(
            color: Colors.grey.withOpacity(0.3),
            thickness: 1,
            indent: 16,
            endIndent: 16,
          ),
          /** Reklam */
          if (Random().nextDouble() < 0.25)
            
           
            Dismissible(
              key: UniqueKey(),
              direction: DismissDirection.horizontal, // Yatay sürükleme
              onDismissed: (direction) {
                // Reklam kaydırıldığında yapılacak işlem
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Reklam kaldırıldı')),
                );
                 print(randomAdCount);
              },
              background: Container(
                color: Colors.red, // Kırmızı arka plan
                alignment: Alignment.centerRight,
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Icon(Icons.delete, color: Colors.white),
              ),
              secondaryBackground: Container(
                color: Colors.red, // Kırmızı arka plan
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Icon(Icons.delete, color: Colors.white),
              ),
              child: Container(
                color: Colors.white, // Arka plan rengi
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                     Text(
                        'Reklam',
                        style: GoogleFonts.workSans(
                          fontWeight: FontWeight.normal,
                          fontSize: 10,
                        ),
                      ),
                      
                    Image.asset(
                    'assets/images/reklam$randomAdCount.png',
                    width: 500,
                    height: 50, // Height increased to make the image larger
                    ),
                  ],
                ),
              ),
            ),
          /** ./Reklam */
        ],
      );
    },
  );
}

/* ./Gelen Listeye gore yazilari gosteren yapi/fonksiyon */

/* Veritabanındaki yazilari getirip listeye atayan fonksiyon */
//eger userId var ise sadece userId ile eslenen yazilari getiriyor
Future<List<Map<String, dynamic>>> fetchArticles({
  String? userId, // Kullanıcı ID'si (opsiyonel)
}) async {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? currentUser = _auth.currentUser;

  try {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    bool isLiked = false;

    // Firestore sorgusunu başlat
    Query query = firestore.collection('Yazi');

    // Eğer userId sağlanmışsa filtre uygula
    if (userId != null) {
      query = query.where('yazar', isEqualTo: userId);
    }

    // Sorguyu çalıştır ve yazıları al
    QuerySnapshot yazilarSnapshot = await query.get();

    // Kullanıcı bilgilerini çekmek için gerekli yazar ID'lerini topla
    Set<String> yazarIds =
        yazilarSnapshot.docs.map((doc) => doc['yazar'] as String).toSet();

    QuerySnapshot kullaniciSnapshot = await firestore
        .collection('Kullanici')
        .where(FieldPath.documentId, whereIn: yazarIds.toList())
        .get();

    // Kullanıcı bilgilerini bir haritada sakla
    Map<String, Map<String, dynamic>> kullaniciMap = {
      for (var doc in kullaniciSnapshot.docs)
        doc.id: doc.data() as Map<String, dynamic>
    };

    /* Begeni islemleri */
    // "Begeni" koleksiyonunu getir
    QuerySnapshot snapshot = await firestore.collection('Begeni').get();
    int begeniSayisi = 0;
    //begeni tablosundaki yazilari listeye ekler
    List<String> begenilenYazilar =
        snapshot.docs.map((doc) => doc['yazi'].toString()).toList();

    //print(begenilenYazilar);

    QuerySnapshot snapshotCurrent = await firestore
        .collection('Begeni')
        .where('kisi', isEqualTo: currentUser?.uid ?? 'BBB')
        .get();

    // Kullanıcının beğendiği yazıları bir listeye ekle
    List<String> currentBegendigiYazilar =
        snapshotCurrent.docs.map((doc) => doc['yazi'].toString()).toList();
    //print(currentBegendigiYazilar);
    /* ./Begeni islemleri */

    // Yazıları bir listeye dönüştür
    List<Map<String, dynamic>> articles = yazilarSnapshot.docs.map((doc) {
      String yaziId = doc.id;
      String yazarId = doc['yazar'];
      Map<String, dynamic>? yazarBilgisi = kullaniciMap[yazarId];

      begeniSayisi = 0;
      for (int i = 0; i < begenilenYazilar.length; i++) {
        if (yaziId == begenilenYazilar[i]) {
          begeniSayisi = begeniSayisi + 1;
        }
      }

      //print("yazi:$yaziId sayisi:$begeniSayisi");
      //print(currentBegendigiYazilar);
      if (currentBegendigiYazilar.contains(yaziId)) {
        isLiked = true;
      } else {
        isLiked = false;
      }

      //print("yazi:$yaziId isLiked:$isLiked");

      return {
        "yazarId": yazarId,
        "yazid": yaziId,
        "baslik": doc["baslik"],
        "icerik": doc["icerik"],
        "kategori": doc["kategori"],
        "tarih": doc["tarih"],
        "resim": doc["resim"],
        "yazar":
            yazarBilgisi?['isim'] != null && yazarBilgisi?['soyisim'] != null
                ? "${yazarBilgisi!['isim']} ${yazarBilgisi['soyisim']}"
                : "Bilinmiyor",
        "yazarResim": yazarBilgisi?['resim'] ?? "",
        "begeniSayisi": begeniSayisi, // Beğeni sayısı
        "isLiked": isLiked,
      };
    }).toList();

    return articles;
  } catch (e) {
    print("Hata: $e");
    return [];
  }
}

/* ./Veritabanındaki yazilari getirip listeye atayan fonksiyon */



