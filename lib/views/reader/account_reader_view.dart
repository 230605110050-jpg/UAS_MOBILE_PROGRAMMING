import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/local/auth_service_local.dart';
import '../../services/local/favorites_service.dart';

class AccountReaderView extends StatefulWidget {
  const AccountReaderView({super.key});

  @override
  State<AccountReaderView> createState() => _AccountReaderViewState();
}

class _AccountReaderViewState extends State<AccountReaderView> {
  final AuthService _authService = AuthService();
  final FavoritesService _favoritesService = FavoritesService();

  Map<String, dynamic>? userData;
  bool isLoading = true;
  bool editMode = false;
  bool notifications = true;
  bool emailUpdates = true;

  List<Map<String, dynamic>> _favorites = [];

  late TextEditingController nameController;
  late TextEditingController bioController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    bioController = TextEditingController();
    _loadUser();
    _loadFavorites();

  }

  // Menggunakan fullName karena field yang disimpan di AuthService adalah fullName
  Future<void> _loadUser() async {
    final user = await _authService.getUserData();
    setState(() {
      userData = user;
      // Gunakan 'fullName' untuk display
      nameController.text = user?['fullName'] ?? '';
      bioController.text = user?['bio'] ?? '';
      isLoading = false;
    });
  }

  // Fungsi untuk menyimpan perubahan profil (hanya update sesi di SharedPreferences)
  Future<void> _saveProfile() async {
    if (userData == null) return;

    // Ambil prefs
    final prefs = await SharedPreferences.getInstance();

    // Update data di memory
    userData!['fullName'] = nameController.text.trim();
    userData!['bio'] = bioController.text.trim();

    // Simpan data sesi yang diupdate kembali ke SharedPreferences
    // Key: 'logged_user_session' adalah key yang digunakan di AuthService
    await prefs.setString(
      'logged_user_session',
      jsonEncode(userData),
    );

    setState(() => editMode = false);

    Get.snackbar(
      'Sukses',
      'Profil berhasil diperbarui.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.teal.shade500,
      colorText: Colors.white,
    );
  }

  // Fungsi untuk Logout
  Future<void> _handleLogout() async {
    await _authService.signOut();
    // Navigasi ke InitialDeciderView (yang akan mengarahkan ke LoginView)
    Get.offAllNamed('/');
  }

  Future<void> _loadFavorites() async {
    final userId = await _authService.getCurrentUserId();
    if (userId != null) {
      final favorites = await _favoritesService.getUserFavorites(userId);
      setState(() {
        _favorites = favorites;
      });
    }
  }



  @override
  void dispose() {
    nameController.dispose();
    bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.teal));
    }

    final user = userData;
    // Scaffold tanpa AppBar (disediakan oleh MainWrapper)
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileCard(user),
              const SizedBox(height: 16),
              _buildFavoritesCard(),
              const SizedBox(height: 16),
              _buildSettingsCard(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // Widget Profile Card
  Widget _buildProfileCard(Map<String, dynamic>? user) {
    // Ambil inisial dari fullName
    String initial = (user?['fullName']?.isNotEmpty ?? false)
        ? user!['fullName'][0].toUpperCase()
        : "?";

    String nameToDisplay = user?['fullName'] ?? "Pengguna";

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.teal.shade100, // Ganti warna ke tema Teal
              child: Text(
                initial,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade700, // Ganti warna ke tema Teal
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: editMode
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Input Nama Pengguna (fullName)
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: "Nama Lengkap",
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Input Bio
                        TextField(
                          controller: bioController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: "Bio",
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Tombol Simpan
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                // Batalkan Edit Mode dan reset controller
                                nameController.text = user?['fullName'] ?? '';
                                bioController.text = user?['bio'] ?? '';
                                setState(() => editMode = false);
                              },
                              child: const Text("Batal", style: TextStyle(color: Colors.grey)),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: _saveProfile,
                              icon: const Icon(Icons.save, size: 18),
                              label: const Text("Simpan"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal, // Ganti warna
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Display Nama Lengkap
                        Text(
                          nameToDisplay,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        // Display Email
                        Text(
                          user?['email'] ?? "Email tidak tersedia",
                          style: const TextStyle(color: Colors.grey),
                        ),
                        // Display Role
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: user?['role'] == 'author' ? Colors.orange.shade100 : Colors.green.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            user?['role']?.toUpperCase() ?? 'READER',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: user?['role'] == 'author' ? Colors.orange.shade700 : Colors.green.shade700,
                            ),
                          ),
                        ),
                        // Display Bio
                        if (user?['bio'] != null &&
                            (user!['bio'] as String).isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(user['bio']),
                          ),
                        const SizedBox(height: 12),
                        // Tombol Edit
                        OutlinedButton.icon(
                          onPressed: () => setState(() => editMode = true),
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text("Edit Profil"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.teal,
                            side: const BorderSide(color: Colors.teal),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget Favorites Card
  Widget _buildFavoritesCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                child: Text(
                  "Komik Favorit",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
            const Divider(),
            if (_favorites.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("Belum ada komik favorit", style: TextStyle(color: Colors.grey)),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _favorites.length,
                itemBuilder: (context, index) {
                  final fav = _favorites[index];
                  return ListTile(
                    leading: Image.network(
                      fav['mangaImageUrl'] ?? '',
                      width: 40,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
                    ),
                    title: Text(fav['mangaTitle'] ?? 'Unknown'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        final userId = await _authService.getCurrentUserId();
                        if (userId != null) {
                          await _favoritesService.removeFromFavorites(userId, fav['mangaSlug']);
                          _loadFavorites();
                        }
                      },
                    ),
                    onTap: () {
                      // Navigate to detail view
                      Get.toNamed('/detail', arguments: {'slug': fav['mangaSlug']});
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }



  // Widget Settings Card
  Widget _buildSettingsCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                child: Text(
                  "Pengaturan Aplikasi",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
            const Divider(),
            _settingTile(
              title: "Notifikasi Push",
              value: notifications,
              onChanged: (v) => setState(() => notifications = v),
              icon: Icons.notifications_none,
            ),
            _settingTile(
              title: "Email Updates",
              value: emailUpdates,
              onChanged: (v) => setState(() => emailUpdates = v),
              icon: Icons.email_outlined,
            ),
            const Divider(),
            // Tombol Logout
            ListTile(
              title: const Text("Logout"),
              leading: const Icon(Icons.logout, color: Colors.red),
              onTap: _handleLogout,
              trailing: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }

  // Helper untuk SwitchListTile
  Widget _settingTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return SwitchListTile(
      title: Text(title),
      value: value,
      secondary: Icon(icon, color: Colors.teal),
      activeThumbColor: Colors.teal,
      onChanged: onChanged,
    );
  }
}
