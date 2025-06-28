import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zefyrka/zefyrka.dart';

//pages
import '../Components/cardPost.dart';
import '../Pages/Post.dart';
import '../function.dart';
import 'home.dart';

class Search extends StatelessWidget {
  const Search({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ContentSearch(),
    );
  }
}

class ContentSearch extends StatefulWidget {
  const ContentSearch({super.key});

  @override
  State<ContentSearch> createState() => _ContentSearchState();
}

class _ContentSearchState extends State<ContentSearch> {
  /** DEGISKENLER (START) */
  TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _articles = [];
  Map<String, String> namesCategory = {}; //Kategori adlarini saklamak icin
  /** DEGISKENLER (END) */

  /** FONKSIYONLAR (START) */
  //yazilari tekrardan getiren fonksiyon
  Future<void> fetchArticlesAndUpdateState() async {
    //print("fetchArticlesAndUpdateState çağrıldı.");
    setState(() {
      //isLoading = true; // Yükleme durumunu güncelledik
    });

    try {
      // Veritabanından yazıları çek
      List<Map<String, dynamic>> updatedArticles = await fetchArticles();

      // Yazılar listesini ve alt listeleri güncelle
      setState(() {
        _articles = updatedArticles;

        //isLoading = false; // Yükleme tamamlandı
      });
    } catch (e) {
      print("Error: $e");
      setState(() {
        //isLoading = false;
      });
    }
  }

  //initState fonksiyon
  @override
  void initState() {
    super.initState();

    loadCategories();

    fetchArticles().then((articles) {
      setState(() {
        _articles = articles;
      });
    });
  }

  //Kategorileri getiren fonksiyon
  Future<void> loadCategories() async {
    Map<String, String> fetchedCategories = await getnamesCategory();
    setState(() {
      namesCategory = fetchedCategories;
    });
  }

  Future<List<Map<String, dynamic>>> fetchArticles({
    String? searchKeyword, // Arama kelimesi
  }) async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    User? currentUser = _auth.currentUser;

    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      bool isLiked = false;

      // Firestore'dan tüm yazıları çekiyoruz
      Query query = firestore.collection('Yazi');
      QuerySnapshot yazilarSnapshot = await query.get();

      // Yazıların yazarlarını alıyoruz
      Set<String> yazarIds =
          yazilarSnapshot.docs.map((doc) => doc['yazar'] as String).toSet();

      QuerySnapshot kullaniciSnapshot = await firestore
          .collection('Kullanici')
          .where(FieldPath.documentId, whereIn: yazarIds.toList())
          .get();

      Map<String, Map<String, dynamic>> kullaniciMap = {
        for (var doc in kullaniciSnapshot.docs)
          doc.id: doc.data() as Map<String, dynamic>
      };

      // Beğeni bilgilerini alıyoruz
      QuerySnapshot snapshot = await firestore.collection('Begeni').get();
      List<String> begenilenYazilar =
          snapshot.docs.map((doc) => doc['yazi'].toString()).toList();

      QuerySnapshot snapshotCurrent = await firestore
          .collection('Begeni')
          .where('kisi', isEqualTo: currentUser?.uid ?? 'BBB')
          .get();

      List<String> currentBegendigiYazilar =
          snapshotCurrent.docs.map((doc) => doc['yazi'].toString()).toList();

