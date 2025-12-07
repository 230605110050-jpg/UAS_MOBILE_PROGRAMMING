// lib/models/user_model.dart

class UserModel {
  // ID opsional (karena saat insert ke DB, ID diisi otomatis)
  final int? id;
  final String fullName;
  final String email;

  // Password disimpan sebagai hash dan salt untuk keamanan
  final String passwordHash; 
  final String salt;

  // Role bisa "reader" atau "author"
  final String role;

  // Tanggal pembuatan akun
  final String createdAt;

  UserModel({
    this.id,
    required this.fullName,
    required this.email,
    required this.passwordHash,
    required this.salt,
    required this.role,
    required this.createdAt,
  });

  // 🔁 Konversi dari Model ke Map (untuk disimpan ke SQLite)
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'fullName': fullName,
      'email': email,
      'passwordHash': passwordHash,
      'salt': salt,
      'role': role,
      'createdAt': createdAt,
    };
    if (id != null) map['id'] = id;
    return map;
  }

  // 🔁 Konversi dari Map ke Model (untuk dibaca dari SQLite/SharedPreferences)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] is int
          ? map['id']
          : int.tryParse(map['id']?.toString() ?? ''),
      fullName: map['fullName'] as String? ?? 'Pengguna Baru',
      email: map['email'] as String? ?? '',
      passwordHash: map['passwordHash'] as String? ?? '',
      salt: map['salt'] as String? ?? '',
      role: map['role'] as String? ?? 'reader',
      createdAt: map['createdAt'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  // ✨ Biar bisa bikin salinan (misal untuk menambah ID setelah insert)
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
