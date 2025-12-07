import 'db_helper.dart';

class FavoritesService {
  final DbHelper _db = DbHelper.instance;

  Future<bool> addToFavorites({
    required int userId,
    required String mangaSlug,
    required String mangaTitle,
    required String mangaImageUrl,
  }) async {
    try {
      final favorite = {
        'userId': userId,
        'mangaSlug': mangaSlug,
        'mangaTitle': mangaTitle,
        'mangaImageUrl': mangaImageUrl,
        'addedAt': DateTime.now().toIso8601String(),
      };
      await _db.insertFavorite(favorite);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> removeFromFavorites(int userId, String mangaSlug) async {
    try {
      await _db.deleteFavorite(userId, mangaSlug);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> isFavorite(int userId, String mangaSlug) async {
    try {
      final favorites = await _db.getFavoritesByUserId(userId);
      return favorites.any((fav) => fav['mangaSlug'] == mangaSlug);
    } catch (e) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getUserFavorites(int userId) async {
    try {
      return await _db.getFavoritesByUserId(userId);
    } catch (e) {
      return [];
    }
  }
}
