import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../models/listing_draft.dart';
import 'listing_draft_repository.dart';

class ListingDraftRepositoryDrift implements ListingDraftRepository {
  ListingDraftRepositoryDrift(this._database);

  final AppDatabase _database;

  @override
  Future<int> saveDraft(ListingDraft draft, String imagePath) {
    return _database
        .into(_database.listingDrafts)
        .insert(
          ListingDraftsCompanion.insert(
            title: draft.title,
            category: draft.category,
            description: draft.description,
            imagePath: imagePath,
          ),
        );
  }

  @override
  Future<List<ListingDraftRow>> getAllDrafts() {
    return (_database.select(_database.listingDrafts)
          ..orderBy([(draft) => OrderingTerm.desc(draft.updatedAt)]))
        .get();
  }

  @override
  Future<void> deleteDraft(int id) async {
    await (_database.delete(
      _database.listingDrafts,
    )..where((draft) => draft.id.equals(id))).go();
  }
}
