import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/user_model.dart';

class DbHelper {
  static Database? _database;
  static const String _dbName = 'manga_app_db.db';
  static const String _tableName = 'users';
  static const String _favoritesTable = 'favorites';
  static const String _historyTable = 'history';
  static const String _chaptersTable = 'chapters';

  // Singleton Instance
  DbHelper._privateConstructor();
  static final DbHelper instance = DbHelper._privateConstructor();

  // Getter untuk Database
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  // Inisialisasi Database
  Future<Database> _initDb() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _dbName);

    return await openDatabase(
      path,
      version: 3, // Increased version for new chapters table
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // Membuat tabel
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fullName TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        passwordHash TEXT NOT NULL,
        salt TEXT NOT NULL,
        role TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_favoritesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        mangaSlug TEXT NOT NULL,
        mangaTitle TEXT NOT NULL,
        mangaImageUrl TEXT NOT NULL,
        addedAt TEXT NOT NULL,
        FOREIGN KEY (userId) REFERENCES $_tableName (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_historyTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        mangaSlug TEXT NOT NULL,
        mangaTitle TEXT NOT NULL,
        mangaImageUrl TEXT NOT NULL,
        chapterSlug TEXT NOT NULL,
        chapterTitle TEXT NOT NULL,
        readAt TEXT NOT NULL,
        FOREIGN KEY (userId) REFERENCES $_tableName (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_chaptersTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        comicId TEXT NOT NULL,
        chapterTitle TEXT NOT NULL,
        chapterSlug TEXT NOT NULL,
        pdfFilePath TEXT,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  // Upgrade database
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $_favoritesTable (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          userId INTEGER NOT NULL,
          mangaSlug TEXT NOT NULL,
          mangaTitle TEXT NOT NULL,
          mangaImageUrl TEXT NOT NULL,
          addedAt TEXT NOT NULL,
          FOREIGN KEY (userId) REFERENCES $_tableName (id)
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS $_historyTable (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          userId INTEGER NOT NULL,
          mangaSlug TEXT NOT NULL,
          mangaTitle TEXT NOT NULL,
          mangaImageUrl TEXT NOT NULL,
          chapterSlug TEXT NOT NULL,
          chapterTitle TEXT NOT NULL,
          readAt TEXT NOT NULL,
          FOREIGN KEY (userId) REFERENCES $_tableName (id)
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('''
      CREATE TABLE IF NOT EXISTS $_chaptersTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        comicId TEXT NOT NULL,
        chapterTitle TEXT NOT NULL,
        chapterSlug TEXT NOT NULL,
        pdfFilePath TEXT,
        createdAt TEXT NOT NULL
      )
    ''');
    }
  }


  // --- Versi Lama (Masih Bisa Dipakai Jika Butuh) ---
  Future<int> insert(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert(_tableName, row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getUserMapByEmail(String email) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'email = ?',
      whereArgs: [email],
    );
    if (maps.isNotEmpty) return maps.first;
    return null;
  }

  // --- 🔥 Versi Baru untuk AuthService ---
  Future<int> insertUser(UserModel user) async {
    final db = await database;
    return await db.insert(_tableName, user.toMap());
  }

  Future<UserModel?> getUserByEmail(String email) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'email = ?',
      whereArgs: [email],
    );

    if (maps.isNotEmpty) {
      return UserModel.fromMap(maps.first);
    }
    return null;
  }

  // --- Favorites methods ---
  Future<int> insertFavorite(Map<String, dynamic> favorite) async {
    final db = await database;
    return await db.insert(_favoritesTable, favorite, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<List<Map<String, dynamic>>> getFavoritesByUserId(int userId) async {
    final db = await database;
    return await db.query(
      _favoritesTable,
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'addedAt DESC',
    );
  }

  Future<int> deleteFavorite(int userId, String mangaSlug) async {
    final db = await database;
    return await db.delete(
      _favoritesTable,
      where: 'userId = ? AND mangaSlug = ?',
      whereArgs: [userId, mangaSlug],
    );
  }

  // --- History methods ---
  Future<int> insertHistory(Map<String, dynamic> history) async {
    final db = await database;
    return await db.insert(_historyTable, history, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getHistoryByUserId(int userId) async {
    final db = await database;
    return await db.query(
      _historyTable,
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'readAt DESC',
    );
  }

  Future<int> deleteHistory(int userId) async {
    final db = await database;
    return await db.delete(
      _historyTable,
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }

  // --- Chapter methods ---
  Future<int> insertChapter(Map<String, dynamic> chapter) async {
    final db = await database;
    return await db.insert(_chaptersTable, chapter, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateChapter(int id, Map<String, dynamic> chapter) async {
    final db = await database;
    return await db.update(
      _chaptersTable,
      chapter,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteChapter(int id) async {
    final db = await database;
    return await db.delete(
      _chaptersTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getChaptersByComicId(String comicId) async {
    final db = await database;
    return await db.query(
      _chaptersTable,
      where: 'comicId = ?',
      whereArgs: [comicId],
      orderBy: 'createdAt DESC',
    );
  }
}
