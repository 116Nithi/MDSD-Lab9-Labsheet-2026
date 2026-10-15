import 'package:campus_marketplace_w7/database/app_database.dart';
import 'package:campus_marketplace_w7/models/listing_draft.dart';
import 'package:campus_marketplace_w7/repositories/listing_draft_repository_drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late ListingDraftRepositoryDrift repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = ListingDraftRepositoryDrift(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('saves, lists, and deletes listing drafts', () async {
    final id = await repository.saveDraft(
      const ListingDraft(
        title: 'ข้าวกะเพราหมูกรอบ',
        category: 'อาหาร',
        description: 'เสิร์ฟพร้อมข้าวสวยร้อน ๆ',
      ),
      'C:/draft_images/basil_pork_rice.jpg',
    );

    final drafts = await repository.getAllDrafts();
    expect(drafts, hasLength(1));
    expect(drafts.single.id, id);
    expect(drafts.single.title, 'ข้าวกะเพราหมูกรอบ');
    expect(drafts.single.imagePath, 'C:/draft_images/basil_pork_rice.jpg');

    await repository.deleteDraft(id);
    expect(await repository.getAllDrafts(), isEmpty);
  });
}
