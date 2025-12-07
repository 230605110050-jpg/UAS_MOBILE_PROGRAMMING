import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/manga_list_item.dart';
import '../../services/api/manga_api_service.dart';
import 'list_view.dart';
import 'detail_view.dart'; // Import KomikDetailView

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final MangaApiService _apiService = MangaApiService();
  List<MangaListItem> _comics = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchHomeData();
  }

  // --- FUNGSI MUAT DATA UNTUK HOME ---
  Future<void> _fetchHomeData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // Muat Halaman 1 dari komik terbaru
      final response = await _apiService.fetchMangaByPage(1); 
      if (!mounted) return;
      setState(() {
        // Ambil list komik, jika kosong, _comics akan tetap []
        _comics = response.mangaList;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', ''); // Bersihkan pesan error
        _isLoading = false;
      });
    }
  }

  // --- Navigasi ---
  void _onNavigateToDetail(String detailUrl) {
    // Menggunakan Get.to untuk navigasi ke halaman detail
    Get.to(() => KomikDetailView(detailUrl: detailUrl));
  }

  void _onNavigateToComics() {
    // Menggunakan Get.to untuk navigasi ke halaman daftar komik
    Get.to(() => const KomikListView());
  }

  @override
  Widget build(BuildContext context) {
    // --- Tampilan Loading ---
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.teal)),
        backgroundColor: Color(0xFFF0FDF4),
      );
    }

    // --- Tampilan Error ---
    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF0FDF4),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Ups! Data utama tidak dapat dimuat saat ini.\n$_error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),

                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _fetchHomeData,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white), 
                  child: const Text("Coba Muat Ulang"),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    // Jika API mengembalikan data kosong
    if (_comics.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF0FDF4),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Belum ada komik tersedia dari API."),
              ElevatedButton(onPressed: _fetchHomeData, child: const Text("Coba Muat Ulang")),
            ],
          ),
        ),
      );
    }

    // Menggunakan data MangaListItem yang sudah ada
    final featuredComic = _comics.first;
    // Ambil 3 untuk Trending (pastikan list cukup panjang)
    final trendingComics = _comics.length > 3 ? _comics.sublist(1, 4) : _comics.skip(1).toList(); 
    // Ambil 6 untuk Recent (pastikan list cukup panjang)
    final recentComics = _comics.length > 6 ? _comics.sublist(0, 6) : _comics; 


    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchHomeData,
          color: Colors.teal,
          child: CustomScrollView(
            slivers: [
              // ---------- HERO SECTION (FITUR UTAMA) ----------
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF0D9488)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Label Featured
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            // ignore: deprecated_member_use
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white30),
                          ),
                          child: const Text("Terbaru", style: TextStyle(color: Colors.white)),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          featuredComic.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Chapter terbaru: ${featuredComic.chapter}",
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 4),
                        Row(
                           children: [
                             const Icon(Icons.star, color: Colors.amber, size: 16),
                             const SizedBox(width: 4),
                             Text("Rating: ${featuredComic.rating}/5.0", style: const TextStyle(color: Colors.white70)),
                           ],
                        ),
                        
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () => _onNavigateToDetail(featuredComic.detailUrl),
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text("Baca Detail"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.teal.shade700,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Gambar Komik
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: CachedNetworkImage(
                            imageUrl: featuredComic.imageUrl,
                            height: 380,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(height: 380, color: Colors.white12, child: const Center(child: CircularProgressIndicator())),
                            errorWidget: (_, __, ___) => const Icon(Icons.broken_image, size: 80, color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ---------- TRENDING SECTION ----------
              SliverToBoxAdapter(
                child: _buildSectionHeader(
                  context,
                  title: "Trending Sekarang (Teratas)",
                  icon: Icons.trending_up,
                  color: Colors.green,
                  onViewAll: _onNavigateToComics,
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final comic = trendingComics[index];
                    return GestureDetector(
                      onTap: () => _onNavigateToDetail(comic.detailUrl),
                      child: Card(
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Row( // List Tile Horizontal
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                              child: CachedNetworkImage(
                                imageUrl: comic.imageUrl,
                                width: 100,
                                height: 120,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(width: 100, height: 120, color: Colors.grey.shade200, child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
                                errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      comic.title,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(Icons.star, color: Colors.amber, size: 16),
                                        const SizedBox(width: 4),
                                        Text(comic.rating),
                                        const SizedBox(width: 12),
                                        const Icon(Icons.menu_book, color: Colors.teal, size: 16),
                                        const SizedBox(width: 4),
                                        Text(comic.chapter.isNotEmpty ? 'Ch. ${comic.chapter}' : 'N/A'),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: Text("#${index + 1}", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green.shade600)),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: trendingComics.length,
                ),
              ),

              // ---------- RECENT SECTION ----------
              SliverToBoxAdapter(
                child: _buildSectionHeader(
                  context,
                  title: "Update Terbaru Lainnya",
                  icon: Icons.access_time,
                  color: Colors.teal,
                  onViewAll: _onNavigateToComics,
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final comic = recentComics[index];
                      return _buildRecentComicCard(comic, _onNavigateToDetail); // Gunakan builder card
                    },
                    childCount: recentComics.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.62,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                ),
              ),

              // ---------- CTA SECTION ----------
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    color: Colors.teal.shade600,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                      child: Column(
                        children: [
                          const Text(
                            "Jelajahi Semua Komik",
                            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Lihat daftar lengkap komik terbaru per halaman.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _onNavigateToComics,
                            icon: const Icon(Icons.arrow_forward),
                            label: const Text("Lihat Semua"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.teal.shade700,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Padding tambahan di bawah
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widget Pembantu (Header) ---

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onViewAll,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color, 
                ),
              ),
            ],
          ),
          TextButton.icon(
            onPressed: onViewAll,
            icon: Icon(Icons.arrow_forward, color: color, size: 18),
            label: Text("Lihat Semua", style: TextStyle(color: color, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  // --- Widget Pembantu (Card Grid) ---

  Widget _buildRecentComicCard(MangaListItem comic, Function(String) onTap) {
    return GestureDetector(
      onTap: () => onTap(comic.detailUrl),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: CachedNetworkImage(
                  imageUrl: comic.imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    comic.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text(comic.rating, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                  Text(
                    comic.chapter.isNotEmpty ? 'Ch. ${comic.chapter}' : 'N/A',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}