      // Yazıları oluşturuyoruz
      List<Map<String, dynamic>> articles = yazilarSnapshot.docs.map((doc) {
        String yaziId = doc.id;
        String yazarId = doc['yazar'];
        Map<String, dynamic>? yazarBilgisi = kullaniciMap[yazarId];
        int begeniSayisi =
            begenilenYazilar.where((yazi) => yazi == yaziId).length;
        isLiked = currentBegendigiYazilar.contains(yaziId);

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
          "begeniSayisi": begeniSayisi,
          "isLiked": isLiked,
        };
      }).toList();

      // Eğer bir arama kelimesi varsa filtreleme yapıyoruz
      if (searchKeyword != null && searchKeyword.isNotEmpty) {
        String lowerCaseSearch = searchKeyword.toLowerCase();
        articles = articles.where((article) {
          String baslik = (article['baslik'] ?? '').toLowerCase();
          return baslik.contains(lowerCaseSearch);
        }).toList();
      }

      return articles;
    } catch (e) {
      print("Hata: $e");
      return [];
    }
  }

  // Güncellenmiş fetchArticles fonksiyonu
  /* calisan
  Future<List<Map<String, dynamic>>> fetchArticles({
    String? searchKeyword, // Arama kelimesi
  }) async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    User? currentUser = _auth.currentUser;

    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      bool isLiked = false;

      Query query = firestore.collection('Yazi');

      if (searchKeyword != null && searchKeyword.isNotEmpty) {
        query = query
            .where('baslik', isGreaterThanOrEqualTo: searchKeyword)
            .where('baslik', isLessThanOrEqualTo: '$searchKeyword\uf8ff');
      }

      QuerySnapshot yazilarSnapshot = await query.get();

      Set<String> yazarIds =
          yazilarSnapshot.docs.map((doc) => doc['yazar'] as String).toSet();

      QuerySnapshot kullaniciSnapshot = await firestore
          .collection('Kullanici')
          .where(FieldPath.documentId, whereIn: yazarIds.toList())
          .get();

      Map<String, Map<String, dynamic>> kullaniciMap = {
        for (var doc in kullaniciSnapshot.docs)
          doc.id: doc.data() as Map<String, dynamic>
      };

      QuerySnapshot snapshot = await firestore.collection('Begeni').get();
      List<String> begenilenYazilar =
          snapshot.docs.map((doc) => doc['yazi'].toString()).toList();

      QuerySnapshot snapshotCurrent = await firestore
          .collection('Begeni')
          .where('kisi', isEqualTo: currentUser?.uid ?? 'BBB')
          .get();

      List<String> currentBegendigiYazilar =
          snapshotCurrent.docs.map((doc) => doc['yazi'].toString()).toList();

      List<Map<String, dynamic>> articles = yazilarSnapshot.docs.map((doc) {
        String yaziId = doc.id;
        String yazarId = doc['yazar'];
        Map<String, dynamic>? yazarBilgisi = kullaniciMap[yazarId];
        int begeniSayisi =
            begenilenYazilar.where((yazi) => yazi == yaziId).length;
        isLiked = currentBegendigiYazilar.contains(yaziId);

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
          "begeniSayisi": begeniSayisi,
          "isLiked": isLiked,
        };
      }).toList();

      return articles;
    } catch (e) {
      print("Hata: $e");
      return [];
    }
  }*/

  Future<void> _onFavoriteChanged() async {
    // Favori değişiminde yapılacak işlemler
    print("Favori değişti");
  }

// Gelen Listeye göre yazıları gösteren yapı/fonksiyon
  Widget buildListViewSearch({
    required List<Map<String, dynamic>> list,
    required BuildContext context,
    required Future<void> Function() onFavoriteChanged,
    Map<String, String>? categoryNames,
  }) {
    if (list.isEmpty) {
      return Center(
        child: Text(
          'Henüz içerik yok.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

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

                //begeni islmeleri icin
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
          ],
        );
      },
    );
  }

  /** FONKSIYONLAR (END) */

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.black.withOpacity(0.5),
                  width: 1.0,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Aramaya başlayın...",
                      hintStyle: TextStyle(
                          color: Colors.grey,
                          fontFamily: 'Arial',
                          fontSize: 16),
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) async {
                      List<Map<String, dynamic>> results = await fetchArticles(
                        searchKeyword: value,
                      );
                      setState(() {
                        _articles = results;
                      });
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () {
                    // Burada istediğiniz sayfaya yönlendirme işlemi yapılır.
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              Home()), // TargetPage yerine kendi sayfanızı yazın
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: buildListViewSearch(
            list: _articles,
            context: context,
            onFavoriteChanged: fetchArticlesAndUpdateState,
            categoryNames: namesCategory,
          ),
        ),
      ],
    );
  }
}
