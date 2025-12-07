// ignore_for_file: deprecated_member_use

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/manga_detail.dart'; // Import model detail
import '../../services/api/manga_api_service.dart';
import '../../services/local/auth_service_local.dart';
import '../../services/local/favorites_service.dart';
import 'reader_view.dart'; // Perlu diimplementasikan selanjutnya

class KomikDetailView extends StatefulWidget {
  final String detailUrl;
  const KomikDetailView({super.key, required this.detailUrl});

  @override
  State<KomikDetailView> createState() => _KomikDetailViewState();
}

class _KomikDetailViewState extends State<KomikDetailView> {
  final MangaApiService apiService = MangaApiService();
  final AuthService _authService = AuthService();
  final FavoritesService _favoritesService = FavoritesService();

  bool _isFavorite = false;
  bool _isLoadingFavorite = false;

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
  }

  Future<void> _checkFavoriteStatus() async {
    final userId = await _authService.getCurrentUserId();
    if (userId != null) {
      final isFav = await _favoritesService.isFavorite(userId, widget.detailUrl);
      setState(() => _isFavorite = isFav);
    }
  }

  Future<void> _toggleFavorite(String title, String imageUrl) async {
    final userId = await _authService.getCurrentUserId();
    if (userId == null) {
      Get.snackbar('Error', 'Silakan login terlebih dahulu', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    setState(() => _isLoadingFavorite = true);

    bool success;
    if (_isFavorite) {
      success = await _favoritesService.removeFromFavorites(userId, widget.detailUrl);
    } else {
      success = await _favoritesService.addToFavorites(
        userId: userId,
        mangaSlug: widget.detailUrl,
        mangaTitle: title,
        mangaImageUrl: imageUrl,
      );
    }

    setState(() => _isLoadingFavorite = false);

    if (success) {
      setState(() => _isFavorite = !_isFavorite);
      // Gunakan addPostFrameCallback untuk memastikan Overlay siap
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Get.snackbar(
            'Berhasil',
            _isFavorite ? 'Ditambahkan ke favorit' : 'Dihapus dari favorit',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.teal.shade500,
            colorText: Colors.white,
          );
        }
      });
    } else {
      // Tambahkan delay kecil untuk memastikan Overlay siap
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          Get.snackbar('Error', 'Gagal memperbarui favorit', snackPosition: SnackPosition.BOTTOM);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MangaDetail>(
      future: apiService.fetchMangaDetail(widget.detailUrl),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Colors.teal)),
            backgroundColor: Color(0xFFF9FAFB),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 40),
                    const SizedBox(height: 10),
                    Text(
                        '❌ Gagal memuat detail: ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold)
                    ),
                    const SizedBox(height: 20),
                    // Tampilkan slug yang gagal dimuat (berguna untuk debugging 404)
                    const Text('Slug yang gagal:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    SelectableText(
                        widget.detailUrl,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14, color: Colors.redAccent)
                    ),
                  ],
                ),
              ),
            ),
          );
        } else if (snapshot.hasData) {
          final detail = snapshot.data!;
          return _DetailContent(
            detail: detail,
            onToggleFavorite: _toggleFavorite,
            isFavorite: _isFavorite,
            isLoadingFavorite: _isLoadingFavorite,
          ); // Pindah ke Widget Khusus
        }
        return const Scaffold(
          body: Center(child: Text('Detail komik tidak ditemukan.')),
          backgroundColor: Color(0xFFF9FAFB),
        );
      },
    );
  }
}

// --- Widget Khusus untuk Konten Detail ---
class _DetailContent extends StatelessWidget {
  final MangaDetail detail;
  final Future<void> Function(String title, String imageUrl) onToggleFavorite;
  final bool isFavorite;
  final bool isLoadingFavorite;

  const _DetailContent({
    required this.detail,
    required this.onToggleFavorite,
    required this.isFavorite,
    required this.isLoadingFavorite,
  });

  @override
  Widget build(BuildContext context) {
    // --- Penentuan Status Warna & Teks ---
    Color statusColor;
    String statusText;

    // API mengembalikan status dalam bentuk String (misal: "Ongoing" atau "Completed")
    switch (detail.status.toLowerCase()) {
      case 'ongoing':
      case 'publishing':
        statusColor = Colors.green;
        statusText = 'Berlanjut';
        break;
      case 'completed':
      case 'finished':
        statusColor = Colors.teal;
        statusText = 'Selesai';
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Hiatus / Tidak Diketahui';
    }
    // ----------------------------------------

    // Fungsi Navigasi Baca Chapter
    void onReadChapter(String chapterSlug) {
      Get.to(() => KomikReaderView(
        initialChapterUrl: chapterSlug,
        // Menggunakan GetX extension untuk kapitalisasi yang lebih aman
        title: '${detail.title} - ${chapterSlug.split('-').last.capitalizeFirst}',
      ));
    }


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
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ---------- Tombol Kembali ----------
              Row(
                children: [
                  TextButton.icon(
                    // Menggunakan Get.back() dari GetX
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.arrow_back, color: Colors.teal),
                    label: const Text(
                      "Kembali",
                      style: TextStyle(color: Colors.teal),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ---------- Info Komik (Responsive Layout) ----------
              LayoutBuilder(
                builder: (context, constraints) {
                  return constraints.maxWidth > 600
                      ? _buildWideLayout(context, statusColor, statusText, onReadChapter, detail)
                      : _buildNarrowLayout(context, statusColor, statusText, onReadChapter, detail);
                },
              ),
              const Divider(height: 40, color: Colors.teal),

              // ---------- Daftar Chapter ----------
              Text(
                "Daftar Chapter",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              // Mapping data chapters dari model
              ...detail.chapters.reversed.map((chapter) {
                return _buildChapterCard(context, chapter, onReadChapter);
              }),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Layout untuk tampilan lebar ----------
  Widget _buildWideLayout(
    BuildContext context,
    Color statusColor,
    String statusText,
    Function(String) onReadChapter,
    MangaDetail detail,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cover
        Expanded(
          flex: 3,
          child: _buildCoverImage(detail.imageUrl),
        ),
        const SizedBox(width: 24),
        // Detail
        Expanded(
          flex: 5,
          child: _buildComicDetails(context, statusColor, statusText, onReadChapter, detail),
        ),
      ],
    );
  }

  // ---------- Layout untuk tampilan sempit ----------
  Widget _buildNarrowLayout(
    BuildContext context,
    Color statusColor,
    String statusText,
    Function(String) onReadChapter,
    MangaDetail detail,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 3 / 4,
          child: _buildCoverImage(detail.imageUrl),
        ),
        const SizedBox(height: 16),
        _buildComicDetails(context, statusColor, statusText, onReadChapter, detail),
      ],
    );
  }

