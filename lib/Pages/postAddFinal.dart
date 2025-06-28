import 'dart:convert';

import 'package:calisma_1_kesfet/Pages/profil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zefyrka/zefyrka.dart';

//Resim yuklemek icin
import 'package:cloudinary/cloudinary.dart';
import 'package:image_picker/image_picker.dart';

import 'postAdd.dart';

class PostAddFinal extends StatelessWidget {
  final String userId;
  final String plainText;
  final String deltaJson;

  PostAddFinal({
    super.key,
    required this.userId,
    required this.plainText,
    required this.deltaJson,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);

            /*
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => postAdd(
                        userId: userId,
                      )), 
            );*/
          },
        ),
        title: Text("Başlık, Resim ve Kategori"),
        backgroundColor: Colors.white,
        actions: [],
      ),
      body: contentPostAddFinal(
        userId: userId,
        deltaJson: deltaJson,
        plainText: plainText,
      ),
    );
  }
}

class contentPostAddFinal extends StatefulWidget {
  final String userId;
  final String plainText;
  final String deltaJson;

  const contentPostAddFinal({
    super.key,
    required this.userId,
    required this.plainText,
    required this.deltaJson,
  });

  @override
  State<contentPostAddFinal> createState() => _contentPostAddFinalState();
}

class _contentPostAddFinalState extends State<contentPostAddFinal> {
  /** DEGISKENLER (START) */
  late NotusDocument _document;

  final TextEditingController _baslikController = TextEditingController();
  final TextEditingController _icerikController = TextEditingController();

  //resim icin
  String? _uploadedImageUrl;
  String? buttonText = "Resim Ekle";

  //Kategoriler icin
  String? _selectedKategori;
  List<DropdownMenuItem<String>> _kategoriItems = [];
  /** DEGISKENLER (END) */

  /** FONKSIYONLAR (START) */

  //initState
  @override
  void initState() {
    super.initState();

    //veritabanindan kategori getirme
    _loadKategoriler();

    //print("Alınan Delta JSON: ${widget.deltaJson}");
    try {
      final decodedJson = jsonDecode(widget.deltaJson); // JSON'u decode et
      _document =
          NotusDocument.fromJson(decodedJson); // NotusDocument olarak ata
      print("Başarıyla Yüklendi: $decodedJson"); // Kontrol için
    } catch (e) {
      print("JSON Decode Hatası: $e"); // Hata durumunu logla
    }
  }

  //Yazi kapak resmini resim platformuna yukleyen foknsiyon
  Future<void> _uploadImage() async {
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
          _uploadedImageUrl = response.secureUrl; // Cloudinary'den gelen URL
          buttonText = "Resmi Değiştir";
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Resim başarıyla yüklendi!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Resim yükleme başarısız oldu!')),
        );
      }
    }
  }

  //Kategorileri getiren fonksiyon
  Future<void> _loadKategoriler() async {
    try {
      QuerySnapshot kategoriSnapshot =
          await FirebaseFirestore.instance.collection('Kategori').get();

      setState(() {
        _kategoriItems = kategoriSnapshot.docs
            .map((doc) => DropdownMenuItem(
                  value: doc.id, // Kategori ID'si
                  child: Text(doc['baslik']), // Kategori adı
                ))
            .toList();
      });
    } catch (e) {
      print('Kategoriler yüklenirken hata: $e');
    }
  }

  //Yazi ekleme fonksiyon
  Future<void> _yaziEkle() async {
    if (_selectedKategori != null) {
      try {
        if (widget.userId != null) {
          // Koleksiyondaki mevcut belge sayısını al
          QuerySnapshot yaziSnapshot =
              await FirebaseFirestore.instance.collection('Yazi').get();

          int yeniId = yaziSnapshot.docs.length + 1; // Sıradaki ID'yi belirle

          //print("Burda" + yeniId.toString());

          await FirebaseFirestore.instance
              .collection('Yazi')
              //.doc(yeniId.toString()) // Sıralı ID'yi kullan
              .doc()
              .set({
            'baslik': _baslikController.text,
            'icerik': widget.plainText,
            'icerikJSON': widget.deltaJson,
            'kategori': _selectedKategori,
            'yazar': widget.userId,
            'tarih': Timestamp.now(),
            'resim': _uploadedImageUrl,
          });

          // Başarı bildirimini göster
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Yazınız başarıyla kaydedildi!')),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => Profil(userId: widget.userId),
            ),
          ); // Yazı eklendikten sonra profil sayfasına yönlendir
        }
      } catch (e) {
        print('Yazı eklenirken hata: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Yazı eklenirken bir hata oluştu: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lütfen kategori seçin.')),
      );

      return;
    }
  }
  /** FONKSIYONLAR (END) */

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  'Başlık',
                  style: GoogleFonts.roboto(
                      fontWeight: FontWeight.normal, fontSize: 12),
                ),
              ],
            ),
            TextFormField(
              controller: _baslikController,
              decoration: InputDecoration(
                hintText: 'Kısa ve açıklayıcı bir başlık giriniz',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ad alanı boş bırakılamaz.';
                }
                return null;
              },
            ),
            SizedBox(
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  'Resim',
                  style: GoogleFonts.roboto(
                      fontWeight: FontWeight.normal, fontSize: 12),
                ),
              ],
            ),
            Row(
              children: [
                OutlinedButton(
                  onPressed: _uploadImage,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.black),
                    backgroundColor: Colors.transparent,
                  ),
                  child: Text(
                    buttonText!,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
                SizedBox(width: 10),
                if (_uploadedImageUrl != null)
                  Image.network(
                    _uploadedImageUrl!,
                    height: 150,
                    width: 150,

                    fit: BoxFit.cover, // Görselin kesilmesini önlemek için
                  ),
                SizedBox(height: 20),
              ],
            ),
            SizedBox(
              height: 20,
            ),
            Row(
              children: [
                Text(
                  'Kategori',
                  style: GoogleFonts.roboto(
                      fontWeight: FontWeight.normal, fontSize: 12),
                ),
              ],
            ),
            DropdownButtonFormField<String>(
              value: _selectedKategori,
              items: _kategoriItems,
              onChanged: (value) {
                setState(() {
                  _selectedKategori = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Seçim Yap',
              ),
              validator: (value) {
                if (value == null) {
                  return 'Lütfen bir kategori seçin';
                }
                return null;
              },
            ),

            SizedBox(
              height: 20,
            ),

            Row(
              children: [
                Text(
                  'Yazı Önizleme',
                  style: GoogleFonts.roboto(
                      fontWeight: FontWeight.normal, fontSize: 12),
                ),
              ],
            ),

            Expanded(
              child: ZefyrEditor(
                controller: ZefyrController(_document),
                readOnly: true, // Düzenlemeyi devre dışı bırak
              ),
            ), // Delta formatını göster

            ElevatedButton(
              onPressed: _yaziEkle,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, // Arkaplan rengi yeşil
                foregroundColor: Colors.white, // Yazı rengi beyaz
              ),
              child: Text('Yazıyı Yayınla!'),
            )
          ],
        ),
      ),
    );
  }
}

/**
 children: [
            Text(data),
            Text(
              "Kullanıcı ID:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(widget.userId), // Kullanıcı ID'sini göster

            SizedBox(height: 16),

            Text(
              "Düz Metin:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(widget.plainText), // Düz metni göster

            SizedBox(height: 16),

            Text(
              "Delta JSON:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ZefyrEditor(
                controller: ZefyrController(_document),
                readOnly: true, // Düzenlemeyi devre dışı bırak
              ),
            ), // Delta formatını göster
          ],
 */
