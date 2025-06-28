import 'dart:io';

import 'package:calisma_1_kesfet/Pages/profil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

//other
import 'package:calisma_1_kesfet/function.dart';

//pages
import '../Pages/home.dart';
import '../Pages/postEdit.dart';

class cardPost extends StatefulWidget {
  final String yazarId;
  final String yaziId;
  final String yazar;
  final String baslik;
  final String icerik;
  final DateTime tarih;
  final String kategoriAdi;
  final String? resim;
  final String? yazarProfilResim;

  //begeni islemleri icin
  int? begeniSayisi;
  bool isLiked;
  final VoidCallback onFavoriteChanged;

  cardPost({
    Key? key,
    required this.yazarId,
    required this.yaziId,
    required this.yazar,
    required this.baslik,
    required this.icerik,
    required this.tarih,
    required this.kategoriAdi,
    this.resim,
    this.yazarProfilResim,

    //begeni islemleri icin
    this.begeniSayisi,
    required this.isLiked,
    required this.onFavoriteChanged,
  }) : super(key: key);

  @override
  State<cardPost> createState() => _cardPostState();
}

class _cardPostState extends State<cardPost> {
  /** DEGISKLENLER (START) */
  //bookmark icin
  bool isBookmarked = false;

  // Firestore ve Auth bağlantısı
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? currentUser;
  String? roleUser;

  //Icerik kisaltir
  late String subtitleText;
  /** DEGISKLENLER (END) */