  // Widget Pembungkus Gambar Cover
  Widget _buildCoverImage(String imageUrl) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 4))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: imageUrl.isNotEmpty
            ? imageUrl
            : 'https://via.placeholder.com/300x400?text=No+Image',
          fit: BoxFit.cover,
          errorWidget: (context, url, error) => const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
          placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ),
    );
  }


  // ---------- Detail Komik ----------
  Widget _buildComicDetails(
    BuildContext context,
    Color statusColor,
    String statusText,
    Function(String) onReadChapter,
    MangaDetail detail,
  ) {
    // Menemukan chapter terbaru
    final latestChapter = detail.chapters.isNotEmpty ? detail.chapters.reversed.first.chapter : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            statusText,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
        const SizedBox(height: 8),

        // Judul
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.green, Colors.teal],
          ).createShader(bounds),
          child: Text(
            detail.title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Author
        Row(
          children: [
            const Icon(Icons.person, size: 18, color: Colors.grey),
            const SizedBox(width: 6),
            Text(detail.author,
                style: const TextStyle(color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 16),

        // Statistik
        Wrap(
          spacing: 20,
          runSpacing: 8,
          children: [
            _buildStat(Icons.star, Colors.amber, "Rating",
                detail.rating),
            _buildStat(Icons.menu_book, Colors.green, "Chapters",
                "${detail.chapters.length}"),
            // Tampilkan Chapter Terbaru
            if (latestChapter != null)
              _buildStat(Icons.new_releases, Colors.pink, "Terbaru",
                  latestChapter),
          ],
        ),
        const SizedBox(height: 16),

        // Genre
        const Text("Genre/Tema",
            style: TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          // Menggunakan data 'themes' dari model
          children: detail.themes
              .map((g) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.green.shade200),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.green.shade50,
                  ),
                  child: Text(
                    g,
                    style: TextStyle(fontSize: 11, color: Colors.green.shade700),
                  ),
                ))
              .toList(),
        ),
        const SizedBox(height: 16),

        // Sinopsis
        const Text("Sinopsis",
            style: TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          detail.shortSynopsis,
          style: const TextStyle(
            color: Colors.black87,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),

        // Tombol aksi
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow),
                label: const Text("Mulai Baca"),
                // Navigasi ke chapter pertama
                onPressed: detail.chapters.isNotEmpty
                    ? () => onReadChapter(detail.chapters.first.url)
                    : null, // Disable jika chapter kosong
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Tombol "Tandai" (Add/Remove Favorite)
            Expanded(
              child: OutlinedButton.icon(
                icon: isLoadingFavorite
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(isFavorite ? Icons.bookmark : Icons.bookmark_outline),
                label: Text(isFavorite ? "Favorit" : "Tandai"),
                onPressed: isLoadingFavorite ? null : () async => await onToggleFavorite(detail.title, detail.imageUrl),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.green.shade300),
                  foregroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStat(IconData icon, Color color, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
            Text(value,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }

  // ---------- Chapter Card ----------
  Widget _buildChapterCard(
    BuildContext context,
    MangaChapter chapter, // Menggunakan model MangaChapter
    Function(String) onReadChapter,
  ) {
    // API Anda hanya menyediakan chapter dan update, jadi kita pakai itu
    return InkWell(
      onTap: () => onReadChapter(chapter.url), // Gunakan chapter.url (slug chapter)
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.green.shade100),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Info
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.green.shade200),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.green.shade50,
                      ),
                      // Menampilkan nama chapter (misalnya: Chapter 143)
                      child: Text(chapter.chapter,
                          style: TextStyle(
                            fontSize: 12, color: Colors.green.shade700, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      chapter.update, // Menggunakan field update
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            TextButton(
              onPressed: () => onReadChapter(chapter.url),
              style: TextButton.styleFrom(foregroundColor: Colors.teal),
              child: const Text("Baca"),
            ),
          ],
        ),
      ),
    );
  }
}
