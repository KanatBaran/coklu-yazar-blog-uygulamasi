import 'dart:convert';

import 'package:calisma_1_kesfet/function.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zefyrka/zefyrka.dart';

//pages
import 'home.dart';
import '../Pages/profil.dart';
import '../Pages/postEdit.dart';

class Post extends StatelessWidget {
  final String yazid;
  final String baslik;
  final String icerik;
  final DateTime tarih;
  final String yazar;
  final String kategoriAdi;

  final String resim;
  final String yazarProfilResim;

  const Post({
    Key? key,
    required this.yazid,
    required this.baslik,
    required this.icerik,
    required this.tarih,
    required this.yazar,
    required this.kategoriAdi,
    required this.resim,
    required this.yazarProfilResim,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: contentPost(
        yazid: yazid,
        baslik: baslik,
        icerik: icerik,
        tarih: tarih,
        yazar: yazar,
        kategoriAdi: kategoriAdi,
        resim: resim,
        yazarProfilResim: yazarProfilResim,
      ),
    );
  }
}

class contentPost extends StatefulWidget {
  final String yazid;
  final String baslik;
  final String icerik;
  final DateTime tarih;
  final String yazar;
  final String kategoriAdi;
  final String resim;
  final String yazarProfilResim;

  const contentPost({
    Key? key,
    required this.yazid,
    required this.baslik,
    required this.icerik,
    required this.tarih,
    required this.yazar,
    required this.kategoriAdi,
    required this.resim,
    required this.yazarProfilResim,
  }) : super(key: key);

  @override
  State<contentPost> createState() => _contentPostState();
}

class _contentPostState extends State<contentPost> {
  /** DEGISKENLER (START) */
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool isLiked = false;
  int totalLikes = 0;
  late String deltaJson = "";
  late NotusDocument _document = NotusDocument();
  List<TextSpan> textSpans = [];

  String? yazarId;
  String? idYazi;
  String? GirisUserId;
  String? yazarRole;
  late User? currentUser;

  //bookmark
  bool isBookmarked = false;
  /** DEGISKENLER (END) */

  @override
  void initState() {
    super.initState();

    _checkIfLiked();
    _fetchTotalLikes();
    postJson();

    fetchYazarDetails();

    idYazi = widget.yazid;

    currentUser = _auth.currentUser;
    GirisUserId = currentUser?.uid;

    if (GirisUserId != null) {
      getUserRole(GirisUserId!);
    }

    checkIfBookmarked();
  }

