// lib/views/auth/register_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/local/auth_service_local.dart'; // Panggil AuthService yang sudah terhubung ke SQLite
import '../core/main_wrapper.dart'; // Navigasi ke Home setelah daftar/login

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  // Controller Input
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  final AuthService _authService = AuthService(); // Instance service
  
  // State UI
  String _selectedRole = 'reader'; // Role default
  bool _isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  // --- Fungsi Validasi (Diambil dari kode Login lama) ---
  String? _validateEmail(String? v) {
    if (v == null || v.isEmpty) return 'Email wajib diisi';
    final regex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
    if (!regex.hasMatch(v)) return 'Format email tidak valid';
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.length < 6) return 'Password minimal 6 karakter';
    return null;
  }
  
  String? _validateConfirmPassword(String? v) {
    if (v == null || v.isEmpty) return 'Konfirmasi password wajib diisi';
    if (v != passwordController.text) return 'Password tidak cocok';
    return null;
  }

  // --- FUNGSI REGISTER UTAMA (Menggunakan SQLite AuthService) ---
  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      // Panggil AuthService.register (yang menyimpan data ke SQLite)
      await _authService.register(
        fullName: nameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text,
        role: _selectedRole,
      );

      // Navigasi ke halaman utama setelah register (AuthService akan menyimpan sesi)
      Get.offAll(() => const MainWrapper());

      // Gunakan addPostFrameCallback untuk memastikan Overlay siap
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Get.snackbar(
            '✅ Pendaftaran Sukses',
            'Akun berhasil dibuat! Selamat datang, ${nameController.text.trim()}',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        }
      });
    } catch (e) {
      // Tambahkan delay kecil untuk memastikan Overlay siap
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          Get.snackbar(
            '❌ Error Pendaftaran',
            e.toString().replaceFirst('Exception: ', ''),
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _navigateToLogin() {
    Get.back(); // Kembali ke LoginView yang memanggil halaman ini
  }

  // --- Widget Role Option (Diambil dari kode Komik lama) ---
  Widget _buildRoleOption(
      String value, String title, String subtitle, IconData icon) {
    bool isSelected = _selectedRole == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = value),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.teal : Colors.teal.shade100,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? Colors.teal.shade50 : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_off,
              color: isSelected ? Colors.teal : Colors.grey,
            ),
            const SizedBox(width: 8),
            Icon(icon, color: Colors.teal, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- UI ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFECFDF5), Colors.white, Color(0xFFE6FFFA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Card(
                elevation: 6,
                shadowColor: Colors.teal.shade100,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.teal.shade100),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ... Header UI (Icon, Title, Subtitle) ...
                      Container(
                        height: 64, width: 64,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            colors: [Colors.green, Colors.teal],
                          ),
                        ),
                        child: const Icon(Icons.menu_book, color: Colors.white, size: 32),
                      ),
                      const SizedBox(height: 16),
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                                colors: [Colors.green, Colors.teal])
                            .createShader(bounds),
                        child: const Text("Buat Akun Baru",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Bergabunglah dengan komunitas pecinta komik",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 24),

                      // Nama Lengkap
                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: "Nama Lengkap",
                          prefixIcon: const Icon(Icons.person_outline, color: Colors.teal),
                          hintText: "Masukkan nama lengkap",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) => value!.isEmpty ? 'Nama tidak boleh kosong' : null,
                      ),
                      const SizedBox(height: 16),

                      // Email
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: "Email",
                          prefixIcon: const Icon(Icons.mail_outline, color: Colors.teal),
                          hintText: "nama@example.com",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: 16),

                      // Password
                      TextFormField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: "Password (Min 6 Karakter)",
                          prefixIcon: const Icon(Icons.lock_outline, color: Colors.teal),
                          hintText: "••••••••",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: _validatePassword,
                      ),
                      const SizedBox(height: 16),

                      // Konfirmasi Password
                      TextFormField(
                        controller: confirmController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: "Konfirmasi Password",
                          prefixIcon: const Icon(Icons.lock_outline, color: Colors.teal),
                          hintText: "••••••••",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: _validateConfirmPassword,
                      ),
                      const SizedBox(height: 24),

                      // Pilihan Role
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Daftar Sebagai",
                          style: TextStyle(
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Column(
                        children: [
                          _buildRoleOption(
                            'reader',
                            'Pembaca',
                            'Baca dan nikmati komik favorit',
                            Icons.menu_book,
                          ),
                          const SizedBox(height: 8),
                          _buildRoleOption(
                            'author',
                            'Author',
                            'Buat dan publikasikan komik',
                            Icons.auto_awesome,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Tombol
                      _isLoading
                          ? const CircularProgressIndicator(color: Colors.teal)
                          : ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                minimumSize: const Size.fromHeight(48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                foregroundColor: Colors.white,
                              ),
                              onPressed: _submit,
                              child: const Text("Daftar Sekarang",
                                  style: TextStyle(fontSize: 16)),
                            ),
                      const SizedBox(height: 24),

                      // Login Link
                      GestureDetector(
                        onTap: _navigateToLogin,
                        child: const Text.rich(
                          TextSpan(
                            text: "Sudah punya akun? ",
                            style: TextStyle(color: Colors.grey),
                            children: [
                              TextSpan(
                                text: "Masuk di sini",
                                style: TextStyle(
                                  color: Colors.teal,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}