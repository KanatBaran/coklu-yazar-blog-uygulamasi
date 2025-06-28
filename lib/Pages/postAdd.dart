import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:zefyrka/zefyrka.dart';

//pages
import 'profil.dart';
import 'postAddFinal.dart';

class postAdd extends StatelessWidget {
  final String userId;
  // GlobalKey tanımlama
  final GlobalKey<_contentPostAddState> contentPostKey = GlobalKey<_contentPostAddState>();

   postAdd({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.close,
              color: Colors.black), // Sol tarafta geri ok ikonu
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => Profil(
                  userId: userId,
                ),
              ),
            );
          },
        ),
        title: Text(""),
        backgroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(
                right: 16.0), // Sağdan biraz boşluk bırakıyoruz
            child: OutlinedButton(
              onPressed: () {
                contentPostKey.currentState?.Paylas();
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.black), // Kenarlık rengi
                backgroundColor: Colors.black, // Dolgu rengi
                foregroundColor: Colors.white, // Yazı rengi
              ),
              child: Text(
                "İlerle",
                style: TextStyle(), // Yazı stili
              ),
            ),
          ),
        ],
      ),
      body: contentPostAdd(
        key: contentPostKey,
        userId: userId,
      ),
    );
  }
}

class contentPostAdd extends StatefulWidget {
  final String userId;

  const contentPostAdd({super.key, required this.userId});

  @override
  State<contentPostAdd> createState() => _contentPostAddState();
}

class _contentPostAddState extends State<contentPostAdd> {
  /** Degiskenler */
  late ZefyrController _controller;
  late FocusNode _focusNode;

  // Başlık seçenekleri
  final List<String> headingOptions = [
    'Normal Text',
    'Heading 1',
    'Heading 2',
    'Heading 3'
  ];
  String selectedHeading = 'Normal Text';

  /** Degiskenler */

  /* FONKSIYONLAR */
  //paylas butonu icin fonksiyon
  void Paylas() {

    //print("calisti");

    final String plainText = _controller.document.toPlainText(); // Düz metin
    final deltaJson = jsonEncode(_controller.document.toDelta().toJson());

   //print("Gönderilen Delta JSON: $deltaJson");

    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => PostAddFinal(
          userId: widget.userId, // Kullanıcı ID'sini gönder
          plainText: plainText, // Düz metni gönder
          deltaJson: deltaJson, // JSON formatındaki metni gönder
        ),),
    );
  }

  //initState
  @override
  void initState() {
    super.initState();

    // Başlangıç içeriği
    final document = NotusDocument();
    _controller = ZefyrController(document);
    _focusNode = FocusNode();

    // Listener ekleyerek değişiklikleri dinle
    _controller.addListener(() {
      setState(
          () {}); // HintText'in görünürlüğünü kontrol etmek için state'i yenile
    });
  }

  //dispose
  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // Yazı türünü değiştirme fonksiyonu
  void _changeHeading(String value) {
    setState(() {
      selectedHeading = value;

      // Yazı türünü ZefyrController üzerinden değiştir
      if (value == 'Normal Text') {
        _controller.formatSelection(NotusAttribute.heading.unset);
      } else if (value == 'Heading 1') {
        _controller.formatSelection(NotusAttribute.heading.level1);
      } else if (value == 'Heading 2') {
        _controller.formatSelection(NotusAttribute.heading.level2);
      } else if (value == 'Heading 3') {
        _controller.formatSelection(NotusAttribute.heading.level3);
      }
    });
  }
  /* ./FONKSIYONLAR */

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(10),
      child: Column(
        children: [
          // Editör Alanı
          Expanded(
            child: Stack(
              children: [
                // HintText
                Positioned.fill(
                  child: Visibility(
                    visible: _controller.document.toPlainText().trim().isEmpty,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Bu alana yazmaya başlayabilirsiniz...', // HintText
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),

                // ZefyrEditor
                ZefyrEditor(
                  controller: _controller,
                  focusNode: _focusNode,
                  autofocus: true,
                ),
              ],
            ),
          ),

          // Özel Araç Çubuğu
          Container(
            height: 56.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  color: Colors.black,
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
                  width: 30,
                ),
                // Yazı Türü Dropdown
                DropdownButton<String>(
                  value: selectedHeading,
                  items: headingOptions.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      _changeHeading(newValue);
                    }
                  },
                ),
                SizedBox(
                  width: 30,
                ),
                IconButton(
                  icon:
                      Icon(Icons.format_list_bulleted), // Madde işaretli liste
                  onPressed: () {
                    _controller
                        .formatSelection(NotusAttribute.ul); // Madde işaretli
                  },
                ),
                IconButton(
                  icon: Icon(Icons.format_list_numbered), // Numaralı liste
                  onPressed: () {
                    _controller
                        .formatSelection(NotusAttribute.ol); // Numaralı liste
                  },
                ),
                SizedBox(
                  width: 30,
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
          ),
        ],
      ),
    );
  }
}
