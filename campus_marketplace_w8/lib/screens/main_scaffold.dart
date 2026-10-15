import 'package:flutter/material.dart';

import '../repositories/listing_draft_repository.dart';
import '../repositories/item_repository.dart';
import 'home_page.dart';
import 'my_drafts_page.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({
    super.key,
    required this.itemRepositories,
    required this.draftRepository,
  });

  final List<ItemRepository> itemRepositories;
  final ListingDraftRepository draftRepository;

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;
  int _homeRefreshKey = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
        key: ValueKey(_homeRefreshKey),
        repositories: widget.itemRepositories,
      ),
      MyDraftsPage(draftRepository: widget.draftRepository),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          if (index == 0 && _selectedIndex != 0) {
            _homeRefreshKey++;
          }
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.storefront),
            label: 'หน้าหลัก',
          ),
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            label: 'ร่างของฉัน',
          ),
        ],
      ),
    );
  }
}