  /* FONKSIYONLAR (START) */
  //bookmark olup olmadigini kontrol eden fonksiyon
  void checkIfBookmarked() async {
    currentUser = _auth.currentUser;
    if (currentUser != null) {
      String? userId = GirisUserId;
      String postId = widget.yazid;

      QuerySnapshot snapshot = await _firestore
          .collection('Isaret')
          .where('kisi', isEqualTo: userId)
          .where('yazi', isEqualTo: postId)
          .get();

      setState(() {
        isBookmarked = snapshot.docs.isNotEmpty;
      });
    }
  }

//isaretleme durumunu guncelleyen fonksiyon
  Future<void> toggleBookmark() async {
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Bu işlemi yapmak için giriş yapmalısınız.")),
      );
      return;
    }

    String userId = currentUser!.uid;
    String postId = widget.yazid;

    QuerySnapshot snapshot = await _firestore
        .collection('Isaret')
        .where('kisi', isEqualTo: userId)
        .where('yazi', isEqualTo: postId)
        .get();

    if (snapshot.docs.isNotEmpty) {
      // İşaret kaldır
      for (var doc in snapshot.docs) {
        await _firestore.collection('Isaret').doc(doc.id).delete();
      }
      setState(() {
        isBookmarked = false;
      });
      /*
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("İşaret kaldırıldı.")),
      );*/
    } else {
      // İşaret ekle
      await _firestore.collection('Isaret').add({
        'kisi': userId,
        'yazi': postId,
        'tarih': DateTime.now(),
      });
      setState(() {
        isBookmarked = true;
      });
      /*
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("İşaretlendi.")),
      );*/
    }
  }

  //yazi silme fonksiyonu
  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Yazıyı Sil"),
          content: Text("Bu yazıyı silmek istediğinize emin misiniz?"),
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
                if (idYazi != null) {
                  deletePost(idYazi!);
                }
              },
            ),
          ],
        );
      },
    );
  }

  //yazi silme fonksiyonu
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

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => Home()), // Yeni sayfaya yönlendirme
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

  //yazarid al
  Future<void> fetchYazarDetails() async {
    try {
      DocumentSnapshot<Map<String, dynamic>> yazidoc =
          await _firestore.collection('Yazi').doc(widget.yazid).get();

      if (yazidoc.exists) {
        setState(() {
          yazarId = yazidoc.data()?['yazar'] ?? '';
          yazarRole = yazidoc.data()?['rol'] ?? '';
        });
      }
    } catch (e) {
      print(" (Post.dart) Yazar id alinamadi: $e");
    }
  }

  //Giris yapmis kullanicinin rolunu alan fonksiyon
  Future<void> getUserRole(String? userId) async {
    if (userId == null) {
      // Kullanıcı giriş yapmamış, role boş kalsın
      yazarRole = null;
      return;
    }

    try {
      // Firestore'da 'Kullanici' koleksiyonunu referans al
      CollectionReference users =
          FirebaseFirestore.instance.collection('Kullanici');

      // Kullanıcı belgesini getir
      DocumentSnapshot userSnapshot = await users.doc(userId).get();

      // Belge mevcutsa, rol alanını global değişkene ata
      if (userSnapshot.exists) {
        setState(() {
          yazarRole = userSnapshot['rol'] as String?;
        });
      } else {
        print("(Post.dart) Kullanıcı belgesi bulunamadı.");
      }
    } catch (e) {
      print("(Post.dart) Hata: $e");
    }
  }

  //kullanicini begeni kontrol
  void _checkIfLiked() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      final likeDoc = await _firestore
          .collection('Begeni')
          .where('kisi', isEqualTo: currentUser.uid)
          .where('yazi', isEqualTo: widget.yazid)
          .get();

      if (likeDoc.docs.isNotEmpty) {
        setState(() {
          isLiked = true;
        });
      }
    }
  }

  //Toplam begeni sayisi
  void _fetchTotalLikes() async {
    final likesSnapshot = await _firestore
        .collection('Begeni')
        .where('yazi', isEqualTo: widget.yazid)
        .get();

    setState(() {
      totalLikes = likesSnapshot.docs.length;
    });
  }

  //begeni islemi
  void _toggleLike() async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Beğendiklerinize eklemek için Giriş yapmalısınız.')),
      );
      return;
    }

    String kisiId = currentUser.uid;
    String idYazi = widget.yazid;

    QuerySnapshot snapshot = await _firestore
        .collection('Begeni')
        .where('kisi', isEqualTo: kisiId)
        .where('yazi', isEqualTo: idYazi)
        .get();

    final likeRef = _firestore
        .collection('Begeni')
        .doc('${currentUser.uid}_${widget.yazid}');

    if (snapshot.docs.isNotEmpty) {
      // Eğer beğenilmişse, belgeyi sil
      for (var doc in snapshot.docs) {
        await _firestore.collection('Begeni').doc(doc.id).delete();
      }
      setState(() {
        isLiked = false;
        totalLikes--;
      });
    } else {
      // Eğer beğenilmemişse, yeni bir belge ekle
      await _firestore.collection('Begeni').add({
        'kisi': kisiId,
        'yazi': idYazi,
        'tarih': DateTime.now(),
      });
      setState(() {
        isLiked = true;
        totalLikes++;
      });
    }
  }

  //Stili icerik cek
  Future<void> postJson() async {
    try {
      DocumentSnapshot<Map<String, dynamic>> yazidoc =
          await _firestore.collection('Yazi').doc(widget.yazid).get();

      setState(() {
        deltaJson = yazidoc.data()?['icerikJSON'] ?? '';
      });

      if (deltaJson.isNotEmpty) {
        final decodedJson = jsonDecode(deltaJson); // JSON'u decode et
        final List<dynamic> jsonContent = decodedJson;
        _document = NotusDocument.fromJson(decodedJson);

        // RichText'te göstermek için hazırla
        setState(() {});
      }
    } catch (e) {
      print("(Post.dart)  JSON Decode Hatası: $e");
    }
  }
  /* FONKSIYONLAR (END) */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /** appbar */
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back,
                      color: Colors.black), // Sol tarafta geri ok ikonu
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              Home()), // Yeni sayfaya yönlendirme
                    );
                  },
                ),
                if (yazarId == GirisUserId ||
                    (yazarRole != null && yazarRole == "2"))
                  PopupMenuButton<int>(
                    icon: Icon(Icons.more_vert,
                        color: Colors.black), // Sağ tarafta üç nokta
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 1,
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline),
                            const SizedBox(width: 8),
                            Text("Sil"),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 2,
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined),
                            const SizedBox(width: 8),
                            Text("Düzenle"),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 1) {
                        _showDeleteConfirmation(); // Silme fonksiyonunu çağır
                      } else if (value == 2) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PostEdit(
                                postId: idYazi ??
                                    ''), // Düzenleme sayfasına yönlendir
                          ),
                        );
                      }
                    },
                  ),
              ],
            ),
            /** ./appbar */
            Text(
              widget.baslik,
              style:
                  GoogleFonts.roboto(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(
              height: 15,
            ),
            Row(
              children: [
                /* yazar Profil Resim */
                GestureDetector(
                  onTap: () {
                    // Tıklama olayında yapılacak işlemler
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Profil(userId: yazarId ?? ''),
                      ),
                    );
                  },
                  child: CircleAvatar(
                    backgroundImage: widget.yazarProfilResim != null &&
                            widget.yazarProfilResim!.isNotEmpty
                        ? NetworkImage(widget.yazarProfilResim!) // Profil resmi
                        : AssetImage('assets/images/demoUser.png')
                            as ImageProvider, // Varsayılan resim
                    radius: 20, // Küçük boyut
                  ),
                ),
                /* ./yazar Profil Resim */
                SizedBox(
                  width: 10,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /* yazar ad ve soyad */
                    Text(
                      widget.yazar,
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.normal,
                          color: Colors.black),
                    ),
                    /* yazar ad ve soyad */
                    /* tarih */
                    Row(
                      children: [
                        Text(
                          widget.kategoriAdi,
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.normal,
                              color: Colors.grey),
                        ),
                        Text(
                          " • ",
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.normal,
                              color: Colors.black),
                        ),
                        Text(
                          formatReadableDateManual(widget.tarih),
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.normal,
                              color: Colors.grey),
                        ),
                      ],
                    ),
                    /* ./tarih */
                  ],
                ),
              ],
            ),
            SizedBox(
              height: 15,
            ),
            /* Yazı Resmi */
            ClipRRect(
              borderRadius:
                  BorderRadius.circular(12), // Resim köşelerini yuvarla
              child: Image.network(
                widget.resim,
                width: double.infinity, // Ekran genişliğine göre ölçeklendirme
                height: 250, // Yükseklik
                fit: BoxFit.cover, // Resmi boyuta sığdır
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) {
                    return child;
                  } else {
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                (loadingProgress.expectedTotalBytes ?? 1)
                            : null,
                      ),
                    );
                  }
                },
              ),
            ),
            /* ./Yazı Resmi */
            SizedBox(
              height: 15,
            ),
            ZefyrEditor(
              controller: ZefyrController(_document),
              readOnly: true, // Düzenlemeyi devre dışı bırak
            ),
          ],
        ),
      ),
/* AltBar */
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround, // Kenarlara hizalar
          children: [
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    isLiked == true ? Icons.favorite : Icons.favorite_border,
                    color: isLiked == true ? Colors.red : Colors.grey,
                    size: 16,
                  ),
                  onPressed: _toggleLike,
                ),
                Text(totalLikes.toString()),
              ],
            ),
            IconButton(
              icon: Icon(
                isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                color: isBookmarked ? Colors.blue : Colors.grey,
                size: 20,
              ),
              onPressed: toggleBookmark,
            ),
            Icon(
              Icons.share_outlined,
              size: 20,
              color: Colors.grey,
            ), // Sağ tarafa paylaşım ikonu
          ],
        ),
      ),
/* ./AltBar */
    );
  }
}
