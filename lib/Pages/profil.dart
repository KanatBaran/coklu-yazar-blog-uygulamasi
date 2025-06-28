import 'package:calisma_1_kesfet/Pages/profilEdit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';

//Components
import '../Components/cardPost.dart';

//Pages
import 'Post.dart';
import 'home.dart';
import 'postAdd.dart';

//other
import '../function.dart';
import '../functionFire.dart';

class Profil extends StatelessWidget {
  final String userId;

  const Profil({super.key, required this.userId});

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
                  builder: (context) => Home()), // Yeni sayfaya yönlendirme
            );
          },
        ),
        title: Text(""),
        backgroundColor: Colors.white,
        actions: [
          if (FirebaseAuth.instance.currentUser != null &&
              userId == FirebaseAuth.instance.currentUser!.uid)
            IconButton(
              icon: Icon(
                Icons.logout,
                color: Colors.black,
              ), // Çıkış ikonu
              onPressed: () {
                FirebaseAuth.instance.signOut(); // Kullanıcıyı çıkış yaptır
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          Home()), // Çıkış sonrası ana sayfaya yönlendirme
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Başarıyla çıkış yaptınız.")),
                );
              },
            ),
        ],
      ),
      body: ContentProfil(userId: userId),
    );
  }
}

class ContentProfil extends StatefulWidget {
  final String userId;

  const ContentProfil({super.key, required this.userId});

  @override
  State<ContentProfil> createState() => _ContentProfilState();
}

