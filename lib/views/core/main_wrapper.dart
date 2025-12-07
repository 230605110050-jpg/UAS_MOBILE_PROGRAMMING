import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart'; 
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/local/auth_service_local.dart';
import '../auth/login_view.dart';
import '../auth/register_view.dart';
import '../manga/home_view.dart';
import '../manga/list_view.dart';
import '../reader/account_reader_view.dart';
import '../author/account_author_view.dart';
import '../author/author_setting_view.dart';
import 'placeholder_view.dart';
// Import InitialDeciderView

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  // State untuk melacak halaman yang sedang aktif
  String currentPage = 'home';
  
  // State untuk menyimpan data user yang sedang login
  Map<String, dynamic>? currentUser; 
  final AuthService _authService = AuthService();
  
  // =======================================================
  // --- MOCK STATE MANAGEMENT (untuk Author CRUD) ---
  // Mock data ini disimpan di sini karena kita tidak menggunakan database untuk data komik
  final List<Map<String, dynamic>> _authorComics = [
    // Data dummy agar Author Dashboard ada isinya
    {'id': 'a1', 'title': 'The Code Master', 'authorId': '123', 'status': 'ongoing', 'genre': ['Sci-Fi', 'Action'], 'rating': 4.5, 'totalViews': 55000, 'coverImage': 'https://placehold.co/80x120/0E7490/FFFFFF?text=CM'},
    {'id': 'a2', 'title': 'Flutter Journey', 'authorId': '123', 'status': 'completed', 'genre': ['Comedy', 'Slice of Life'], 'rating': 4.8, 'totalViews': 120000, 'coverImage': 'https://placehold.co/80x120/047857/FFFFFF?text=FJ'},
  ];

  void _createComic(Map<String, dynamic> newComic) {
    setState(() {
      _authorComics.add(newComic);
    });
  }

  void _updateComic(String id, Map<String, dynamic> updatedData) {
    setState(() {
      final index = _authorComics.indexWhere((comic) => comic['id'] == id);
      if (index != -1) {
        _authorComics[index] = {
          ..._authorComics[index], 
          ...updatedData, 
        };
      }
    });
  }

  void _deleteComic(String id) {
    setState(() {
      _authorComics.removeWhere((comic) => comic['id'] == id);
    });
  }
  // =======================================================

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  // Fungsi untuk memuat data pengguna dari AuthService
  Future<void> _loadCurrentUser() async {
    final user = await _authService.getCurrentUser();
    if (mounted) {
      setState(() {
        currentUser = user;
        _initializePages(); // Panggil inisialisasi di sini SETELAH user dimuat
        
        // Atur halaman default jika user adalah author
        if (currentUser?['role'] == 'author' && currentPage == 'home') {
          currentPage = 'author-dashboard';
        }
      });
    }
  }

  void _initializePages() {
    // Placeholder method to fix error
    // You can implement page initialization logic here if needed
  }

  void navigateTo(String page) {
    setState(() {
      currentPage = page;
    });
  }

  // Fungsi Logout yang terintegrasi dengan AuthService
  Future<void> logout() async {
    try {
      // 1. Hapus sesi di SharedPreferences (AuthService)
      await _authService.signOut();
      
      // 2. Hapus data 'remember me' di SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('remembered_email');
      await prefs.remove('remembered_password');
      await prefs.setBool('rememberMe', false);

      if (!mounted) return;
      
      setState(() {
        currentUser = null;
      });

      // 3. Navigasi kembali ke LoginView
      Get.offAll(() => const LoginView());

      // Tambahkan delay kecil untuk memastikan Overlay siap
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          Get.snackbar(
            '👋 Sampai Jumpa',
            'Anda telah berhasil keluar.',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.teal,
            colorText: Colors.white,
          );
        }
      });
      
    } catch (e) {
      Get.snackbar(
        '❌ Error Logout',
        e.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tampilkan loading screen sampai data user dimuat
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.teal)),
        backgroundColor: Colors.white,
      );
    }

    // Inisialisasi pages setelah user dimuat
    final currentAuthorId = currentUser?['id']?.toString() ?? '123';
    final pages = {
      'home': const HomeView(),
      'comics': const KomikListView(),
      'login': const LoginView(),
      'register': const RegisterView(),

      'account': const AccountReaderView(),
      'author-settings': const AuthorSettingView(),

      'author-dashboard': AccountAuthorView(
        authorId: currentAuthorId,
        comics: _authorComics,
        onCreateComic: _createComic,
        onUpdateComic: _updateComic,
        onDeleteComic: _deleteComic,
      ),
    };

    return Scaffold(
      // Navbar dikelola di sini
      appBar: Navbar(
        currentUser: currentUser,
        currentPage: currentPage,
        onNavigate: (page) {
          if (page == 'logout') {
            logout();
          } else if (page == 'detail' || page == 'reader') {
            // Detail & Reader akan di-handle dengan Get.to() di halaman lain
          } else {
            navigateTo(page);
          }
        },
        onLogout: logout,
      ),
      // Tampilkan halaman yang aktif
      body: pages[currentPage] ?? const PlaceholderView(title: 'Page not found'),
    );
  }
}


