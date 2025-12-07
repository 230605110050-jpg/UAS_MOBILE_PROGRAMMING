// ignore_for_file: deprecated_member_use

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/api/manga_api_service.dart';
import '../../models/manga_detail.dart'; // Mengandung ChapterImageResponse
import '../../services/local/auth_service_local.dart';
import '../../services/local/history_service.dart';

class KomikReaderView extends StatefulWidget {
  final String initialChapterUrl;
  final String title;

  const KomikReaderView({
    super.key,
    required this.initialChapterUrl,
    required this.title,
  });

  @override
  State<KomikReaderView> createState() => _KomikReaderViewState();
}

class _KomikReaderViewState extends State<KomikReaderView> {
  final MangaApiService _apiService = MangaApiService();
  final AuthService _authService = AuthService();
  final HistoryService _historyService = HistoryService();

  late String _currentChapterUrl;

  late Future<ChapterImageResponse> _imageFuture;

  // Menggunakan ScrollController untuk menggulir ke atas saat chapter baru dimuat
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _currentChapterUrl = widget.initialChapterUrl;
    _imageFuture = _fetchImages(_currentChapterUrl);
    _addToHistory();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // --- Fungsi untuk memuat gambar chapter (dan navigasi slugs) ---
  Future<ChapterImageResponse> _fetchImages(String chapterUrl) async {
    return await _apiService.fetchChapterImages(chapterUrl);
  }

  // --- Fungsi untuk menambah ke history ---
  Future<void> _addToHistory() async {
    final userId = await _authService.getCurrentUserId();
    if (userId == null) return; // Tidak ada user login, skip

    try {
      // Extract manga slug dari chapter URL
      final parts = _currentChapterUrl.split('/');
      if (parts.length < 2) return;
      final mangaSlug = parts[0];

      // Fetch manga detail untuk mendapatkan title dan image
      final mangaDetail = await _apiService.fetchMangaDetail(mangaSlug);

      // Cari chapter title dari chapters list
      final chapter = mangaDetail.chapters.firstWhere(
        (ch) => ch.url == _currentChapterUrl,
        orElse: () => MangaChapter(
          chapter: 'Unknown Chapter',
          url: _currentChapterUrl,
          update: DateTime.now().toString(),
        ),
      );

      // Add to history
      await _historyService.addToHistory(
        userId: userId,
        mangaSlug: mangaSlug,
        mangaTitle: mangaDetail.title,
        mangaImageUrl: mangaDetail.imageUrl,
        chapterSlug: _currentChapterUrl,
        chapterTitle: chapter.chapter,
      );
    } catch (e) {
      // Handle error silently
      debugPrint('Error adding to history: $e');
    }
  }

  // --- Fungsi untuk navigasi chapter ---
  void _changeChapter(String newChapterSlug) {
    // Navigasi yang valid (slug tidak boleh null atau kosong)
    if (newChapterSlug.isEmpty) return;

    // Notifikasi perubahan chapter
    String chapterName = newChapterSlug.split('-').last.capitalizeFirst ?? "Chapter Baru";
    Get.snackbar(
      'Mengganti Chapter',
      'Memuat $chapterName...',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.teal,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );

    setState(() {
      _currentChapterUrl = newChapterSlug;
      _imageFuture = _fetchImages(newChapterSlug); // Muat ulang data
    });

    // Menggulir ke atas saat chapter baru dimuat
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut
      );
    }

    // Add to history for new chapter
    _addToHistory();
  }

  // --- Widget Tombol Navigasi Footer ---
  Widget _buildFixedFooter(ChapterImageResponse response) {
    // Menggunakan Padding di luar Positioned untuk menghindari Safe Area ganda
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: Colors.black87,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10)
          ]
        ),
        child: SafeArea(
          top: false, // Karena sudah ada AppBar, bottom safe area saja yang penting
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Tombol Sebelumnya
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: response.backChapterSlug != null ? () => _changeChapter(response.backChapterSlug!) : null,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text("Prev Chapter"),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12)),
                ),
              ),
              const SizedBox(width: 16),
              // Tombol Selanjutnya
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: response.nextChapterSlug != null ? () => _changeChapter(response.nextChapterSlug!) : null,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text("Next Chapter"),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.title, style: const TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Get.back(),
          )
        ],
      ),

      body: FutureBuilder<ChapterImageResponse>(
        future: _imageFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.teal));
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                '❌ Error memuat chapter: ${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            );
          } else if (snapshot.hasData && snapshot.data!.imageUrls.isNotEmpty) {
            final response = snapshot.data!;
            final imageUrls = response.imageUrls;

            // --- STRUKTUR BARU MENGGUNAKAN STACK ---
            return Stack(
              children: [
                // 1. Daftar Gambar (dengan padding bawah agar tidak tertutup footer)
                ListView.builder(
                  controller: _scrollController, // Tambahkan controller
                  itemCount: imageUrls.length,
                  padding: const EdgeInsets.only(bottom: 80), // Tambahkan padding bawah
                  itemBuilder: (context, index) {
                    return CachedNetworkImage(
                      imageUrl: imageUrls[index],
                      fit: BoxFit.fitWidth,
                      placeholder: (context, url) => Container(
                        height: 300,
                        alignment: Alignment.center,
                        child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.teal),
                      ),
                      errorWidget: (context, url, error) => const Icon(Icons.image_not_supported, size: 80, color: Colors.white38),
                    );
                  },
                ),

                // 2. Kontrol Navigasi Fixed di Bawah Layar
                _buildFixedFooter(response),
              ],
            );
            // --- AKHIR STRUKTUR BARU ---

          }
          return const Center(child: Text('Tidak ada gambar chapter yang dimuat.', style: TextStyle(color: Colors.white)));
        },
      ),
    );
  }
}
