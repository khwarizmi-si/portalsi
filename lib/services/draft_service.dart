// lib/services/draft_service.dart
import 'package:hive_flutter/hive_flutter.dart';
import '../models/draft_model.dart';

class DraftService {
  static const _boxName = 'draftsBox';

  Future<Box<Map>> _getBox() async {
    return await Hive.openBox<Map>(_boxName);
  }

  Future<void> saveDraft(Draft draft) async {
    final box = await _getBox();
    // Gunakan ID unik sebagai key
    await box.put(draft.id, draft.toMap());
  }

  Future<List<Draft>> getAllDrafts() async {
    final box = await _getBox();
    return box.values
        .map((draftMap) => Draft.fromMap(Map<String, dynamic>.from(draftMap)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Urutkan dari terbaru
  }

  Future<void> deleteDraft(String draftId) async {
    final box = await _getBox();
    await box.delete(draftId);
  }
}