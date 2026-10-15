import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import 'package:campus_marketplace_w7/models/cart_model.dart';
import 'package:campus_marketplace_w7/models/item.dart';
import 'package:campus_marketplace_w7/repositories/item_repository.dart';
import 'package:campus_marketplace_w7/screens/home_page.dart';

class _FakeItemRepository implements ItemRepository {
  @override
  Future<List<Item>> getItems() => Completer<List<Item>>().future;
}

class _ImmediateItemRepository implements ItemRepository {
  _ImmediateItemRepository(this.items);

  final List<Item> items;

  @override
  Future<List<Item>> getItems() async => items;
}

void main() {
  testWidgets('shows app title and loading state', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => CartModel(),
        child: MaterialApp(
          title: 'Campus Marketplace',
          home: HomePage(repositories: [_FakeItemRepository()]),
        ),
      ),
    );

    expect(find.text('Campus Marketplace'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('combines repositories and labels each listing source', (
    WidgetTester tester,
  ) async {
    final apiItem = Item(
      id: '1',
      title: 'API item',
      price: 10,
      description: '',
      category: '',
      imageUrl: '',
    );
    final studentItem = Item(
      id: 'firestore-1',
      title: 'Student item',
      price: 20,
      description: '',
      category: '',
      imageUrl: '',
      sellerId: 'seller-1',
    );

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => CartModel(),
        child: MaterialApp(
          home: HomePage(
            repositories: [
              _ImmediateItemRepository([apiItem]),
              _ImmediateItemRepository([studentItem]),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('API item'), findsOneWidget);
    expect(find.text('Student item'), findsOneWidget);
    expect(find.text('🏪 API'), findsOneWidget);
    expect(find.text('🎓 นักศึกษา'), findsOneWidget);
  });
}
