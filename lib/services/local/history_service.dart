import 'db_helper.dart';

class HistoryService {
  final DbHelper _db = DbHelper.instance;

  Future<bool> addToHistory({
    required int userId,
    required String mangaSlug,
    required String mangaTitle,
    required String mangaImageUrl,
    required String chapterSlug,
    required String chapterTitle,
  }) async {
    try {
      final db = await _db.database;
      await db.insert('history', {
        'userId': userId,
        'mangaSlug': mangaSlug,
        'mangaTitle': mangaTitle,
        'mangaImageUrl': mangaImageUrl,
        'chapterSlug': chapterSlug,
        'chapterTitle': chapterTitle,
        'readAt': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getUserHistory(int userId) async {
    try {
      final db = await _db.database;
      final result = await db.query(
        'history',
        where: 'userId = ?',
        whereArgs: [userId],
        orderBy: 'readAt DESC',
      );
      return result;
    } catch (e) {
      return [];
    }
  }

  Future<bool> clearHistory(int userId) async {
    try {
      final db = await _db.database;
      await db.delete('history', where: 'userId = ?', whereArgs: [userId]);
      return true;
    } catch (e) {
      return false;
    }
  }
}
