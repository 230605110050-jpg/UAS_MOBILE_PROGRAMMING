import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AccountAuthorView extends StatefulWidget {
  // Data and callbacks must be provided by MainWrapper
  final String authorId;
  final List<Map<String, dynamic>> comics;
  final Function(Map<String, dynamic>) onCreateComic;
  final Function(String, Map<String, dynamic>) onUpdateComic;
  final Function(String) onDeleteComic;

  const AccountAuthorView({
    super.key,
    required this.authorId,
    required this.comics,
    required this.onCreateComic,
    required this.onUpdateComic,
    required this.onDeleteComic,
  });

  @override
  State<AccountAuthorView> createState() => _AccountAuthorViewState();
}

class _AccountAuthorViewState extends State<AccountAuthorView> {
  // Form controllers
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController coverController = TextEditingController();
  final TextEditingController genreController = TextEditingController();

  String status = 'ongoing';
  List<String> genres = [];
  Map<String, dynamic>? selectedComic;

  // State untuk menampilkan Dialog (diperlukan untuk stateful dialog)
  bool showCreateDialog = false;
  bool showEditDialog = false;
  bool showDeleteDialog = false;

  void resetForm() {
    titleController.clear();
    descriptionController.clear();
    coverController.clear();
    genreController.clear();
    setState(() {
      genres = [];
      status = 'ongoing';
      selectedComic = null; // Tambahkan reset selectedComic
    });
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    coverController.dispose();
    genreController.dispose();
    super.dispose();
  }
  
  // --- Fungsi yang dipanggil oleh tombol dialog ---
  // Menggunakan fungsi terpisah untuk memastikan dialog muncul di atas konten utama
  void _showCreateDialog() {
    resetForm();
    showDialog(
      context: context,
      builder: (context) => _buildComicDialog(context, isEdit: false),
    );
  }

  void _showEditDialog(Map<String, dynamic> comic) {
    titleController.text = comic['title'];
    descriptionController.text = comic['description'] ?? '';
    coverController.text = comic['coverImage'] ?? '';
    setState(() {
      genres = List<String>.from(comic['genre'] ?? []);
      status = comic['status'] ?? 'ongoing';
      selectedComic = comic;
    });

    showDialog(
      context: context,
      builder: (context) => _buildComicDialog(context, isEdit: true),
    );
  }
  
  void _showDeleteDialog(Map<String, dynamic> comic) {
    setState(() {
      selectedComic = comic;
    });
    showDialog(
      context: context,
      builder: (context) => _buildDeleteDialog(context),
    );
  }


  @override
  Widget build(BuildContext context) {
    // Filter komik berdasarkan authorId
    final authorComics = widget.comics.where((comic) => comic['authorId'] == widget.authorId).toList();

     return Scaffold(
       backgroundColor: const Color(0xFFF9FAFB),
       body: SafeArea(
         child: ListView(
           padding: const EdgeInsets.all(16),
           children: [
             // Existing Widgets here: Header, Statistics, Comics List (from existing code above)...
             // Build comics list   manage comics
             ...buildComicListAndManagement(authorComics),

             const SizedBox(height: 24),

             // Chapter Management Card (new)
             ...buildChapterManagement(authorComics),
           ],
         ),
       ),
     );
   }

