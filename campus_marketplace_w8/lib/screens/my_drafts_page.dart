import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../models/item.dart';
import '../repositories/item_repository_firestore.dart';
import '../repositories/listing_draft_repository.dart';
import 'sell_item_page.dart';

const _freePlanSampleImageUrl =
    'https://images.unsplash.com/photo-1512058564366-18510be2db19?auto=format&fit=crop&w=900&q=85';

class MyDraftsPage extends StatefulWidget {
  const MyDraftsPage({super.key, required this.draftRepository});

  final ListingDraftRepository draftRepository;

  @override
  State<MyDraftsPage> createState() => _MyDraftsPageState();
}

class _MyDraftsPageState extends State<MyDraftsPage> {
  late Future<List<ListingDraftRow>> _draftsFuture;
  int? _postingDraftId;

  @override
  void initState() {
    super.initState();
    _refreshDrafts();
  }

  void _refreshDrafts() {
    _draftsFuture = widget.draftRepository.getAllDrafts();
  }

  Future<double?> _askPrice(ListingDraftRow draft) async {
    final initialPrice = draft.title == 'ข้าวกะเพราหมูกรอบ' ? '60' : '';
    var enteredPrice = initialPrice;
    String? errorText;
    final price = await showDialog<double>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('ตั้งราคาสินค้า'),
          content: TextFormField(
            initialValue: initialPrice,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (value) => enteredPrice = value,
            decoration: InputDecoration(
              labelText: 'ราคา (บาท)',
              errorText: errorText,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('ยกเลิก'),
            ),
            FilledButton(
              onPressed: () {
                final value = double.tryParse(enteredPrice.trim());
                if (value == null || !value.isFinite || value <= 0) {
                  setDialogState(
                    () => errorText = 'กรอกราคาเป็นตัวเลขที่มากกว่า 0',
                  );
                  return;
                }
                Navigator.pop(dialogContext, value);
              },
              child: const Text('ต่อไป'),
            ),
          ],
        ),
      ),
    );
    return price;
  }

  Future<bool> _confirmFreeImage() async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('โพสต์ด้วยแผนฟรี'),
            content: const Text(
              'ประกาศจะใช้รูปอาหารตัวอย่างจาก URL สาธารณะ '
              'รูปที่เลือกจากเครื่องจะยังอยู่ในร่างและไม่ถูกอัปโหลดเข้า Firebase Storage',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('กลับไปก่อน'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('โพสต์ด้วยรูปตัวอย่างฟรี'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _postDraft(ListingDraftRow draft) async {
    final seller = FirebaseAuth.instance.currentUser;
    if (seller == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเข้าสู่ระบบก่อนโพสต์สินค้า')),
      );
      return;
    }
    final price = await _askPrice(draft);
    if (price == null || !mounted) return;
    final useFreeSampleImage = await _confirmFreeImage();
    if (!useFreeSampleImage || !mounted) return;

    setState(() => _postingDraftId = draft.id);
    try {
      final item = Item(
        id: 'listing_${seller.uid}_${draft.id}',
        title: draft.title,
        price: price,
        description: draft.description,
        category: draft.category,
        imageUrl: _freePlanSampleImageUrl,
        sellerId: seller.uid,
      );
      await ItemRepositoryFirestore().postItem(item);
      await widget.draftRepository.deleteDraft(draft.id);
      if (!mounted) return;
      setState(() {
        _postingDraftId = null;
        _refreshDrafts();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('โพสต์ "${draft.title}" สำเร็จแล้ว')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _postingDraftId = null);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('โพสต์สินค้าไม่สำเร็จ: $error')));
    }
  }

  Future<void> _createDraft() async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => SellItemPage(draftRepository: widget.draftRepository),
      ),
    );
    if (!mounted) return;
    setState(_refreshDrafts);
  }

  Future<void> _deleteDraft(ListingDraftRow draft) async {
    try {
      await widget.draftRepository.deleteDraft(draft.id);
      if (!mounted) return;
      setState(_refreshDrafts);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ลบร่างสินค้าแล้ว')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ลบร่างสินค้าไม่สำเร็จ: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ร่างของฉัน')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _postingDraftId == null ? _createDraft : null,
        icon: const Icon(Icons.add_a_photo),
        label: const Text('สร้างร่าง'),
      ),
      body: FutureBuilder<List<ListingDraftRow>>(
        future: _draftsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('โหลดร่างไม่สำเร็จ: ${snapshot.error}'));
          }
          final drafts = snapshot.data ?? [];
          if (drafts.isEmpty) {
            return const Center(
              child: Text('ยังไม่มีร่างประกาศ กด “สร้างร่าง” เพื่อเริ่มต้น'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: drafts.length,
            itemBuilder: (context, index) {
              final draft = drafts[index];
              final isPosting = _postingDraftId == draft.id;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(draft.imagePath),
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image),
                    ),
                  ),
                  title: Text(draft.title),
                  subtitle: Text(draft.category),
                  isThreeLine: true,
                  trailing: isPosting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'post') {
                              _postDraft(draft);
                            } else if (value == 'delete') {
                              _deleteDraft(draft);
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: 'post',
                              child: Text('โพสต์ขายจริง'),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('ลบร่าง'),
                            ),
                          ],
                        ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
