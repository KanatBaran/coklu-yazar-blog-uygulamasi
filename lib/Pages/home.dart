import 'package:calisma_1_kesfet/Pages/profil.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

//firebase import
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

//page
import 'login.dart';
import 'search.dart';

//Components

//other
import '../function.dart';
import '../functionFire.dart';

/*** ANASAYFA (START) ***/
class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: contentHome(),
    );
  }
}

class contentHome extends StatefulWidget {
  contentHome({super.key});

  @override
  State<contentHome> createState() => _contentHomeState();
}

class _contentHomeState extends State<contentHome>
    with TickerProviderStateMixin {
  //firebase auth islemi
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? userName;
  String? userPhotoUrl;
  String? userId;

  // Firestore Baglantisi
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> articles = []; //Yazilar listesi icin
  List<Map<String, dynamic>> newsArticles = []; //En son yazilan yazilar icin
  Map<String, String> namesCategory = {}; //Kategori adlarini saklamak icin
  List<Map<String, dynamic>> mostLikedArticles = []; //En beğenilen yazılar için

  bool isLoading = true; //veri cekiminde gecikme yasanmasi durumunda kullanilir
  late TabController _tabController; //Tab menu ayarlari icin

  /* INITSTATE (START)*/
  //Bu fonksiyon ilk acilista calistirmasi gereken fonksiyonlari calistirir
  @override
  void initState() {
    super.initState();

    /* veritabanindaki butun yazilari getiren fonksiyon */
    //functionFire.dart
    fetchArticles().then((fetchedArticles) {
      setState(() {
        articles = fetchedArticles;

        newsArticles = List.from(fetchedArticles)
          ..sort((a, b) => b["tarih"].toDate().compareTo(a["tarih"].toDate()));

        mostLikedArticles = List.from(fetchedArticles)
          ..sort((a, b) => b["begeniSayisi"].compareTo(a["begeniSayisi"]));
      });
    });
    /* ./veritabanindaki butun yazilari getiren fonksiyon */

    loadCategories();

    _loadUserInfo();

    _tabController = TabController(length: 3, vsync: this);
  }
  /* INITSTATE (END) */

/* Fonksiyonlar */
//begeni islemi sonrasi yazilarin guncellenmesi
  Future<void> fetchArticlesAndUpdateState() async {
    //print("fetchArticlesAndUpdateState çağrıldı.");
    setState(() {
      isLoading = true; // Yükleme durumunu güncelledik
    });

    try {
      // Veritabanından yazıları çek
      List<Map<String, dynamic>> updatedArticles = await fetchArticles();

      // Yazılar listesini ve alt listeleri güncelle
      setState(() {
        articles = updatedArticles;

        newsArticles = List.from(updatedArticles)
          ..sort((a, b) => b["tarih"].toDate().compareTo(a["tarih"].toDate()));

        mostLikedArticles = List.from(updatedArticles)
          ..sort((a, b) => b["begeniSayisi"].compareTo(a["begeniSayisi"]));

        isLoading = false; // Yükleme tamamlandı
      });
    } catch (e) {
      print("Error: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

//giris oldugu durumda calisacak fonksiyon
  Future<void> _loadUserInfo() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('Kullanici').doc(user.uid).get();
      setState(() {
        userName = userDoc['isim'];
        userPhotoUrl = userDoc['resim'];
        userId = user.uid;
      });
    }
  }

//Kategorileri isimlendirmek icin
  Future<void> loadCategories() async {
    Map<String, String> fetchedCategories = await getnamesCategory();
    setState(() {
      namesCategory = fetchedCategories;
    });
  }

//Hesap buton fonksiyonu
  void account() {
    if (_auth.currentUser != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => Profil(userId: _auth.currentUser!.uid),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => Login()),
      );
    }
  }
/* ./Fonksiyonlar */

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 5.0, right: 5, top: 5),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Text(
                    'Home',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Spacer(),
                  Padding(
                    padding: EdgeInsets.only(right: 10.0),
                    child: Row(
                      children: [
                        if (userPhotoUrl != null && userPhotoUrl!.isNotEmpty)
                          GestureDetector(
                          onTap: account,
                          child: CircleAvatar(
                            backgroundImage: NetworkImage(userPhotoUrl!),
                          ),
                          )
                        else if (userPhotoUrl == "")
                          GestureDetector(
                          onTap: account,
                          child: CircleAvatar(
                            backgroundImage: AssetImage('assets/images/demoUser.png'),
                          ),
                          )
                        else
                          IconButton(
                            icon: Icon(Icons.person_outline),
                            onPressed: account,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: 10,
          ),

          /* Tabbar Menu */
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: const Color.fromARGB(176, 158, 158, 158),
                      width: 1,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: IconButton(
                    icon: Icon(Icons.search),
                    onPressed: () {
                      
                     Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => Search()),
                      ); 
                    },
                  ),
                ),
              ),
              Expanded(
                child: TabBar(
                  controller: _tabController,
                  tabs: <Widget>[
                    Tab(
                      child: Text(
                        'Yazilar',
                        style: GoogleFonts.workSans(
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ),
                    Tab(
                      child: Text(
                        'Yeniler',
                        style: GoogleFonts.roboto(
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ),
                    Tab(
                      child: Text(
                        'Begenilenler',
                        style: GoogleFonts.roboto(
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                  indicator: UnderlineTabIndicator(
                    borderSide: BorderSide(
                      color: Colors.black,
                      width: 1.0,
                    ),
                  ),
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.grey,
                ),
              ),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                buildListView(
                  list: articles,
                  context: context,
                  onFavoriteChanged: fetchArticlesAndUpdateState,
                  categoryNames: namesCategory,
                ),
                buildListView(
                  list: newsArticles,
                  context: context,
                  onFavoriteChanged: fetchArticlesAndUpdateState,
                  categoryNames: namesCategory,
                ),
                buildListView(
                  list: mostLikedArticles,
                  context: context,
                  onFavoriteChanged: fetchArticlesAndUpdateState,
                  categoryNames: namesCategory,
                ),
              ],
            ),
          ),

/* ./Tabbar Menu */
        ],
      ),
    );
  }
}
/*** ANASAYFA (END) ***/