class _ContentProfilState extends State<ContentProfil>
    with SingleTickerProviderStateMixin {
  /** DEGSIKENLER (START) */
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> articles = [];
  Map<String, String> namesCategory = {};
  List<Map<String, dynamic>> likedArticles = [];
  List<Map<String, dynamic>> bookmarkedArticles = [];

  String? loggedInUserId;
  Map<String, dynamic>? userData;
  bool isLoading = true;

  late TabController _tabController;

  String? bookmarkControl = "";
  /** DEGSIKENLER (END) */

  /** FONKSIYONLAR (START) */
  //initState fonksiyon
  @override
  void initState() {
    super.initState();

    String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

    fetchArticles(userId: widget.userId).then((fetchedArticles) {
      setState(() {
        articles = fetchedArticles;
      });
    });

    getLikedArticles();
    loadCategories();

    _checkLoggedInUser();
    _fetchUserData();

    getBookmarkedArticles();

    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _onTabChanged(_tabController.index);
      }
    });
  }

  //kullanicinin isaretledigi yazilari getiren fonksiyon
  Future<void> getBookmarkedArticles() async {
    try {
      // Kullanıcının işaretlediği yazıların ID'lerini al
      QuerySnapshot isaretSnapshot = await _firestore
          .collection('Isaret')
          .where('kisi', isEqualTo: widget.userId) // Kullanıcıya göre filtrele
          .get();

      // Eğer işaretli yazı yoksa, boş bir liste döndür
      if (isaretSnapshot.docs.isEmpty) {
        setState(() {
          bookmarkedArticles = [];
        });
        return;
      }

      // İşaretli yazıların ID'lerini topla
      List<String> bookmarkedArticleIds =
          isaretSnapshot.docs.map((doc) => doc['yazi'] as String).toList();

      // İşaretli yazıları Firestore'dan getir
      QuerySnapshot yazilarSnapshot = await _firestore
          .collection('Yazi')
          .where(FieldPath.documentId, whereIn: bookmarkedArticleIds)
          .get();

      // Beğenilen yazı ID'lerini getir
      QuerySnapshot begeniSnapshot = await _firestore
          .collection('Begeni')
          .where('kisi', isEqualTo: widget.userId)
          .get();

      List<String> likedArticleIds =
          begeniSnapshot.docs.map((doc) => doc['yazi'] as String).toList();

      // Beğeni sayısını hesapla
      QuerySnapshot begeniSnapshot2 =
          await _firestore.collection('Begeni').get();

      Map<String, int> begeniCountMap = {};
      for (var doc in begeniSnapshot2.docs) {
        String yaziId = doc['yazi'];
        if (begeniCountMap.containsKey(yaziId)) {
          begeniCountMap[yaziId] = begeniCountMap[yaziId]! + 1;
        } else {
          begeniCountMap[yaziId] = 1;
        }
      }

      /** Yazar bilgi islemi */
      // Yazar bilgilerini topluca çekmek için yazarlardan bir set oluştur
      Set<String> yazarIds =
          yazilarSnapshot.docs.map((doc) => doc['yazar'] as String).toSet();

      QuerySnapshot kullaniciSnapshot = await _firestore
          .collection('Kullanici')
          .where(FieldPath.documentId, whereIn: yazarIds.toList())
          .get();

      // Kullanıcı bilgilerini bir haritada saklayın
      Map<String, Map<String, dynamic>> kullaniciMap = {
        for (var doc in kullaniciSnapshot.docs)
          doc.id: doc.data() as Map<String, dynamic>
      };
      /** ./Yazar bilgi islemi */

      // Yazılar listesini detaylı şekilde oluştur
      List<Map<String, dynamic>> tempList = yazilarSnapshot.docs.map((doc) {
        String yaziId = doc.id;
        String yazarId = doc['yazar'];
        Map<String, dynamic>? yazarBilgisi = kullaniciMap[yazarId];
        return {
          "yazarId": doc['yazar'],
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
          "begeniSayisi": begeniCountMap[yaziId] ?? 0,
          "isLiked": likedArticleIds.contains(yaziId),
        };
      }).toList();

      setState(() {
        bookmarkedArticles = tempList; // İşaretli yazıları güncelle
      });
    } catch (e) {
      print("Bookmark yazıları getirilemedi: $e");
    }
  }

  /*
  Future<void> getBookmarkedArticles() async {
    try {
      // Kullanıcının işaretlediği yazıların ID'lerini al
      QuerySnapshot isaretSnapshot = await _firestore
          .collection('Isaret')
          .where('kisi', isEqualTo: widget.userId) // Kullanıcıya göre filtrele
          .get();

      // Eğer işaretli yazı yoksa, boş bir liste döndür
      if (isaretSnapshot.docs.isEmpty) {
        setState(() {
          bookmarkedArticles = [];
        });
        return;
      }

      // İşaretli yazıların ID'lerini topla
      List<String> bookmarkedArticleIds =
          isaretSnapshot.docs.map((doc) => doc['yazi'] as String).toList();

      // İşaretli yazıları Firestore'dan getir
      QuerySnapshot yazilarSnapshot = await _firestore
          .collection('Yazi')
          .where(FieldPath.documentId, whereIn: bookmarkedArticleIds)
          .get();

      /** Begeni sayi islemi */
      // Beğenilen yazı ID'lerini topla
      QuerySnapshot begeniSnapshot2 =
          await _firestore.collection('Begeni').get();

      //List<String> likedArticleIds =  begeniSnapshot.docs.map((doc) => doc['yazi'] as String).toList();

      // Beğenileri topluca çek ve sayısını hesapla
      Map<String, int> begeniCountMap = {};
      for (var doc in begeniSnapshot2.docs) {
        //print("Beğeni Dokümanı: ${doc.data()}");

        String yaziId = doc['yazi'];
        if (begeniCountMap.containsKey(yaziId)) {
          begeniCountMap[yaziId] = begeniCountMap[yaziId]! + 1;
        } else {
          begeniCountMap[yaziId] = 1;
        }
      }
      /** ./begeni sayi islemi */

      /** Yazar bilgi islemi */
      // Yazar bilgilerini topluca çekmek için yazarlardan bir set oluştur
      Set<String> yazarIds =
          yazilarSnapshot.docs.map((doc) => doc['yazar'] as String).toSet();

      QuerySnapshot kullaniciSnapshot = await _firestore
          .collection('Kullanici')
          .where(FieldPath.documentId, whereIn: yazarIds.toList())
          .get();

      // Kullanıcı bilgilerini bir haritada saklayın
      Map<String, Map<String, dynamic>> kullaniciMap = {
        for (var doc in kullaniciSnapshot.docs)
          doc.id: doc.data() as Map<String, dynamic>
      };
      /** ./Yazar bilgi islemi */

      /* Begeni eslestir */
      User? currentUser = FirebaseAuth.instance.currentUser;
      QuerySnapshot snapshotCurrent = await _firestore
          .collection('Begeni')
          .where('kisi', isEqualTo: currentUser?.uid ?? 'BBB')
          .get();

      // Kullanıcının beğendiği yazıları bir listeye ekle
      List<String> currentBegendigiYazilar =
          snapshotCurrent.docs.map((doc) => doc['yazi'].toString()).toList();

      bool? isLiked;

      if (currentBegendigiYazilar.contains("1")) {
        isLiked = true;
      } else {
        isLiked = false;
      }
      /* Begeni eslestir */

      // Yazılar listesini detaylı şekilde oluştur
      List<Map<String, dynamic>> tempList = yazilarSnapshot.docs.map((doc) {
        String yaziId = doc.id;
        String yazarId = doc['yazar'];
        Map<String, dynamic>? yazarBilgisi = kullaniciMap[yazarId];
        return {
          "yazarId": doc['yazar'],
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
          "begeniSayisi": begeniCountMap[yaziId] ?? 0, // Beğeni sayısını ekle
          "isLiked": isLiked,
        };
      }).toList();

      setState(() {
        bookmarkedArticles = tempList; // İşaretli yazıları güncelle
      });
    } catch (e) {
      print("Bookmark yazıları getirilemedi: $e");
    }
  }*/

  //Tab her degistiginde calisan fonksiyon
  Future<void> _onTabChanged(int index) async {
    // Tab değiştirildiğinde çalışacak fonksiyon
    List<Map<String, dynamic>> updatedArticles =
        await fetchArticles(userId: widget.userId);
    await getLikedArticles();
    await getBookmarkedArticles();

    setState(() {
      articles = updatedArticles; // Yazılar listesini güncelle
      isLoading = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  //yazilari guncelleyen fonksiyon
  Future<void> fetchArticlesAndUpdateState() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Kullanıcının yazılarını ve beğenilen yazılarını getir
      List<Map<String, dynamic>> updatedArticles =
          await fetchArticles(userId: widget.userId);
      await getLikedArticles();
      await getBookmarkedArticles();

      setState(() {
        articles = updatedArticles; // Yazılar listesini güncelle
        isLoading = false;
      });
    } catch (e) {
      print("Error: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  //giris yapmis kullaniciyi kontrol eder
  Future<void> _checkLoggedInUser() async {
    // FirebaseAuth ile giriş yapan kullanıcıyı kontrol et
    User? currentUser = FirebaseAuth.instance.currentUser;

    setState(() {
      loggedInUserId = currentUser?.uid;
    });

    if (loggedInUserId == null) {
      print("Kullanıcı giriş yapmamış. (profil.dart)");
    } else {
      print("Giriş yapan kullanıcı ID: $loggedInUserId (profil.dart)");
    }
  }

  //kategorileri veritabanindan alan fonksiyon
  //  diger bir ucu functionFire.dart sayfasinda
  Future<void> loadCategories() async {
    Map<String, String> fetchedCategories = await getnamesCategory();
    setState(() {
      namesCategory = fetchedCategories;
    });
  }

  //Begenilen fonksiyonlari ceken fonksiyon
  //  fonksiyonun uzun olmasinin sebebi begeni islemleri icin
  Future<void> getLikedArticles() async {
    try {
      // Kullanıcının beğendiği yazıların ID'lerini al
      QuerySnapshot begeniSnapshot = await _firestore
          .collection('Begeni')
          .where('kisi', isEqualTo: widget.userId) // Kullanıcıya göre filtrele
          .get();

      // Eğer beğenilen yazı yoksa, boş bir liste döndür
      if (begeniSnapshot.docs.isEmpty) {
        setState(() {
          likedArticles = [];
        });
        return;
      }

      // Beğenilen yazı ID'lerini topla
      QuerySnapshot begeniSnapshot2 =
          await _firestore.collection('Begeni').get();

      List<String> likedArticleIds =
          begeniSnapshot.docs.map((doc) => doc['yazi'] as String).toList();

      // Beğenileri topluca çek ve sayısını hesapla
      Map<String, int> begeniCountMap = {};
      for (var doc in begeniSnapshot2.docs) {
        //print("Beğeni Dokümanı: ${doc.data()}");

        String yaziId = doc['yazi'];
        if (begeniCountMap.containsKey(yaziId)) {
          begeniCountMap[yaziId] = begeniCountMap[yaziId]! + 1;
        } else {
          begeniCountMap[yaziId] = 1;
        }
      }

      // Beğenilen yazıların detaylarını çek
      QuerySnapshot yazilarSnapshot = await _firestore
          .collection('Yazi')
          .where(FieldPath.documentId,
              whereIn: likedArticleIds) // ID'lere göre filtrele
          .get();

      // Yazar bilgilerini topluca çekmek için yazarlardan bir set oluştur
      Set<String> yazarIds =
          yazilarSnapshot.docs.map((doc) => doc['yazar'] as String).toSet();

      QuerySnapshot kullaniciSnapshot = await _firestore
          .collection('Kullanici')
          .where(FieldPath.documentId, whereIn: yazarIds.toList())
          .get();

      // Kullanıcı bilgilerini bir haritada saklayın
      Map<String, Map<String, dynamic>> kullaniciMap = {
        for (var doc in kullaniciSnapshot.docs)
          doc.id: doc.data() as Map<String, dynamic>
      };

      /* Begeni eslestir */
      User? currentUser = FirebaseAuth.instance.currentUser;
      QuerySnapshot snapshotCurrent = await _firestore
          .collection('Begeni')
          .where('kisi', isEqualTo: currentUser?.uid ?? 'BBB')
          .get();

      // Kullanıcının beğendiği yazıları bir listeye ekle
      List<String> currentBegendigiYazilar =
          snapshotCurrent.docs.map((doc) => doc['yazi'].toString()).toList();

      bool? isLiked;

      if (currentBegendigiYazilar.contains("1")) {
        isLiked = true;
      } else {
        isLiked = false;
      }
      /* Begeni eslestir */

      // Beğenilen yazıları detaylı şekilde listeye ekle
      List<Map<String, dynamic>> tempList = yazilarSnapshot.docs.map((doc) {
        String yaziId = doc.id;
        String yazarId = doc['yazar'];
        Map<String, dynamic>? yazarBilgisi = kullaniciMap[yazarId];
        return {
          "yazarId": doc['yazar'],
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
          "begeniSayisi": begeniCountMap[yaziId] ?? 0, // Beğeni sayısını ekle
          "isLiked": isLiked,
        };
      }).toList();

      setState(() {
        for (var item in tempList) {
          //print(item);

          if (currentBegendigiYazilar.contains(item["yazid"])) {
            item["isLiked"] = true;
          } else {
            item["isLiked"] = false;
          }
        }
        likedArticles = tempList; // Güncellenmiş beğenilen yazılar
      });
    } catch (e) {
      print("Error: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  //Kullanici Bilgilerini getiren fonksiyon
  Future<void> _fetchUserData() async {
    try {
      DocumentSnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
          .instance
          .collection('Kullanici')
          .doc(widget.userId)
          .get();

      if (snapshot.exists) {
        setState(() {
          userData = snapshot.data();
          isLoading = false;
          //bookmark
          bookmarkControl = userData != null ? userData!['isaret'] : null;
          print("isaret: $bookmarkControl");
        });
      }
    } catch (e) {
      print("Hata: $e");
    }
  }

/* ./Fonksiyonlar */

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (userData == null) {
      return const Center(child: Text("Kullanıcı bilgileri bulunamadı."));
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            if (userData?['resim'] != null &&
                (userData?['resim'] as String).isNotEmpty)
              CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(userData!['resim'] ?? ''),
              )
            else if (userData?['resim'] == "")
              CircleAvatar(
                radius: 50,
                backgroundImage: AssetImage('assets/images/demoUser.png'),
              ),

            const SizedBox(height: 5), // Boşluk

            Text(
              "${userData!['isim']} ${userData!['soyisim']}",
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5), // Boşluk
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.info_outline,
                    size: 20.0, // Küçük ikon boyutu
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text("Hakkımda"),
                          content: Text(
                            userData!['hakkinda'],
                            style: GoogleFonts.roboto(
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                              color: Colors.grey,
                            ),
                          ),
                          actions: [
                            TextButton(
                              child: Text("Kapat"),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
                Text(
                  userData!['meslek'],
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 5), // Boşluk

            if (loggedInUserId != null && loggedInUserId == widget.userId)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => postAdd(
                                  userId: widget.userId,
                                )), // Yeni sayfaya yönlendirme
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: Colors.black), // Kenarlık rengi
                      backgroundColor: Colors.black, // Dolgu rengi
                      foregroundColor: Colors.white, // Yazı rengi
                    ),
                    child: Text(
                      "Yazı Ekle",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => profilEdit(
                                  userId: widget.userId,
                                )), // Yeni sayfaya yönlendirme
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.black),
                      backgroundColor: Colors.transparent,
                    ),
                    child: Text(
                      "Profil Düzenle",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 16),

            // Tab Menüsü
            DefaultTabController(
              length: 2, // Tab sayısı
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TabBar(
                    controller: _tabController,
                    indicator: const UnderlineTabIndicator(
                      borderSide: BorderSide(
                        color: Colors.black,
                        width: 1.0,
                      ),
                    ),
                    labelColor: Colors.black,
                    unselectedLabelColor: Colors.grey,
                    tabs: [
                      Tab(
                        child: Text(
                          'Yazılar',
                          style: GoogleFonts.workSans(
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ),
                      Tab(
                        child: Text(
                          'Beğenilenler',
                          style: GoogleFonts.roboto(
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ),
                      Tab(
                        child: Text(
                          'İşaretlenenler',
                          style: GoogleFonts.roboto(
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 300, // Tab içerik yüksekliği
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        buildListView(
                          list: articles,
                          context: context,
                          onFavoriteChanged: () async {
                            List<Map<String, dynamic>> updatedArticles =
                                await fetchArticles(userId: widget.userId);
                            await getLikedArticles();
                            await getBookmarkedArticles();
                            setState(() {
                              articles =
                                  updatedArticles; // Sadece `articles` güncellenir
                            });
                          },
                          categoryNames: namesCategory,
                        ),
                        buildListView(
                          list: likedArticles,
                          context: context,
                          onFavoriteChanged: () async {
                            await fetchArticles(userId: widget.userId);
                            await getLikedArticles();
                            await getBookmarkedArticles();
                            setState(() {
                              // Sadece `likedArticles` güncellenir
                            });
                          },
                          categoryNames: namesCategory,
                        ),
                        if (bookmarkControl == "1" ||
                            widget.userId == loggedInUserId)
                          buildListView(
                            list: bookmarkedArticles, // İşaretli yazılar
                            context: context,
                            onFavoriteChanged: () async {
                              //await getBookmarkedArticles();
                              setState(() {});
                            },
                            categoryNames: namesCategory,
                          )
                        else
                          Center(
                            child: Text(
                              "Bu kullanıcı işaretlediği yazıları gizlemeyi tercih etti.",
                              style: GoogleFonts.roboto(
                                fontSize: 16,
                                fontWeight: FontWeight.normal,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
