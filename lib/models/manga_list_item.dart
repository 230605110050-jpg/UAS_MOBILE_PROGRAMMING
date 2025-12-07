// lib/models/manga_list_item.dart

import 'package:flutter/foundation.dart';

class MangaListItem {
  final String title;
  final String rating;
  final String chapter;
  final String imageUrl;
  final String detailUrl; // Slug untuk navigasi ke detail

  MangaListItem({
    required this.title,
    required this.rating,
    required this.chapter,
    required this.imageUrl,
    required this.detailUrl,
  });

  factory MangaListItem.fromJson(Map<String, dynamic> json) {
    // Ambil nilai 'url' (yang sekarang kita tahu adalah URL lengkap)
    String rawUrl = json['url'] as String? ?? ''; 
    String cleanSlug = '';

    // Logika untuk mengekstrak SLUG dari URL LENGKAP
    try {
      if (kDebugMode) {
        // Hanya untuk debugging, bisa dihapus di production
        // print('Processing raw URL: $rawUrl');
      }
      
      // 1. Parse string URL menjadi objek Uri
      final uri = Uri.parse(rawUrl);
      // 2. Ambil path segments (misal: /komik/slug/)
      // Filter out empty strings from segments
      final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      
      // Slug adalah segmen terakhir (contoh: "510508-the-regressed-mercenarys-machinations")
      if (segments.isNotEmpty) {
        cleanSlug = segments.last;
      } else {
         // Jika parsing gagal mendapatkan segmen, fallback ke URL mentah
         cleanSlug = rawUrl;
      }

    } catch (e) {
      if (kDebugMode) {
        print('Error parsing URL in MangaListItem: $e');
      }
      // Jika terjadi error parsing, gunakan raw URL sebagai fallback
      cleanSlug = rawUrl;
    }
    
    // Pastikan slug yang diekstrak tidak memiliki trailing slash
    cleanSlug = cleanSlug.trimRight();


    return MangaListItem(
      title: json['title'] as String? ?? 'N/A',
      rating: json['ratting'] as String? ?? 'N/A',
      chapter: json['chapter'] as String? ?? 'N/A',
      imageUrl: json['img'] as String? ?? '',
      detailUrl: cleanSlug, // KIRIM HANYA SLUG YANG SUDAH BERSIH
    );
  }
}