/// ===================================================================
/// 🔹 CLASS NAVBAR (Dipisahkan agar lebih rapi)
/// ===================================================================

class Navbar extends StatelessWidget implements PreferredSizeWidget {
  final Map<String, dynamic>? currentUser;
  final String currentPage;
  final Function(String page) onNavigate;
  final VoidCallback? onLogout;

  const Navbar({
    super.key,
    required this.currentUser,
    required this.currentPage,
    required this.onNavigate,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 2,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            // Logo
            GestureDetector(
              onTap: () => onNavigate(
                currentUser?['role'] == 'author' ? 'author-dashboard' : 'home',
              ),
              child: Row(
                children: [
                  Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: const LinearGradient(
                        colors: [Colors.green, Colors.teal],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Icon(
                      CupertinoIcons.book_fill,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Colors.green, Colors.teal],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ).createShader(bounds),
                    child: const Text(
                      "KomikKu",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Navigasi
            if (currentUser != null)
              Row(
                children: [
                  if (currentUser?['role'] == 'reader') ...[
                    _navButton('Beranda', Icons.home_outlined, currentPage == 'home', () => onNavigate('home')),
                    _navButton('Daftar Komik', Icons.library_books_outlined, currentPage == 'comics', () => onNavigate('comics')),
                  ],
                  if (currentUser?['role'] == 'author')
                    _navButton('Dashboard', Icons.dashboard_outlined, currentPage == 'author-dashboard', () => onNavigate('author-dashboard')),
                ],
              ),
            const SizedBox(width: 12),
            if (currentUser != null) _userMenu(context) else Row(
              children: [
                TextButton(
                  onPressed: () => Get.offAll(() => const LoginView()), // Navigasi ke Login
                  child: const Text('Masuk', style: TextStyle(color: Colors.teal)),
                ),
                const SizedBox(width: 4),
                ElevatedButton(
                  onPressed: () => Get.offAll(() => const RegisterView()), // Navigasi ke Register
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Daftar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _navButton(String label, IconData icon, bool active, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: active ? Colors.teal : Colors.grey[700]),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 14, color: active ? Colors.teal : Colors.grey[700], fontWeight: active ? FontWeight.w600 : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  Widget _userMenu(BuildContext context) {
    final isAuthor = currentUser?['role'] == 'author';
    return PopupMenuButton<String>(
      tooltip: 'Menu Akun',
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      offset: const Offset(0, 50),
      icon: CircleAvatar(
        backgroundColor: Colors.teal.shade100,
        foregroundColor: Colors.teal.shade700,
        // Menggunakan 'fullName' untuk inisial
        child: Text((currentUser?['fullName']?.isNotEmpty ?? false) ? currentUser!['fullName'][0].toUpperCase() : '?', style: const TextStyle(fontWeight: FontWeight.bold)), 
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            // Menggunakan 'fullName' yang disimpan di AuthService
            title: Text(currentUser?['fullName'] ?? 'Pengguna', style: const TextStyle(fontWeight: FontWeight.w600)), 
            subtitle: Text(currentUser?['email'] ?? '', style: const TextStyle(fontSize: 12)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(10)),
              child: Text(isAuthor ? 'Author' : 'Pembaca', style: TextStyle(color: Colors.teal.shade700, fontSize: 11)),
            ),
          ),
        ),
        const PopupMenuDivider(),
        if (isAuthor) ...[
          _popupItem(Icons.dashboard, 'Dashboard', 'author-dashboard'),
          _popupItem(Icons.person, 'Informasi Akun', 'author-settings'),
          _popupItem(Icons.edit, 'Edit Profil', 'author-settings'),
        ] else ...[
          _popupItem(Icons.person, 'Informasi Akun', 'account'), 
          _popupItem(Icons.edit, 'Edit Profil', 'account'),
          const PopupMenuDivider(),
          _popupItem(Icons.favorite, 'Komik Favorit', 'account'),
          _popupItem(Icons.history, 'Riwayat Baca', 'account'),
        ],
        const PopupMenuDivider(),
        _popupItem(Icons.settings, 'Pengaturan', isAuthor ? 'author-settings' : 'account'),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'logout',
          onTap: onLogout,
          child: const Row(
            children: [Icon(Icons.logout, color: Colors.red), SizedBox(width: 8), Text('Keluar', style: TextStyle(color: Colors.red))],
          ),
        ),
      ],
      onSelected: (String page) {
        if (page != 'logout') {
          onNavigate(page);
        }
      },
    );
  }

  PopupMenuItem<String> _popupItem(IconData icon, String label, String route) {
    return PopupMenuItem<String>(
      value: route,
      child: Row(
        children: [Icon(icon, color: Colors.teal, size: 18), const SizedBox(width: 8), Text(label)],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(60);
}