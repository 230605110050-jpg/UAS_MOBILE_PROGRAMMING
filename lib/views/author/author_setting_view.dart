import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/local/auth_service_local.dart';

class AuthorSettingView extends StatefulWidget {
  const AuthorSettingView({super.key});

  @override
  State<AuthorSettingView> createState() => _AuthorSettingViewState();
}

class _AuthorSettingViewState extends State<AuthorSettingView>
    with SingleTickerProviderStateMixin { // Wajib untuk TabController
  
  final AuthService _authService = AuthService();
  Map<String, dynamic>? userData;
  bool isLoading = true;

  // State UI
  late TabController _tabController;
  bool editMode = false;
  
  // Settings State (Mock)
  bool notifications = true;
  bool emailUpdates = true;
  bool publicProfile = true;
  bool commentNotifications = true;

  // Controllers (menggunakan fullName karena UserModel kita menggunakan fullName)
  late TextEditingController nameController; 
  late TextEditingController bioController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    nameController = TextEditingController();
    bioController = TextEditingController();
    _loadUser(); // Muat data pengguna saat inisialisasi
  }

  // --- LOGIC: Memuat dan Menyimpan Profil ---

  Future<void> _loadUser() async {
    final user = await _authService.getUserData();
    if (!mounted) return;

    setState(() {
      userData = user;
      // Bind controller ke data sesi (menggunakan fullName)
      nameController.text = user?['fullName'] ?? ''; 
      bioController.text = user?['bio'] ?? '';
      isLoading = false;
    });
  }

  Future<void> _saveProfile() async {
    if (userData == null) return;
    
    // 1. Update data di memory
    userData!['fullName'] = nameController.text.trim();
    userData!['bio'] = bioController.text.trim(); // Simpan bio jika ada

    // 2. Simpan data sesi yang diupdate kembali ke SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'logged_user_session', 
      jsonEncode(userData),
    );

    setState(() => editMode = false);

    Get.snackbar(
      'Sukses',
      'Profil Author berhasil diperbarui.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.teal.shade500,
      colorText: Colors.white,
    );
  }


  @override
  void dispose() {
    _tabController.dispose();
    nameController.dispose();
    bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.teal));
    }

    final user = userData!; // Kita tahu user tidak null karena sudah melewati loading

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFECFDF5), Colors.white, Color(0xFFE6FFFA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                // Tombol Kembali
                TextButton.icon(
                  onPressed: () => Get.back(), // Menggunakan Get.back() untuk kembali ke Dashboard
                  icon: const Icon(Icons.arrow_back, color: Colors.teal),
                  label: const Text(
                    "Kembali ke Dashboard",
                    style: TextStyle(color: Colors.teal),
                  ),
                ),

                // ---------------- HEADER PROFIL ----------------
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFFCCF0E3)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  elevation: 4,
                  child: Column(
                    children: [
                      Container(
                        height: 100,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.green, Colors.teal],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.teal.shade100, // Ganti warna
                              backgroundImage: user['avatar'] != null
                                  ? NetworkImage(user['avatar'])
                                  : null,
                              child: user['avatar'] == null
                                  ? Text(
                                      user['fullName'][0], // Gunakan fullName
                                      style: const TextStyle(
                                          fontSize: 28,
                                          color: Colors.teal,
                                          fontWeight: FontWeight.bold),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        user['fullName'], // Gunakan fullName
                                        style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                              colors: [
                                                Colors.green,
                                                Colors.teal
                                              ]),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: const Text(
                                          "Author",
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    user['email'],
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                  Text(
                                    "Bergabung ${user['createdAt'].substring(0, 10)}", // Tampilkan tanggal gabung
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ---------------- TAB NAVIGASI ----------------
                TabBar(
                  controller: _tabController,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.teal,
                  indicator: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Colors.green, Colors.teal]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  tabs: const [
                    Tab(text: "Profil", icon: Icon(Icons.person)),
                    Tab(text: "Notifikasi", icon: Icon(Icons.notifications)),
                    Tab(text: "Publikasi", icon: Icon(Icons.menu_book)),
                    Tab(text: "Keamanan", icon: Icon(Icons.shield)),
                  ],
                ),

                const SizedBox(height: 16),

                // ---------------- TAB ISI ----------------
                SizedBox(
                  height: 900, // Ukuran tetap agar TabBarView dapat digulir
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildProfileTab(user), // Kirim data user
                      _buildNotificationTab(),
                      _buildPublishingTab(),
                      _buildSecurityTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============ TAB: PROFIL ============
  Widget _buildProfileTab(Map<String, dynamic> user) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFCCF0E3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Informasi Profil Author",
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.teal)),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              enabled: editMode,
              decoration: const InputDecoration(
                labelText: "Nama Author",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              enabled: false,
              decoration: InputDecoration(
                labelText: "Email",
                border: const OutlineInputBorder(),
                hintText: user['email'],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bioController,
              enabled: editMode,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Bio Author",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text("Tampilkan Profil Publik"),
              subtitle: const Text(
                  "Aktifkan agar profil Anda muncul untuk pembaca"),
              activeThumbColor: Colors.teal,
              value: publicProfile,
              onChanged: (val) => setState(() => publicProfile = val),
            ),
            const SizedBox(height: 12),
            if (editMode)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        // Reset controller ke nilai awal
                        nameController.text = user['fullName'];
                        bioController.text = user['bio'] ?? '';
                        editMode = false;
                      });
                    },
                    child: const Text("Batal"),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _saveProfile, // Panggil fungsi simpan terintegrasi
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Simpan"),
                  ),
                ],
              )
            else
              OutlinedButton.icon(
                onPressed: () => setState(() => editMode = true),
                icon: const Icon(Icons.settings),
                label: const Text("Edit Profil"),
              ),
          ],
        ),
      ),
    );
  }

  // ============ TAB: NOTIFIKASI ============
  Widget _buildNotificationTab() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFCCF0E3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text("Notifikasi Push"),
              subtitle:
                  const Text("Terima notifikasi untuk aktivitas komik Anda"),
              activeThumbColor: Colors.teal,
              value: notifications,
              onChanged: (val) => setState(() => notifications = val),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text("Notifikasi Komentar"),
              subtitle: const Text("Terima notifikasi saat ada komentar baru"),
              activeThumbColor: Colors.teal,
              value: commentNotifications,
              onChanged: (val) => setState(() => commentNotifications = val),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text("Email Updates"),
              subtitle:
                  const Text("Terima email untuk statistik mingguan Anda"),
              activeThumbColor: Colors.teal,
              value: emailUpdates,
              onChanged: (val) => setState(() => emailUpdates = val),
            ),
          ],
        ),
      ),
    );
  }

  // ============ TAB: PUBLIKASI ============
  Widget _buildPublishingTab() {
    // Variabel state lokal harus diinisialisasi di sini jika tidak menggunakan StateBuilder
    // Karena kita tidak menyimpan state ini ke SharedPreferences, kita biarkan saja di sini
    String? visibility = "public"; 
    String? rating = "all"; 

    return ListView(
      // ListView di sini agar konten di dalam tab dapat digulir jika terlalu panjang
      physics: const NeverScrollableScrollPhysics(), 
      children: [
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFCCF0E3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Preferensi Publikasi",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.teal)),
                const SizedBox(height: 12),
                DropdownButtonFormField(
                  initialValue: visibility,
                  decoration: const InputDecoration(
                    labelText: "Visibilitas Default",
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: "public", child: Text("Publik")),
                    DropdownMenuItem(
                        value: "unlisted", child: Text("Tidak Terdaftar")),
                    DropdownMenuItem(
                        value: "private", child: Text("Private")),
                  ],
                  // Perubahan state dilakukan di dalam Tab, tidak perlu disimpan
                  onChanged: (v) => setState(() => visibility = v! as String?),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField(
                  initialValue: rating,
                  decoration: const InputDecoration(
                    labelText: "Rating Konten Default",
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: "all", child: Text("Semua Umur")),
                    DropdownMenuItem(value: "teen", child: Text("Remaja 13+")),
                    DropdownMenuItem(value: "mature", child: Text("Dewasa 18+")),
                  ],
                  onChanged: (v) => setState(() => rating = v! as String?),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.teal.shade200),
                  ),
                  child: const Text(
                    "💰 Fitur monetisasi akan segera tersedia. "
                    "Anda akan dapat menerima donasi dan menjual chapter premium.",
                    style: TextStyle(color: Colors.teal),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  // ============ TAB: KEAMANAN ============
  Widget _buildSecurityTab() {
    return ListView(
      physics: const NeverScrollableScrollPhysics(), // Nonaktifkan scroll
      children: [
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFCCF0E3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.lock_outline),
                  onPressed: () {
                    Get.snackbar('Fitur Belum Tersedia', 'Anda akan diarahkan ke halaman ganti password.', snackPosition: SnackPosition.BOTTOM);
                  },
                  label: const Text("Ubah Password"),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.security),
                  onPressed: () {
                    Get.snackbar('Fitur Belum Tersedia', 'Anda akan diarahkan ke halaman 2FA.', snackPosition: SnackPosition.BOTTOM);
                  },
                  label: const Text("Autentikasi Dua Faktor"),
                ),
                const Divider(),
                const ListTile(
                  title: Text("Sesi Aktif"),
                  subtitle: Text("Kelola perangkat yang login ke akun Anda"),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.teal.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Chrome on Desktop (Perangkat Ini)"),
                          Text("Aktif sekarang",
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.teal.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          "Aktif",
                          style: TextStyle(color: Colors.teal),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Danger Zone
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.redAccent),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text("Zona Berbahaya",
                    style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  onPressed: () {
                    Get.snackbar('Fitur Belum Tersedia', 'Nonaktifkan akun akan segera diimplementasikan.', snackPosition: SnackPosition.BOTTOM);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.redAccent),
                  ),
                  label: const Text("Nonaktifkan Akun Author"),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.delete_forever),
                  onPressed: () {
                    Get.snackbar('Fitur Belum Tersedia', 'Hapus akun permanen akan segera diimplementasikan.', snackPosition: SnackPosition.BOTTOM);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  label: const Text("Hapus Akun & Semua Komik"),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}