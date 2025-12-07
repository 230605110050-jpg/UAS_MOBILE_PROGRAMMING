// lib/models/manga_detail.dart

import 'package:flutter/foundation.dart';

// --- MODEL UNTUK ITEM CHAPTER ---
class MangaChapter {
  final String url; 
  final String chapter;
  final String update;
  final String? pdfFilePath; // New nullable field for PDF file path

  MangaChapter({required this.url, required this.chapter, required this.update, this.pdfFilePath});

  factory MangaChapter.fromJson(Map<String, dynamic> json) {
    String rawUrl = json['url'] as String? ?? ''; 
    String cleanSlug = '';
    
    // --- Logika untuk mengekstrak SLUG dari URL LENGKAP CHAPTER ---
    try {
      final uri = Uri.parse(rawUrl);
      // Chapter slug biasanya adalah segmen path terakhir (misal: "nama-komik-chapter-1/")
      final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      
      if (segments.isNotEmpty) {
        cleanSlug = segments.last;
      }

    } catch (e) {
      // Fallback jika parsing URL gagal (tetapi ini seharusnya dihindari)
      if (kDebugMode) {
        print('Warning: Gagal mengekstrak chapter slug. Menggunakan raw URL: $e');
      }
      cleanSlug = rawUrl;
    }
    
    // Pastikan chapter slug bersih dari trailing slash sebelum digunakan
    cleanSlug = cleanSlug.replaceAll(RegExp(r'/+$'), '');

    return MangaChapter(
      url: cleanSlug, // Simpan hanya SLUG yang bersih untuk digunakan di Service
      chapter: json['chapter'] as String? ?? 'N/A',
      update: json['update'] as String? ?? 'N/A',
      pdfFilePath: json['pdfFilePath'] as String?, // Parse new field if present
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'chapter': chapter,
      'update': update,
      'pdfFilePath': pdfFilePath,
    };
  }
}

// --- MODEL UNTUK ITEM MIRIP/REKOMENDASI ---
class MangaRelatedItem {
  final String url;
  final String img;
  final String title;
  final String subtitle;

  MangaRelatedItem({
    required this.url, 
    required this.img, 
    required this.title,
    required this.subtitle,
  });

  factory MangaRelatedItem.fromJson(Map<String, dynamic> json) {
    return MangaRelatedItem(
      url: json['url'] as String? ?? '',
      img: json['img'] as String? ?? '',
      title: json['title'] as String? ?? 'N/A',
      subtitle: json['subtitle'] as String? ?? 'N/A',
    );
  }
}

// --- MODEL UTAMA UNTUK DETAIL KOMIK (/detail/{url}) ---
class MangaDetail {
  final String title;
  final String imageUrl;
  final String rating;
  final String shortSynopsis;
  final String status;
  final String author;
  
  // Semua list diamankan dengan pengecekan tipe data
  final List<String> themes; 
  final List<MangaChapter> chapters; 
  final List<MangaRelatedItem> similarManga; 

  MangaDetail({
    required this.title,
    required this.imageUrl,
    required this.rating,
    required this.shortSynopsis,
    required this.status,
    required this.author,
    required this.themes,
    required this.chapters,
    required this.similarManga,
  });

  factory MangaDetail.fromJson(Map<String, dynamic> json) {
    
    // --- PENANGANAN TIPE DATA AMAN (PENTING UNTUK MENGHINDARI BUG) ---
    // 1. Chapters
    List<MangaChapter> chapterList = [];
    final dynamic chapterData = json['chapter']; 
    if (chapterData is List) { 
      chapterList = (chapterData)
          .map((c) => MangaChapter.fromJson(c as Map<String, dynamic>))
          .toList();
    }
    
    // 2. Mirip / Rekomendasi
    List<MangaRelatedItem> similarList = [];
    final dynamic similarData = json['mirip'];
    if (similarData is List) {
      similarList = (similarData)
          .map((m) => MangaRelatedItem.fromJson(m as Map<String, dynamic>))
          .toList();
    }
    
    // 3. Tema
    List<String> themeList = [];
    final dynamic themeData = json['tema'];
    if (themeData is List) {
      themeList = themeData.map((e) => e.toString()).toList();
    }
    // -------------------------------------------------------------------

    return MangaDetail(
      title: json['title'] as String? ?? 'N/A',
      imageUrl: json['img'] as String? ?? '',
      rating: json['ratting'] as String? ?? 'N/A',
      shortSynopsis: json['short_sinopsis'] as String? ?? 'Sinopsis tidak tersedia.',
      status: json['status'] as String? ?? 'N/A',
      author: json['pengarang'] as String? ?? 'N/A',
      
      chapters: chapterList,
      similarManga: similarList,
      themes: themeList,
    );
  }
}

// --- MODEL BARU UNTUK RESPONS GAMBAR CHAPTER (/baca) ---
class ChapterImageResponse {
  final List<String> imageUrls;
  final String? backChapterSlug;
  final String? nextChapterSlug;

  ChapterImageResponse({
    required this.imageUrls,
    this.backChapterSlug,
    this.nextChapterSlug,
  });
}