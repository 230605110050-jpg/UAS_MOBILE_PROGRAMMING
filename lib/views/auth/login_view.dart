import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/local/auth_service_local.dart';
import '../core/main_wrapper.dart';
import 'register_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final AuthService _authService = AuthService();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool rememberMe = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // PERBAIKAN UTAMA: Menggunakan Future.delayed
    // Memberi jeda 500ms agar Overlay widget benar-benar siap sebelum cek login.
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _checkSavedLogin();
      }
    });
  }

  // --- Fungsi Remember Me ---

  Future<void> _checkSavedLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('remembered_email');
    final savedPassword = prefs.getString('remembered_password');
    final isRemembered = prefs.getBool('rememberMe') ?? false;

    if (isRemembered && savedEmail != null && savedPassword != null) {
      if (!mounted) return;
      emailController.text = savedEmail;
      passwordController.text = savedPassword;
      setState(() {
        rememberMe = true;
      });
      // Coba otomatis login
      _handleLogin(autoLogin: true);
    }
  }

  Future<void> _saveLoginData(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('remembered_email', email);
    await prefs.setString('remembered_password', password);
    await prefs.setBool('rememberMe', rememberMe);
  }

  Future<void> _clearLoginData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('remembered_email');
    await prefs.remove('remembered_password');
    await prefs.setBool('rememberMe', false);
  }

  // --- Fungsi Login Utama ---
  void _handleLogin({bool autoLogin = false}) async {
    // Validasi hanya jika bukan auto login
    if (autoLogin || (_formKey.currentState?.validate() ?? false)) {
      if (mounted) setState(() => _isLoading = true);

      try {
        await _authService.signIn(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        if (rememberMe) {
          await _saveLoginData(
            emailController.text.trim(),
            passwordController.text.trim(),
          );
        } else {
          await _clearLoginData();
        }

        // Navigasi ke MainWrapper
        Get.offAll(() => const MainWrapper());

        // PERBAIKAN PENTING:
        // JANGAN tampilkan snackbar jika Auto Login.
        // Ini mencegah error "No Overlay" saat startup.
        if (!autoLogin) {
          // Gunakan addPostFrameCallback untuk memastikan Overlay siap
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Get.snackbar(
                '✅ Login Sukses',
                'Selamat datang kembali!',
                snackPosition: SnackPosition.TOP,
                backgroundColor: Colors.green,
                colorText: Colors.white,
              );
            }
          });
        }
      } catch (e) {
        // Jika error saat manual login, tampilkan snackbar.
        // Jika error saat auto login, diam saja (biarkan user login manual)
        if (!autoLogin) {
          // Tambahkan delay kecil untuk memastikan Overlay siap
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              Get.snackbar(
                '❌ Error Login',
                e.toString().replaceFirst('Exception: ', ''),
                snackPosition: SnackPosition.TOP,
                backgroundColor: Colors.red,
                colorText: Colors.white,
              );
            }
          });
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _navigateToRegister() {
    Get.to(() => const RegisterView());
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFECFDF5), Colors.white, Color(0xFFE6FFFA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
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
                        Container(
                          height: 64,
                          width: 64,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                              colors: [Colors.green, Colors.teal],
                            ),
                          ),
                          child: const Icon(Icons.menu_book,
                              color: Colors.white, size: 32),
                        ),
                        const SizedBox(height: 16),
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Colors.green, Colors.teal],
                          ).createShader(bounds),
                          child: const Text(
                            "Selamat Datang Kembali",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Masuk untuk melanjutkan petualangan komik Anda",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: "Email",
                            prefixIcon: const Icon(Icons.mail_outline,
                                color: Colors.teal),
                            hintText: "nama@example.com",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null ||
                                value.isEmpty ||
                                !value.contains('@')) {
                              return 'Masukkan email yang valid';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: "Password",
                            prefixIcon: const Icon(Icons.lock_outline,
                                color: Colors.teal),
                            hintText: "••••••••",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.length < 6) {
                              return 'Password minimal 6 karakter';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Checkbox(
                                  value: rememberMe,
                                  activeColor: Colors.teal,
                                  onChanged: (val) {
                                    setState(() => rememberMe = val!);
                                  },
                                ),
                                const Text("Ingat saya"),
                              ],
                            ),
                            TextButton(
                              onPressed: () {
                                Get.snackbar(
                                    'Fitur Belum Tersedia',
                                    'Fitur Lupa Password sedang dalam pengembangan.',
                                    snackPosition: SnackPosition.TOP,
                                    backgroundColor: Colors.orange,
                                    colorText: Colors.white);
                              },
                              child: const Text(
                                "Lupa password?",
                                style: TextStyle(color: Colors.teal),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 8),
                        _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.teal)
                            : ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal,
                                  minimumSize: const Size.fromHeight(48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: _handleLogin,
                                child: const Text("Masuk",
                                    style: TextStyle(fontSize: 16)),
                              ),
                        const SizedBox(height: 24),
                        GestureDetector(
                          onTap: _navigateToRegister,
                          child: const Text.rich(
                            TextSpan(
                              text: "Belum punya akun? ",
                              style: TextStyle(color: Colors.grey),
                              children: [
                                TextSpan(
                                  text: "Daftar sekarang",
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
      ),
    );
  }
}