import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/listing_draft.dart';
import '../repositories/listing_draft_repository.dart';

class SellItemPage extends StatefulWidget {
  const SellItemPage({super.key, required this.draftRepository});

  final ListingDraftRepository draftRepository;

  @override
  State<SellItemPage> createState() => _SellItemPageState();
}

class _SellItemPageState extends State<SellItemPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController(text: 'ข้าวกะเพราหมูกรอบ');
  final _categoryController = TextEditingController(text: 'อาหาร');
  final _descriptionController = TextEditingController(
    text: 'ข้าวกะเพราหมูกรอบ เสิร์ฟพร้อมข้าวสวยร้อน ๆ',
  );
  final _picker = ImagePicker();

  String? _imagePath;
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<String> _persistImage(File source) async {
    final directory = await getApplicationDocumentsDirectory();
    final imageDirectory = Directory(p.join(directory.path, 'draft_images'));
    await imageDirectory.create(recursive: true);
    final extension = p.extension(source.path);
    final destination = File(
      p.join(
        imageDirectory.path,
        '${DateTime.now().microsecondsSinceEpoch}$extension',
      ),
    );
    await source.copy(destination.path);
    return destination.path;
  }

  Future<void> _pickImage() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image == null) return;

      final path = await _persistImage(File(image.path));
      if (!mounted) return;
      setState(() => _imagePath = path);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เลือกรูปสินค้าไม่สำเร็จ: $error')),
      );
    }
  }

  Future<void> _useDishPhoto({
    required String assetPath,
    required String title,
    required String description,
  }) async {
    setState(() => _saving = true);
    try {
      final asset = await rootBundle.load(assetPath);
      final directory = await getApplicationDocumentsDirectory();
      final imageDirectory = Directory(p.join(directory.path, 'draft_images'));
      await imageDirectory.create(recursive: true);
      final path = p.join(
        imageDirectory.path,
        '${DateTime.now().microsecondsSinceEpoch}.jpg',
      );
      await File(path).writeAsBytes(
        asset.buffer.asUint8List(asset.offsetInBytes, asset.lengthInBytes),
        flush: true,
      );
      if (!mounted) return;
      setState(() {
        _imagePath = path;
        _titleController.text = title;
        _categoryController.text = 'อาหาร';
        _descriptionController.text = description;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('เลือกรูป "$title" แล้ว')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ใช้รูปตัวอย่างไม่ได้: $error')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveDraft() async {
    if (!_formKey.currentState!.validate()) return;
    final imagePath = _imagePath;
    if (imagePath == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('กรุณาเลือกรูปสินค้า')));
      return;
    }

    setState(() => _saving = true);
    try {
      await widget.draftRepository.saveDraft(
        ListingDraft(
          title: _titleController.text.trim(),
          category: _categoryController.text.trim(),
          description: _descriptionController.text.trim(),
        ),
        imagePath,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('บันทึกร่างสินค้าแล้ว')));
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('บันทึกร่างไม่สำเร็จ: $error')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('สร้างร่างประกาศ')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'ชื่อสินค้า',
                border: OutlineInputBorder(),
              ),
              maxLength: 100,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'กรุณากรอกชื่อสินค้า'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'หมวดหมู่',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'กรุณากรอกหมวดหมู่'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'รายละเอียด',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'กรุณากรอกรายละเอียดสินค้า'
                  : null,
            ),
            const SizedBox(height: 16),
            if (_imagePath != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(_imagePath!),
                  height: 200,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                height: 140,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('เลือกรูปสินค้าก่อนบันทึก'),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _saving ? null : _pickImage,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('เลือกรูปจากเครื่อง'),
            ),
            OutlinedButton.icon(
              onPressed: _saving
                  ? null
                  : () => _useDishPhoto(
                      assetPath: 'assets/krapao_moo_krob.jpg',
                      title: 'ข้าวกะเพราหมูกรอบ',
                      description:
                          'ข้าวกะเพราหมูกรอบ เสิร์ฟพร้อมไข่ดาวและข้าวสวยร้อน ๆ',
                    ),
              icon: const Icon(Icons.restaurant),
              label: const Text('ใช้รูปข้าวกะเพราหมูกรอบ'),
            ),
            OutlinedButton.icon(
              onPressed: _saving
                  ? null
                  : () => _useDishPhoto(
                      assetPath: 'assets/krapao_moo.jpg',
                      title: 'ข้าวกะเพราหมู',
                      description:
                          'ข้าวกะเพราหมูสับ เสิร์ฟพร้อมไข่ดาวและข้าวสวยร้อน ๆ',
                    ),
              icon: const Icon(Icons.restaurant_menu),
              label: const Text('ใช้รูปข้าวกะเพราหมู'),
            ),
            Text(
              'รูปอาหารจากภาพที่คุณส่งมา',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _saveDraft,
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('บันทึกร่าง'),
            ),
          ],
        ),
      ),
    );
  }
}
