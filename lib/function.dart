import 'package:cloud_firestore/cloud_firestore.dart';

Future<Map<String, String>> getnamesCategory() async {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, String> namesCategory = {};

  try {
    QuerySnapshot querySnapshot = await _firestore.collection('Kategori').get();
    for (var doc in querySnapshot.docs) {
      namesCategory[doc.id] = doc["baslik"];
    }
  } catch (e) {
    print("Kategori başlıkları yüklenirken hata: $e");
  }

  return namesCategory;
}


String formatReadableDateManual(DateTime date) {
  // Ayları Türkçe yazmak için bir liste tanımlıyoruz.
  const List<String> months = [
    "Ocak",
    "Şubat",
    "Mart",
    "Nisan",
    "Mayıs",
    "Haziran",
    "Temmuz",
    "Ağustos",
    "Eylül",
    "Ekim",
    "Kasım",
    "Aralık"
  ];

  // Günü, ayı ve yılı formatlıyoruz.
  String day = date.day.toString();
  String month = months[date.month - 1];
  String year = date.year.toString();


  // "11 Kasım 2024, Pazartesi" şeklinde bir çıktı
  return "$day $month $year";
}