  /** FONKSIYONLAR (START) */
  //yer isareti duzenleyen fonksiyon
  Future<void> toggleBookmark() async {
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Bu işlemi yapmak için giriş yapmalısınız."),
        ),
      );
      return;
    }

    String? userId = currentUser?.uid;
    String postId = widget.yaziId;

    QuerySnapshot snapshot = await _firestore
        .collection('Isaret')
        .where('kisi', isEqualTo: userId)
        .where('yazi', isEqualTo: postId)
        .get();

    if (snapshot.docs.isNotEmpty) {
      // Eğer kayıt varsa, sil
      for (var doc in snapshot.docs) {
        await _firestore.collection('Isaret').doc(doc.id).delete();
      }
      setState(() {
        isBookmarked = false; // İşaret kaldırıldı
      });

        /*
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("İşaret kaldırıldı.")),
      );*/


    } else {
      // Eğer kayıt yoksa, ekle
      await _firestore.collection('Isaret').add({
        'kisi': userId,
        'yazi': postId,
        'tarih': DateTime.now(),
      });
      setState(() {
        isBookmarked = true; // İşaretlendi
      });

      /*
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("İşaretlendi.")),
      );
    */

    }
  }

  //post silme oncesi uyari fonksiyonu
  void showDeleteConfirmation(String yaziId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Yazıyı Sil"),
          content: RichText(
            text: TextSpan(
              text: "Bu yazıyı silmek istediğinizden emin misiniz?\n",
              style: TextStyle(color: Colors.black),
              children: <TextSpan>[
                TextSpan(
                  text: "Bu işlem geri alınamaz!",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text("Hayır"),
              onPressed: () {
                Navigator.of(context).pop(); // Dialog'u kapat
              },
            ),
            TextButton(
              child: Text("Evet"),
              onPressed: () {
                Navigator.of(context).pop(); // Dialog'u kapat
                deletePost(yaziId); // Yazıyı silme işlemi
              },
            ),
          ],
        );
      },
    );
  }

  //post silme fonksiyonu
  void deletePost(String yaziId) async {
    try {
      // Yazıya ait tüm beğenileri sil
      QuerySnapshot begeniSnapshot = await _firestore
          .collection('Begeni')
          .where('yazi', isEqualTo: yaziId)
          .get();

      for (var doc in begeniSnapshot.docs) {
        await _firestore.collection('Begeni').doc(doc.id).delete();
      }

      // Firestore'dan yazıyı sil
      await FirebaseFirestore.instance.collection('Yazi').doc(yaziId).delete();

      // Kullanıcıya silme işleminin başarılı olduğunu bildir
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Yazı başarıyla silindi."),
        ),
      );

      widget.onFavoriteChanged();
    } catch (e) {
      // Hata durumunda kullanıcıya hata mesajı göster
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Yazı silinirken bir hata oluştu: $e"),
        ),
      );
    }
  }

  //initState Fonksiyonu
  @override
  void initState() {
    super.initState();

    //giris yapmis kullanici
    currentUser = _auth.currentUser;

    /** kullanici rolu alma */
    if (currentUser != null) {
      // Kullanıcıya ait Firestore dökümanını getir
      _firestore
          .collection('Kullanici') // Kullanıcı koleksiyonunun adı
          .doc(currentUser!.uid) // Giriş yapan kullanıcının UID'si
          .get()
          .then((DocumentSnapshot documentSnapshot) {
        if (documentSnapshot.exists) {
          // 'rol' değerini al ve roleUser'a ata
          setState(() {
            roleUser = documentSnapshot
                .get('rol')
                .toString(); // Eğer 'rol' bir int ise String'e çevir
          });
        } else {
          //print("Kullanıcı dökümanı bulunamadı.");
        }
      }).catchError((error) {
        print("(cardPost.dart) Hata oluştu: $error");
      });
    } else {
      //print("Giriş yapmış bir kullanıcı yok.");
    }
    /** kullanici rolu alma */

    /** yazi silme fonksiyonu */
    void deletePost(String yaziId) async {
      try {
        // Firestore'dan yazıyı sil
        await FirebaseFirestore.instance
            .collection('Yazi')
            .doc(yaziId)
            .delete();

        // Kullanıcıya silme işleminin başarılı olduğunu bildir
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Yazı başarıyla silindi."),
          ),
        );
      } catch (e) {
        // Hata durumunda kullanıcıya hata mesajı göster
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Yazı silinirken bir hata oluştu: $e"),
          ),
        );
      }
    }
    /** ./yazi silme fonksiyonu */

    //icerik kisaltma
    currentUser = _auth.currentUser;
    subtitleText = widget.icerik.length > 100
        ? widget.icerik.substring(0, 100) + "..."
        : widget.icerik.replaceAll('\n', ' ');

    //isaret kontrolu
    checkIfBookmarked();
  }

  //isaret kontrol eden fonksiyon
  void checkIfBookmarked() async {
    if (currentUser != null) {
      String? userId = currentUser?.uid;
      String postId = widget.yaziId;

      QuerySnapshot snapshot = await _firestore
          .collection('Isaret')
          .where('kisi', isEqualTo: userId)
          .where('yazi', isEqualTo: postId)
          .get();

      if (snapshot.docs.isNotEmpty) {
        setState(() {
          isBookmarked = true; // İşaretli olarak ayarla
        });
      } else {
        setState(() {
          isBookmarked = false; // İşaretli değil olarak ayarla
        });
      }
    }

    //widget.onFavoriteChanged();
  }

  //Favori duzenleme fonksiyonu
  Future<void> editFavorite() async {
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Beğendiklerinize eklemek için Giriş yapmalısınız."),
        ),
      );
      exit(0);
    }

    if (widget.isLiked == true) {
      String? kisiId = currentUser?.uid;
      String? idYazi = widget.yaziId;

      /* Veritabanindan silme islemi */
      QuerySnapshot snapshot = await _firestore
          .collection('Begeni')
          .where('kisi', isEqualTo: kisiId)
          .where('yazi', isEqualTo: idYazi)
          .get();

      if (snapshot.docs.isNotEmpty) {
        for (var doc in snapshot.docs) {
          // Her belgeyi sil
          await _firestore.collection('Begeni').doc(doc.id).delete();
        }
        //print('Tüm eşleşen belgeler silindi.');
      } else {
        //print('Eşleşen belge bulunamadı.');
      }
      /* ./Veritabanindan silme islemi */

      setState(() {
        widget.isLiked = false;
        widget.begeniSayisi = (widget.begeniSayisi ?? 0) - 1;
      });
    } else if (widget.isLiked == false) {
      String? kisiId = currentUser?.uid;
      String? idYazi = widget.yaziId;

      /* ./Veritabanina ekleme islemi */
      await _firestore.collection('Begeni').add({
        'kisi': currentUser?.uid,
        'yazi': widget.yaziId,
        'tarih': DateTime.now(),
      });

      /* ./Veritabanina ekleme islemi */

      setState(() {
        widget.isLiked = true;
        widget.begeniSayisi = (widget.begeniSayisi ?? 0) + 1;
      });
    }

    //print("onFavoriteChanged çağrılıyor...");
    widget.onFavoriteChanged();
  }

  /** FONKSIYONLAR (END) */

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /* yazar Profil Resim */
                GestureDetector(
                  onTap: () {
                    // Yazarın profiline gitme işlemi burada yapılır
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Profil(userId: widget.yazarId),
                      ),
                    ).then((_) {
                      //print("geri donuldu");

                      setState(() {});
                    });
                  },
                  child: CircleAvatar(
                    backgroundImage: widget.yazarProfilResim != null &&
                            widget.yazarProfilResim!.isNotEmpty
                        ? NetworkImage(widget.yazarProfilResim!) // Profil resmi
                        : AssetImage('assets/images/demoUser.png')
                            as ImageProvider, // Varsayılan resim
                    radius: 10, // Küçük boyut
                  ),
                ),
                /* ./yazar Profil Resim */

                SizedBox(
                  width: 5,
                ),

                /* yazar ad ve soyad */
                GestureDetector(
                  onTap: () {
                    // Yazarın profiline gitme işlemi burada yapılır
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Profil(
                            userId: widget
                                .yazarId), // Yazarın profili sayfasına gidilir
                      ),
                    );
                  },
                  child: Text(
                    widget.yazar,
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.normal,
                        color: Colors.grey),
                  ),
                ),
                /* yazar ad ve soyad */
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Başlık
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        widget.baslik,
                        style: GoogleFonts.roboto(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitleText,
                        style:
                            GoogleFonts.roboto(fontWeight: FontWeight.normal),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Resim Bölümü

                if (widget.resim != null && widget.resim!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.network(
                      widget.resim!,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) {
                          return child;
                        } else {
                          return SizedBox(
                            width: 100,
                            height: 100,
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        (loadingProgress.expectedTotalBytes ??
                                            1)
                                    : null,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  )
                else
                  Container(
                    width: 100,
                    height: 100,
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.image,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      formatReadableDateManual(widget.tarih),
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.normal,
                          color: Colors.grey),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      Icons.label_outline,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.kategoriAdi,
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.normal,
                          color: Colors.grey),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        widget.isLiked == true
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color:
                            widget.isLiked == true ? Colors.red : Colors.grey,
                        size: 16,
                      ),
                      onPressed: editFavorite,
                    ),
                    const SizedBox(width: 0),
                    Text(
                      widget.begeniSayisi.toString(),
                      style:
                          GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                    ),
                    SizedBox(
                      width: 6,
                    ),
                    IconButton(
                      icon: Icon(
                        isBookmarked
                            ? Icons.bookmark
                            : Icons.bookmark_border, 
                        color: isBookmarked
                            ? Colors.blue
                            : Colors.grey, 
                        size: 16,
                      ),
                      onPressed: toggleBookmark,
                    ),
                    if (widget.yazarId == currentUser?.uid || roleUser == '2')
                      PopupMenuButton<int>(
                        icon: Icon(
                          Icons.more_vert,
                          color: Colors.grey,
                          size: 16,
                        ),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 1,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_outline,
                                  color: Colors.grey,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text("Sil"),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 2,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.edit_outlined,
                                  color: Colors.grey,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text("Düzenle"),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 1) {
                            showDeleteConfirmation(widget.yaziId);
                          } else if (value == 2) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    PostEdit(postId: widget.yaziId),
                              ),
                            );
                          }
                        },
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
