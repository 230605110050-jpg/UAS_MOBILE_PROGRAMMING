// lib/services/local/auth_service_local.dart

import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_model.dart';
import 'db_helper.dart';

class AuthService {
  // Menggunakan instance Singleton dari DbHelper
  final DbHelper _db = DbHelper.instance; 
  // Menggunakan FlutterSecureStorage untuk menyimpan ID sesi secara aman
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  static const String _loggedUserSharedPreferencesKey = 'logged_user_session';
  static const String _secureStorageUserIdKey = 'userId';


  // Generate random salt (hex)
  String _generateSalt([int length = 16]) {
    final rand = Random.secure();
    final bytes = List<int>.generate(length, (_) => rand.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  // Hash password with salt using SHA-256
  String _hashPassword(String password, String salt) {
    // Menggunakan salt + password sebelum hashing
    final bytes = utf8.encode(salt + password); 
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  // --- SESSION MANAGEMENT ---

  // Simpan data user ke SharedPreferences (untuk akses cepat di UI)
  Future<void> _saveUserToPrefs(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _loggedUserSharedPreferencesKey,
      jsonEncode({
        'id': user.id,
        'fullName': user.fullName,
        'email': user.email,
        'role': user.role,
        'createdAt': user.createdAt,
      }),
    );
  }

  // Hapus semua data sesi (Secure Storage & SharedPreferences)
  Future<void> signOut() async {
    await _secureStorage.delete(key: _secureStorageUserIdKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_loggedUserSharedPreferencesKey);
  }

  // Ambil data user dari SharedPreferences (digunakan oleh MainWrapper/AccountView)
  Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_loggedUserSharedPreferencesKey);
    if (userJson == null || userJson.isEmpty) return null;
    return jsonDecode(userJson);
  }
  
  // Alias agar kompatibel dengan kode lama
  Future<Map<String, dynamic>?> getUserData() async => await getCurrentUser();
  Future<void> logout() async => await signOut();

  // Get current user ID
  Future<int?> getCurrentUserId() async {
    final userData = await getCurrentUser();
    return userData?['id'];
  }


  // --- OTENTIKASI UTAMA ---

  // Register: Menyimpan ke SQLite dan memulai sesi
  Future<UserModel> register({
    required String fullName, 
    required String email, 
    required String password, 
    required String role
  }) async {
    // 1. Cek apakah email sudah terdaftar
    final existing = await _db.getUserByEmail(email);
    if (existing != null) {
      throw Exception('Email sudah terdaftar.');
    }

    // 2. Hash Password
    final salt = _generateSalt();
    final hash = _hashPassword(password, salt);
    final now = DateTime.now().toIso8601String();
    
    // 3. Buat dan simpan Model ke SQLite
    final userToInsert = UserModel(
      fullName: fullName,
      email: email,
      passwordHash: hash,
      salt: salt,
      role: role,
      createdAt: now,
    );
    final id = await _db.insertUser(userToInsert); // Simpan ke DB

    // 4. Buat objek User yang lengkap dengan ID
    final registeredUser = userToInsert.copyWith(id: id);
    
    // 5. Simpan sesi login
    await _secureStorage.write(key: _secureStorageUserIdKey, value: id.toString());
    await _saveUserToPrefs(registeredUser);

    return registeredUser;
  }


  // Login: Memverifikasi user dari SQLite dan memulai sesi
  Future<UserModel> signIn({
    required String email, 
    required String password
  }) async {
    // 1. Ambil user dari SQLite
    final user = await _db.getUserByEmail(email);
    if (user == null) {
      throw Exception('Email atau password salah.');
    }
    
    // 2. Verifikasi Password
    final attemptedHash = _hashPassword(password, user.salt);
    if (attemptedHash != user.passwordHash) {
      throw Exception('Email atau password salah.');
    }
    
    // 3. Simpan sesi login
    if (user.id == null) {
        throw Exception('User data tidak lengkap (ID hilang).');
    }
    await _secureStorage.write(key: _secureStorageUserIdKey, value: user.id.toString());
    await _saveUserToPrefs(user);

    return user;
  }
}

// Extension untuk membuat salinan UserModel dengan ID baru
extension UserModelCopy on UserModel {
  UserModel copyWith({
    int? id,
    String? fullName,
    String? email,
    String? passwordHash,
    String? salt,
    String? role,
    String? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      salt: salt ?? this.salt,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
