import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;


import 'services/local/auth_service_local.dart';
import 'views/auth/login_view.dart';
import 'views/core/main_wrapper.dart'; // Halaman utama aplikasi komik

void main() async {
  // Pastikan binding Flutter diinisialisasi sebelum async code
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi databaseFactory untuk desktop
  // Hanya diperlukan untuk Windows, Linux, dan MacOS
  if (!kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.windows ||
     defaultTargetPlatform == TargetPlatform.linux ||
     defaultTargetPlatform == TargetPlatform.macOS)) {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}


  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Komik Reader - Auth Integrated',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: Colors.grey[100],
        useMaterial3: false,
      ),
      // Halaman awal: cek sesi login
      home: const InitialDeciderView(),
    );
  }
}

/// Widget penentu tampilan awal: Login atau Home
/// Menentukan apakah user sudah login atau belum.
class InitialDeciderView extends StatefulWidget {
  const InitialDeciderView({super.key});

  @override
  State<InitialDeciderView> createState() => _InitialDeciderViewState();
}

class _InitialDeciderViewState extends State<InitialDeciderView> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  /// Mengecek apakah user masih punya sesi aktif
  Future<void> _checkAuthStatus() async {
    // Beri sedikit delay biar terasa ada proses "loading"
    await Future.delayed(const Duration(milliseconds: 600));

    final user = await _authService.getCurrentUser();

    if (!mounted) return;

    if (user != null) {
      // Jika user sudah login → masuk ke dashboard
      Get.offAll(() => const MainWrapper());
    } else {
      // Jika belum login → ke halaman login
      Get.offAll(() => const LoginView());
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.teal),
            SizedBox(height: 16),
            Text(
              'Memeriksa sesi pengguna...',
              style: TextStyle(color: Colors.teal),
            ),
          ],
        ),
      ),
    );
  }
}
