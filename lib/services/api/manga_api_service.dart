import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/manga_detail.dart';
import '../../models/manga_list_item.dart';

/// ===================================================================
/// 🔹 KELAS PAGINASI UNTUK DAFTAR MANGA
/// ===================================================================
class PaginatedMangaResponse {
  final int currentPage;
  final int totalPages;
  final List<MangaListItem> mangaList;

  PaginatedMangaResponse({
    required this.currentPage,
    required this.totalPages,
    required this.mangaList,
  });
}

/// ===================================================================
/// 🔹 FUNGSI PEMBANTU: Membersihkan & Mengekstrak SLUG dari URL
/// ===================================================================
/// Contoh:
///   - Input: "https://example.com/manga/naruto/" → Output: "naruto"
///   - Input: "boruto" → Output: "boruto"
String? _extractCleanSlug(String? rawUrl) {
  if (rawUrl == null || rawUrl.isEmpty) return null;

  // 1️⃣ Hapus trailing slash & spasi
  String cleaned = rawUrl.replaceAll(RegExp(r'/+$'), '').trim();

  // 2️⃣ Jika input masih berupa URL penuh (mengandung domain/http)
  try {
    final uri = Uri.tryParse(cleaned);
    if (uri != null && uri.hasAbsolutePath) {
      final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      if (segments.isNotEmpty) return segments.last;
    }
  } catch (_) {
    // Abaikan error parsing
  }

  // 3️⃣ Jika hanya slug sederhana
  return cleaned;
}

/// ===================================================================
/// 🔹 SERVICE UTAMA: API MANGA SCRAPER
/// ===================================================================
class MangaApiService {
  static const String baseUrl = 'https://laravel-api-manga-scraper.vercel.app/api/api';

  // ===============================================================
  // 📘 1. Fetch Data Manga dengan Pagination (/terbaru/{page})
  // ===============================================================
  Future<PaginatedMangaResponse> fetchMangaByPage(int pageNumber) async {
    final url = Uri.parse('$baseUrl/terbaru/$pageNumber');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);

      if (jsonResponse['success'] == true && jsonResponse['data'] is Map) {
        final data = jsonResponse['data'];
        final currentPage = int.tryParse(data['current_page']?.toString() ?? '1') ?? 1;
        final totalPages = int.tryParse(data['total_page']?.toString() ?? '1') ?? 1;

        List<MangaListItem> mangaList = [];
        if (data['data'] is List) {
          mangaList = (data['data'] as List)
              .map((json) => MangaListItem.fromJson(json as Map<String, dynamic>))
              .toList();
        }

        return PaginatedMangaResponse(
          currentPage: currentPage,
          totalPages: totalPages,
          mangaList: mangaList,
        );
      } else {
        throw Exception('Gagal parsing data paginasi atau respons tidak valid.');
      }
    } else {
      throw Exception('Gagal memuat komik terbaru. Status: ${response.statusCode}');
    }
  }

  // ===============================================================
  // 📖 2. Fetch Detail Komik (/detail/{slug})
  // ===============================================================
  Future<MangaDetail> fetchMangaDetail(String detailSlug) async {
    final cleanSlug = _extractCleanSlug(detailSlug) ?? detailSlug;
    final url = Uri.parse('$baseUrl/detail/$cleanSlug');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);

      if (jsonResponse['success'] == true && jsonResponse['data'] is Map) {
        try {
          return MangaDetail.fromJson(jsonResponse['data'] as Map<String, dynamic>);
        } catch (e) {
          throw Exception('Gagal parsing data detail: $e');
        }
      } else {
        throw Exception('Respons API tidak sukses atau struktur data tidak valid.');
      }
    } else {
      throw Exception('Gagal memuat detail komik. Status: ${response.statusCode}');
    }
  }

  // ===============================================================
  // 📷 3. Fetch Gambar Chapter (/baca/{slug})
  // ===============================================================
  Future<ChapterImageResponse> fetchChapterImages(String chapterUrl) async {
    final cleanChapterSlug = _extractCleanSlug(chapterUrl);
    if (cleanChapterSlug == null) {
      throw Exception('Chapter URL tidak valid.');
    }

    final url = Uri.parse('$baseUrl/baca/$cleanChapterSlug');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);

      if (jsonResponse['success'] == true && jsonResponse['data'] is Map) {
        final data = jsonResponse['data'];

        List<String> imageUrls = [];
        if (data['img'] is List) {
          imageUrls = (data['img'] as List).map((e) => e.toString()).toList();
        }

        String? backSlug = _extractCleanSlug(data['back_chapter'] as String?);
        String? nextSlug = _extractCleanSlug(data['next_chapter'] as String?);

        return ChapterImageResponse(
          imageUrls: imageUrls,
          backChapterSlug: backSlug,
          nextChapterSlug: nextSlug,
        );
      } else {
        throw Exception('Respons API sukses tapi data gambar/navigasi tidak valid.');
      }
    } else {
      throw Exception('Gagal memuat gambar chapter. Status: ${response.statusCode}');
    }
  }
}