   List<Widget> buildComicListAndManagement(List<Map<String, dynamic>> authorComics) {
     return [
       Row(
         mainAxisAlignment: MainAxisAlignment.spaceBetween,
         children: [
           const Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Text(
                 "Dashboard Author",
                 style: TextStyle(
                   fontSize: 26,
                   fontWeight: FontWeight.bold,
                   color: Colors.teal,
                 ),
               ),
               Text(
                 "Kelola komik dan pantau performa Anda",
                 style: TextStyle(color: Colors.grey),
               ),
             ],
           ),
           ElevatedButton.icon(
             onPressed: _showCreateDialog, // Panggil showDialog
             style: ElevatedButton.styleFrom(
               backgroundColor: Colors.teal,
               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
             ),
             icon: const Icon(Icons.add, color: Colors.white),
             label: const Text("Buat Komik Baru",
                 style: TextStyle(color: Colors.white)),
           ),
         ],
       ),
       const SizedBox(height: 24),
       // Comics Grid Stats and List (same as previous UI)
       GridView(
         shrinkWrap: true,
         physics: const NeverScrollableScrollPhysics(),
         gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
             crossAxisCount: 2,
             crossAxisSpacing: 12,
             mainAxisSpacing: 12,
             childAspectRatio: 2.5),
         children: [
           _buildStatCard("Total Komik", authorComics.length.toString(), Icons.menu_book, Colors.green),
           _buildStatCard("Total Views", "${(authorComics.fold<num>(0, (sum, c) => (sum + (c['totalViews'] ?? 0))) / 1000).toStringAsFixed(1)}k", Icons.visibility, Colors.teal),
           _buildStatCard("Rating Rata-rata", authorComics.isNotEmpty ? (authorComics.fold<double>(0.0, (sum, c) => sum + (c['rating'] ?? 0.0)) / authorComics.length).toStringAsFixed(1) : '0', Icons.star, Colors.amber),
           _buildStatCard("Total Pembaca", "1.2k", Icons.people, Colors.purple),
         ],
       ),
       const SizedBox(height: 24),
       Card(
         shape: RoundedRectangleBorder(
           borderRadius: BorderRadius.circular(16),
           side: const BorderSide(color: Color(0xFFCCF0E3)),
         ),
         child: Padding(
           padding: const EdgeInsets.all(16),
           child: Column(
             children: [
               const Align(
                 alignment: Alignment.centerLeft,
                 child: Text(
                   "Daftar Komik Anda",
                   style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                 ),
               ),
               const SizedBox(height: 12),
               if (authorComics.isEmpty)
                 Column(
                   children: [
                     const Icon(Icons.menu_book, size: 60, color: Colors.teal),
                     const SizedBox(height: 8),
                     const Text("Belum ada komik"),
                     const Text("Mulai membuat komik pertama Anda"),
                     const SizedBox(height: 12),
                     ElevatedButton.icon(
                       onPressed: _showCreateDialog,
                       icon: const Icon(Icons.add, color: Colors.white),
                       label: const Text("Buat Komik Baru",
                           style: TextStyle(color: Colors.white)),
                       style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                     ),
                   ],
                 )
               else
                 Column(
                   children: authorComics.map((comic) {
                     return ListTile(
                       contentPadding: const EdgeInsets.symmetric(vertical: 8),
                       leading: ClipRRect(
                         borderRadius: BorderRadius.circular(6),
                         child: Image.network(
                           comic['coverImage'] ?? 'https://via.placeholder.com/80',
                           height: 80,
                           width: 60,
                           fit: BoxFit.cover,
                           errorBuilder: (context, error, stackTrace) => Container(
                             height: 80,
                             width: 60,
                             color: Colors.grey[300],
                             child: const Icon(Icons.image_not_supported, color: Colors.grey),
                           ),
                         ),
                       ),
                       title: Text(comic['title']),
                       subtitle: Text("Genre: ${comic['genre']?.join(', ')} • ${comic['status']}", style: const TextStyle(color: Colors.grey)),
                       trailing: Wrap(
                         children: [
                           IconButton(
                             onPressed: () => _showEditDialog(comic),
                             icon: const Icon(Icons.edit, color: Colors.teal),
                           ),
                           IconButton(
                             onPressed: () => _showDeleteDialog(comic),
                             icon: const Icon(Icons.delete, color: Colors.red),
                           ),
                         ],
                       ),
                     );
                   }).toList(),
                 ),
             ],
           ),
         ),
       ),
       const SizedBox(height: 40),
     ];
   }

  List<Widget> buildChapterManagement(List<Map<String, dynamic>> authorComics) {
    // For simplicity, show list of chapters from first comic (or none)
    final firstComic = authorComics.isNotEmpty ? authorComics[0] : null;
    final chapters = (firstComic != null) ? List<Map<String, dynamic>>.from(firstComic['chapters'] ?? []) : [];

    return [
      Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFCCF0E3))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Chapter Management (for first comic)",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text("Add Chapter"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                onPressed: () {
                  _showAddChapterDialog();
                },
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: chapters.length,
                itemBuilder: (context, index) {
                  final chapter = chapters[index];
                  return ListTile(
                    title: Text(chapter['chapterTitle'] ?? 'Unknown Chapter'),
                    subtitle: Text(chapter['chapterSlug'] ?? ''),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.teal),
                          onPressed: () => _showEditChapterDialog(chapter, index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _showDeleteChapterDialog(chapter, index),
                        ),
                      ],
                    ),
                  );
                },
              )
            ],
          ),
        ),
      ),
    ];
  }

  void _showAddChapterDialog() {
    String chapterTitle = '';
    String chapterSlug = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, void Function(void Function()) setStateDialog) {
          return AlertDialog(
            title: const Text("Add Chapter"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(labelText: "Chapter Title"),
                  onChanged: (val) => chapterTitle = val,
                ),
                const SizedBox(height: 8),
                TextField(
                  decoration: const InputDecoration(labelText: "Chapter Slug / URL"),
                  onChanged: (val) => chapterSlug = val,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                onPressed: () {
                  if (chapterTitle.trim().isEmpty || chapterSlug.trim().isEmpty) {
                    Get.snackbar(
                      'Error',
                      'Please fill all chapter fields.',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                    );
                    return;
                  }
                  _addChapter(chapterTitle.trim(), chapterSlug.trim());
                  Navigator.pop(context);
                },
                child: const Text("Add"),
              )
            ],
          );
        },
      ),
    );
  }

  void _addChapter(String title, String slug) {
    final authorComics = widget.comics.where((c) => c['authorId'] == widget.authorId).toList();
    if (authorComics.isEmpty) return;
    final comic = authorComics.first;

    final chapters = List<Map<String, dynamic>>.from(comic['chapters'] ?? []);
    chapters.add({'chapterTitle': title, 'chapterSlug': slug});
    comic['chapters'] = chapters;

    widget.onUpdateComic(comic['id'], comic);
    setState(() {});
  }

  void _showEditChapterDialog(Map<String, dynamic> chapter, int index) {
    String chapterTitle = chapter['chapterTitle'] ?? '';
    String chapterSlug = chapter['chapterSlug'] ?? '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, void Function(void Function()) setStateDialog) {
          return AlertDialog(
            title: const Text("Edit Chapter"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(labelText: "Chapter Title"),
                  controller: TextEditingController(text: chapterTitle),
                  onChanged: (val) => chapterTitle = val,
                ),
                const SizedBox(height: 8),
                TextField(
                  decoration: const InputDecoration(labelText: "Chapter Slug / URL"),
                  controller: TextEditingController(text: chapterSlug),
                  onChanged: (val) => chapterSlug = val,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                onPressed: () {
                  if (chapterTitle.trim().isEmpty || chapterSlug.trim().isEmpty) {
                    Get.snackbar(
                      'Error',
                      'Please fill all chapter fields.',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                    );
                    return;
                  }
                  _editChapter(index, chapterTitle.trim(), chapterSlug.trim());
                  Navigator.pop(context);
                },
                child: const Text("Save"),
              )
            ],
          );
        },
      ),
    );
  }

  void _editChapter(int index, String title, String slug) {
    final authorComics = widget.comics.where((c) => c['authorId'] == widget.authorId).toList();
    if (authorComics.isEmpty) return;
    final comic = authorComics.first;

    final chapters = List<Map<String, dynamic>>.from(comic['chapters'] ?? []);
    if (index < 0 || index >= chapters.length) return;

    chapters[index] = {'chapterTitle': title, 'chapterSlug': slug};
    comic['chapters'] = chapters;

    widget.onUpdateComic(comic['id'], comic);
    setState(() {});
  }

  void _showDeleteChapterDialog(Map<String, dynamic> chapter, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Chapter"),
        content: Text('Are you sure you want to delete the chapter "${chapter['chapterTitle'] ?? ''}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              _deleteChapter(index);
              Navigator.pop(context);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  void _deleteChapter(int index) {
    final authorComics = widget.comics.where((c) => c['authorId'] == widget.authorId).toList();
    if (authorComics.isEmpty) return;
    final comic = authorComics.first;

    final chapters = List<Map<String, dynamic>>.from(comic['chapters'] ?? []);
    if (index < 0 || index >= chapters.length) return;

    chapters.removeAt(index);
    comic['chapters'] = chapters;

    widget.onUpdateComic(comic['id'], comic);
    setState(() {});
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withAlpha((0.2 * 255).toInt()),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(title, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Removed duplicate empty buildChapterManagement method

  // Dialog Buat/Edit Komik
  Widget _buildComicDialog(BuildContext context, {required bool isEdit}) {
    // Gunakan StatefulBuilder untuk mengelola state lokal dialog (genres, status)
    return StatefulBuilder(
      builder: (context, setStateDialog) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min, 
              children: [
                Text(
                  isEdit ? "Edit Komik" : "Buat Komik Baru",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: "Judul Komik",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: "Deskripsi",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: coverController,
                  decoration: const InputDecoration(
                    labelText: "URL Cover Image",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                // Input Genre
                TextField(
                  controller: genreController,
                  onSubmitted: (value) {
                    if (value.isNotEmpty && !genres.contains(value)) {
                      setStateDialog(() {
                        genres.add(value.trim());
                        genreController.clear();
                      });
                    }
                  },
                  decoration: InputDecoration(
                    labelText: "Tambah Genre",
                    hintText: "Tekan Enter atau ikon ' '",
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        if (genreController.text.isNotEmpty &&
                            !genres.contains(genreController.text)) {
                          setStateDialog(() {
                            genres.add(genreController.text.trim());
                            genreController.clear();
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Tampilan Chips Genre
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: genres
                      .map((g) => Chip(
                            label: Text(g),
                            onDeleted: () => setStateDialog(() => genres.remove(g)),
                            deleteIconColor: Colors.redAccent,
                          ))
                      .toList(),
                ),
                const SizedBox(height: 12),
                // Dropdown Status
                DropdownButtonFormField<String>(
                  initialValue: status,
                  items: const [
                    DropdownMenuItem(value: 'ongoing', child: Text('Berlanjut')),
                    DropdownMenuItem(value: 'completed', child: Text('Selesai')),
                    DropdownMenuItem(value: 'hiatus', child: Text('Hiatus')),
                  ],
                  onChanged: (v) => setStateDialog(() => status = v!),
                  decoration: const InputDecoration(
                    labelText: "Status",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                // Tombol Aksi
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        // Close dialog and reset local state
                        Navigator.pop(context);
                        resetForm();
                      },
                      child: const Text("Batal"),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        // Simple validation
                        if (titleController.text.isEmpty ||
                            descriptionController.text.isEmpty ||
                            coverController.text.isEmpty) {
                          Get.snackbar(
                            'Error',
                            'Harap isi semua kolom wajib.',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                          );
                          return;
                        }
                        
                        // Send data to parent handler
                        if (isEdit && selectedComic != null) {
                          widget.onUpdateComic(selectedComic!['id'], {
                            'title': titleController.text,
                            'description': descriptionController.text,
                            'coverImage': coverController.text,
                            'genre': genres,
                            'status': status,
                          });
                          Get.snackbar(
                            'Sukses',
                            'Komik berhasil diupdate.',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.green,
                            colorText: Colors.white,
                          );
                        } else {
                          // Create new comic
                          widget.onCreateComic({
                            'id': DateTime.now().millisecondsSinceEpoch.toString(),
                            'title': titleController.text,
                            'description': descriptionController.text,
                            'coverImage': coverController.text,
                            'genre': genres,
                            'status': status,
                            'authorId': widget.authorId,
                            'rating': 0.0,
                            'totalViews': 0,
                            'chapters': [],
                            'createdAt': DateTime.now().toIso8601String(),
                          });
                          Get.snackbar(
                            'Sukses',
                            'Komik baru berhasil dibuat.',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.green,
                            colorText: Colors.white,
                          );
                        }
                        
                        Navigator.pop(context);
                        resetForm();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(isEdit ? "Simpan" : "Buat"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Dialog Hapus Komik
  Widget _buildDeleteDialog(BuildContext context) {
    return AlertDialog(
      title: const Text("Hapus Komik"),
      content: Text(
          'Apakah Anda yakin ingin menghapus komik "**${selectedComic?['title'] ?? ''}**"? Tindakan ini tidak dapat dibatalkan.'),
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              selectedComic = null;
            });
            Navigator.pop(context);
          },
          child: const Text("Batal"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
          onPressed: () {
            if (selectedComic != null && selectedComic!['id'] is String) {
              widget.onDeleteComic(selectedComic!['id']);
              Get.snackbar('Terhapus', 'Komik berhasil dihapus.', 
                snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.redAccent, colorText: Colors.white);
              setState(() {
                selectedComic = null;
              });
            }
            Navigator.pop(context);
          },
          child: const Text("Hapus"),
        ),
      ],
    );
  }
}