import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/item.dart';
import 'item_repository.dart';

class ItemRepositoryFirestore implements ItemRepository {
  ItemRepositoryFirestore({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  CollectionReference<Map<String, dynamic>> get _items =>
      _firestore.collection('items');

  @override
  Future<List<Item>> getItems() async {
    final snapshot = await _items.get();
    return snapshot.docs.map(Item.fromFirestore).toList();
  }

  Future<void> postItem(Item item) async {
    if (item.id.isEmpty) {
      await _items.add(item.toFirestore());
      return;
    }
    await _items.doc(item.id).set(item.toFirestore());
  }

  Stream<List<Item>> watchMyListings(String sellerId) {
    return _items
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Item.fromFirestore).toList());
  }
}
