import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/manga_list_item.dart';
import '../../services/api/manga_api_service.dart';
import 'detail_view.dart';

class KomikListView extends StatefulWidget {
  const KomikListView({super.key});

  @override
  State<KomikListView> createState() => _KomikListViewState();
}

class _KomikListViewState extends State<KomikListView> {
  final MangaApiService _apiService = MangaApiService();
  
  // State untuk Paging
  int _currentPage = 1;
  int _totalPages = 1;

  // State untuk Data & Loading
  List<MangaListItem> _allComics = [];
  bool _isLoading = true;
  String? _error;

  // State untuk Filter (Mempertahankan Filter Anda)
  String searchQuery = '';
  String selectedGenre = 'all'; 
  String selectedStatus = 'all'; 
  String sortBy = 'rating'; // Default ke rating/popular
  String viewMode = 'grid';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  // --- FUNGSI FETCH DATA DENGAN PAGING ---
  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await _apiService.fetchMangaByPage(_currentPage);
      if (!mounted) return;
      setState(() {
        _allComics = response.mangaList;
        _currentPage = response.currentPage;
        _totalPages = response.totalPages;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  // --- FUNGSI NAVIGASI HALAMAN ---
  void _changePage(int newPage) {
    if (newPage > 0 && newPage <= _totalPages) {
      // Pastikan ada perubahan halaman sebelum fetch
      if (_currentPage != newPage) {
        setState(() {
          _currentPage = newPage;
        });
        _fetchData(); // Muat data untuk halaman baru
      }
    }
  }

  // --- LOGIC FILTERING DAN SORTING ---
  
  List<MangaListItem> get filteredComics {
    List<MangaListItem> filtered = _allComics.where((comic) {
      final title = comic.title.toLowerCase();
      final matchesSearch = title.contains(searchQuery.toLowerCase());
      
      // Filter Genre/Status dinonaktifkan karena endpoint /terbaru tidak memiliki data genre/status spesifik.
      final matchesGenre = selectedGenre == 'all';
      final matchesStatus = selectedStatus == 'all'; 

      return matchesSearch && matchesGenre && matchesStatus;
    }).toList();

    filtered.sort((a, b) {
      final aRating = double.tryParse(a.rating.replaceAll(',', '.')) ?? 0.0;
      final bRating = double.tryParse(b.rating.replaceAll(',', '.')) ?? 0.0;
      
      if (sortBy == 'popular' || sortBy == 'rating') {
        // Urutkan dari tertinggi (b banding a)
        return bRating.compareTo(aRating);
      } 
      // Jika sorting by 'newest' (default API) atau lainnya, kembalikan 0 (urutan asli)
      return 0;
    });

    return filtered;
  }
  
  // Dummy genres karena API hanya menyediakan data list/detail, bukan list genre
  List<String> get allGenres {
    return ['action', 'fantasy', 'romance', 'comedy', 'thriller', 'sci-fi', 'horror'];
  }

  void resetFilters() {
    setState(() {
      searchQuery = '';
      selectedGenre = 'all';
      selectedStatus = 'all';
      sortBy = 'rating';
      // Panggil fetch data jika filter di reset dan data saat ini bukan data default page 1
      if (_currentPage != 1) {
         _currentPage = 1;
         _fetchData();
      } else {
         // Jika hanya filter lokal (search) yang berubah, cukup re-render
      }
    });
  }

  String _capitalize(String text) =>
      text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);

  // --- WIDGET PEMBANTU: Dropdown ---
  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required String label,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.teal.shade700),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFCCF0E3)),
        ),
      ),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(_capitalize(e))))
          .toList(),
      onChanged: onChanged,
    );
  }

  // --- WIDGET PEMBANTU: Empty/Error State ---
  Widget _buildEmptyState() {
    if (_isLoading) {
      return const Center(child: Padding(padding: EdgeInsets.only(top: 50), child: CircularProgressIndicator(color: Colors.teal)));
    }
    if (_error != null) {
      return Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 50),
            child: Text('Gagal Memuat Data: $_error', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
          ));
    }
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.teal),
            const SizedBox(height: 12),
            const Text("Tidak ada komik ditemukan",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text("Coba ubah filter atau kata kunci pencarian Anda",
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: resetFilters,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
              child: const Text("Reset Filter"),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET PEMBANTU: Pagination Controls ---
  Widget _buildPaginationControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: _currentPage > 1 ? () => _changePage(_currentPage - 1) : null,
          icon: const Icon(Icons.arrow_back_ios),
          color: Colors.teal,
          disabledColor: Colors.grey.shade400,
        ),
        Text('Halaman $_currentPage dari $_totalPages', style: const TextStyle(fontWeight: FontWeight.bold)),
        IconButton(
          onPressed: _currentPage < _totalPages ? () => _changePage(_currentPage + 1) : null,
          icon: const Icon(Icons.arrow_forward_ios),
          color: Colors.teal,
          disabledColor: Colors.grey.shade400,
        ),
      ],
    );
  }

  // --- WIDGET BUILD UTAMA ---
  @override
  Widget build(BuildContext context) {
    final comics = filteredComics;
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive Grid setup
    int crossAxisCount = screenWidth < 600
        ? 2
        : (screenWidth < 900 ? 3 : (screenWidth < 1200 ? 4 : 5));

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFECFDF5), Colors.white, Color(0xFFE6FFFA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: RefreshIndicator(
            onRefresh: _fetchData,
            color: Colors.teal,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    "Daftar Komik Terbaru",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      foreground: Paint()
                        ..shader = const LinearGradient(
                          colors: [Colors.green, Colors.teal],
                        ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Menampilkan halaman $_currentPage dari $_totalPages",
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),

                  // Search Bar
                  TextField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                      hintText: "Cari di halaman ini...",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFCCF0E3), width: 1.2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.teal, width: 1.5),
                      ),
                    ),
                    onChanged: (val) => setState(() => searchQuery = val),
                  ),
                  const SizedBox(height: 16),
                  
                  // Dropdown Filter & View Mode Toggle
                  Wrap(
                    runSpacing: 8,
                    spacing: 12,
                    children: [
                      // Dropdown Genre (Dummy, karena API endpoint ini terbatas)
                      SizedBox(width: 150,
                        child: _buildDropdown(value: selectedGenre, items: ['all', ...allGenres], label: 'Genre', onChanged: (val) => setState(() => selectedGenre = val!)),
                      ),
                      // Dropdown Status (Dummy)
                      SizedBox(width: 150,
                        child: _buildDropdown(value: selectedStatus, items: const ['all', 'ongoing', 'completed', 'hiatus'], label: 'Status', onChanged: (val) => setState(() => selectedStatus = val!)),
                      ),
                      // Dropdown Sort
                      SizedBox(width: 150,
                        child: _buildDropdown(value: sortBy, items: const ['popular', 'rating', 'newest'], label: 'Urutkan', onChanged: (val) => setState(() => sortBy = val!)),
                      ),
                      // View Mode Toggle
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFCCF0E3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(onPressed: () => setState(() => viewMode = 'grid'), icon: Icon(Icons.grid_view, color: viewMode == 'grid' ? Colors.teal : Colors.grey)),
                            IconButton(onPressed: () => setState(() => viewMode = 'list'), icon: Icon(Icons.list, color: viewMode == 'list' ? Colors.teal : Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Paging Control di atas list
                  _buildPaginationControls(),
                  const SizedBox(height: 16),

                  // List atau Grid View
                  if (comics.isNotEmpty)
                    viewMode == 'grid'
                        ? GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: comics.length,
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.68,
                              ),
                              itemBuilder: (context, index) {
                                final comic = comics[index];
                                return GestureDetector(
                                  onTap: () => Get.to(() => KomikDetailView(detailUrl: comic.detailUrl)),
                                  // Tampilan Grid Card
                                  child: Container(
                                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))]),
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Expanded(child: ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(12)), child: CachedNetworkImage(imageUrl: comic.imageUrl, fit: BoxFit.cover, width: double.infinity, placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)), errorWidget: (_, __, ___) => const Icon(Icons.broken_image)))),
                                      Padding(padding: const EdgeInsets.all(8.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        Text(comic.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis, maxLines: 2),
                                        const SizedBox(height: 4),
                                        Row(children: [const Icon(Icons.star, color: Colors.amber, size: 14), const SizedBox(width: 4), Text(comic.rating, style: const TextStyle(fontSize: 12))]),
                                        Text(comic.chapter.isNotEmpty ? 'Ch. ${comic.chapter}' : 'N/A', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                      ])),
                                    ]),
                                  ),
                                );
                              },
                            )
                        : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: comics.length,
                              itemBuilder: (context, index) {
                                final comic = comics[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                                  child: ListTile(
                                    onTap: () => Get.to(() => KomikDetailView(detailUrl: comic.detailUrl)),
                                    tileColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    leading: ClipRRect(borderRadius: BorderRadius.circular(6), child: CachedNetworkImage(imageUrl: comic.imageUrl, width: 50, height: 70, fit: BoxFit.cover, placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 1)), errorWidget: (_, __, ___) => const Icon(Icons.broken_image))),
                                    title: Text(comic.title),
                                    subtitle: Row(children: [const Icon(Icons.star, color: Colors.amber, size: 14), const SizedBox(width: 4), Text(comic.rating, style: const TextStyle(fontSize: 12)), const SizedBox(width: 8), Text('Ch. ${comic.chapter}', style: const TextStyle(fontSize: 12, color: Colors.grey))]),
                                    trailing: const Icon(Icons.chevron_right, color: Colors.teal),
                                  ),
                                );
                              },
                            )
                  else
                    _buildEmptyState(),
                  
                  // Paging Control di bawah list
                  if (comics.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: _buildPaginationControls(),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}