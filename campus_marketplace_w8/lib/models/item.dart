import 'package:cloud_firestore/cloud_firestore.dart';

class Item {
  final String id;
  final String title;
  final double price;
  final String description;
  final String category;
  final String imageUrl;
  final String? sellerId;

  const Item({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
    required this.category,
    required this.imageUrl,
    this.sellerId,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    final id = json['id'].toString();
    final title = json['title'] as String;
    final price = (json['price'] as num).toDouble();
    final description = json['description'] as String;
    final category = json['category'] as String;
    final imageUrl = json['image'] as String;

    return Item(
      id: id,
      title: title,
      price: price,
      description: description,
      category: category,
      imageUrl: imageUrl,
    );
  }

  factory Item.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    if (data == null) {
      throw StateError('ไม่พบข้อมูลสินค้าในเอกสาร ${document.id}');
    }

    return Item(
      id: document.id,
      title: data['title'] as String,
      price: (data['price'] as num).toDouble(),
      description: data['description'] as String,
      category: data['category'] as String,
      imageUrl: data['imageUrl'] as String,
      sellerId: data['sellerId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'title': title,
    'price': price,
    'description': description,
    'category': category,
    'imageUrl': imageUrl,
    'sellerId': sellerId,
  };
}