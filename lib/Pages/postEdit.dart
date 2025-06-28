import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:zefyrka/zefyrka.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary/cloudinary.dart';

//pages
import 'profil.dart';

class PostEdit extends StatefulWidget {
  final String postId;

  const PostEdit({super.key, required this.postId});

  @override
  State<PostEdit> createState() => _PostEditState();
}

class _PostEditState extends State<PostEdit> {
  /** Değişkenler */
  late ZefyrController _controller;
  late FocusNode _focusNode;
  final TextEditingController _baslikController = TextEditingController();
  String? _uploadedImageUrl;
  String? _selectedKategori;
  String selectedHeading = 'Normal Text'; // Seçilen başlık seviyesi
  List<DropdownMenuItem<String>> _kategoriItems = [];
  bool _isLoading = true;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /** Fonksiyonlar */
  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _loadPostData();
    _loadKategoriler();
  }

  Future<void> _loadPostData() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Yazi')
          .doc(widget.postId)
          .get();

      if (snapshot.exists) {
        setState(() {
          _baslikController.text = snapshot['baslik'];
          _uploadedImageUrl = snapshot['resim'];
          _selectedKategori = snapshot['kategori'];

          final deltaJson = snapshot['icerikJSON'];
          final document = NotusDocument.fromJson(jsonDecode(deltaJson));
          _controller = ZefyrController(document);

          _isLoading = false;
        });
      }
    } catch (e) {
      print("Veri yükleme hatası: $e");
    }
  }

  Future<void> _loadKategoriler() async {
    try {
      final kategoriSnapshot =
          await FirebaseFirestore.instance.collection('Kategori').get();

      setState(() {
        _kategoriItems = kategoriSnapshot.docs
            .map((doc) => DropdownMenuItem(
                  value: doc.id,
                  child: Text(doc['baslik']),
                ))
            .toList();

            
      });
    } catch (e) {
      print('Kategoriler yüklenirken hata: $e');
    }
  }

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
          _uploadedImageUrl = response.secureUrl;
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

  Future<void> _updatePost() async {
    try {
      final updatedData = {
        'baslik': _baslikController.text,
        'icerik': _controller.document.toPlainText(),
        'icerikJSON': jsonEncode(_controller.document.toDelta().toJson()),
        'kategori': _selectedKategori,
        'resim': _uploadedImageUrl,
        'tarih': Timestamp.now(),
      };

      await FirebaseFirestore.instance
          .collection('Yazi')
          .doc(widget.postId)
          .update(updatedData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Yazınız başarıyla güncellendi!')),
      );
    } catch (e) {
      print('Yazı güncellenirken hata: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Yazı güncellenirken bir hata oluştu: $e')),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _baslikController.dispose();
    super.dispose();
  }

  // Araç çubuğu düğmeleri
  Widget _buildToolbar() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.grey[200],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(Icons.format_bold),
            onPressed: () {
              _controller.formatSelection(NotusAttribute.bold);
            },
          ),
          IconButton(
            icon: Icon(Icons.format_italic),
            onPressed: () {
              _controller.formatSelection(NotusAttribute.italic);
            },
          ),
          SizedBox(
            width: 20,
          ),
          DropdownButton<String>(
            value: selectedHeading,
            items: ['Normal Text', 'Heading 1', 'Heading 2', 'Heading 3']
                .map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                selectedHeading = newValue ?? 'Normal Text';

                if (selectedHeading == 'Normal Text') {
                  _controller.formatSelection(NotusAttribute.heading.unset);
                } else if (selectedHeading == 'Heading 1') {
                  _controller.formatSelection(NotusAttribute.heading.level1);
                } else if (selectedHeading == 'Heading 2') {
                  _controller.formatSelection(NotusAttribute.heading.level2);
                } else if (selectedHeading == 'Heading 3') {
                  _controller.formatSelection(NotusAttribute.heading.level3);
                }
              });
            },
          ),
          SizedBox(
            width: 20,
          ),
          IconButton(
            icon: Icon(Icons.format_list_bulleted), // Madde işaretli liste
            onPressed: () {
              _controller.formatSelection(NotusAttribute.ul); // Madde işaretli
            },
          ),
          IconButton(
            icon: Icon(Icons.format_list_numbered), // Numaralı liste
            onPressed: () {
              _controller.formatSelection(NotusAttribute.ol); // Numaralı liste
            },
          ),
          SizedBox(
            width: 20,
          ),
          IconButton(
            icon: Icon(Icons.format_quote), // Alıntı ikonu
            onPressed: () {
              _controller.formatSelection(
                  NotusAttribute.block.quote); // Alıntı özelliği
            },
          ),
          IconButton(
            icon: Icon(Icons.code),
            onPressed: () {
              _controller.formatSelection(NotusAttribute.block.code);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Varsayılan geri ikonu kaldırılır
        title: Text('Yazı Düzenle'),
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black), // Geri gitme ikonu
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => Profil(userId: _auth.currentUser!.uid),
              ),
            );
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.save_as, color: Colors.black), // Kaydet ikonu
            onPressed: _updatePost, // Kaydetme fonksiyonu
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              children: [
                TextFormField(
                  controller: _baslikController,
                  decoration: InputDecoration(
                    labelText: 'Başlık',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedKategori,
                  items: _kategoriItems,
                  onChanged: (value) {
                    setState(() {
                      _selectedKategori = value;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Kategori',
                  ),
                ),
                SizedBox(height: 10),
                if (_uploadedImageUrl != null)
                  Image.network(
                    _uploadedImageUrl!,
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                SizedBox(
                  height: 5,
                ),
                ElevatedButton(
                  onPressed: _uploadImage,
                  child: Text('Resmi Güncelle'),
                ),
              ],
            ),
          ),
          _buildToolbar(), // Araç çubuğunu burada ekliyoruz
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: ZefyrEditor(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
