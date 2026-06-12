// lib/screens/note_list_screen.dart

import 'package:flutter/material.dart';
import '../models/note.dart';
import '../helpers/file_helper.dart';
import '../main.dart' show themeNotifier;
import 'note_editor_screen.dart';

class NoteListScreen extends StatefulWidget {
  const NoteListScreen({super.key});

  @override
  State<NoteListScreen> createState() => _NoteListScreenState();
}

class _NoteListScreenState extends State<NoteListScreen> {
  final FileHelper _fileHelper = FileHelper();
  List<Note> _notes = [];
  bool _isLoading = true;

  static const List<String> _monthNames = [
    '',
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  String _formatDate(String iso8601) {
    try {
      final dt = DateTime.parse(iso8601);
      return '${dt.day} ${_monthNames[dt.month]} ${dt.year}';
    } catch (_) {
      return '';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final notes = await _fileHelper.getAllNotes();

    if (!mounted) return;
    setState(() {
      _notes = notes;
      _isLoading = false;
    });
  }

  Future<void> _deleteNote(String noteId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Catatan'),
        content: const Text(
          'Catatan beserta semua gambar pendampingnya akan dihapus secara permanen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
            const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _fileHelper.deleteNote(noteId);
      _loadNotes();
    }
  }

  Future<void> _navigateToEditor({Note? note}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteEditorScreen(note: note),
      ),
    );
    _loadNotes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catatan'),
        actions: [
          // Tombol toggle dark/light mode
          ValueListenableBuilder(
            valueListenable: themeNotifier,
            builder: (_, mode, __) => IconButton(
              icon: Icon(
                mode == ThemeMode.dark
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
              ),
              tooltip: mode == ThemeMode.dark ? 'Mode Terang' : 'Mode Gelap',
              onPressed: themeNotifier.toggle,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notes.isEmpty
          ? const Center(
        child: Text(
          'Belum ada catatan.\nTekan + untuk membuat catatan baru.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      )
          : ListView.builder(
        itemCount: _notes.length,
        itemBuilder: (context, index) {
          final note = _notes[index];
          return _buildNoteCard(note);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToEditor(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildNoteCard(Note note) {
    final formattedDate = _formatDate(note.lastModified);

    // Warna background card dari tag
    Color? cardColor;
    if (note.colorTag.isNotEmpty) {
      cardColor = Color(int.parse(note.colorTag, radix: 16));
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      color: cardColor,
      child: ListTile(
        leading: _buildLeadingIcon(note),
        title: Row(
          children: [
            if (note.isPinned) ...[
              const Icon(Icons.push_pin, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
            ],
            Expanded(
              child: Text(
                note.title.isEmpty ? '(Tanpa judul)' : note.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (formattedDate.isNotEmpty)
              Text(
                formattedDate,
                style:
                const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            Text(
              note.content.isEmpty ? '(Tidak ada isi)' : note.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _deleteNote(note.id),
        ),
        onTap: () => _navigateToEditor(note: note),
      ),
    );
  }

  Widget _buildLeadingIcon(Note note) {
    if (note.imageCount == 0) {
      return const Icon(Icons.article_outlined, color: Colors.grey);
    }
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.image, color: Colors.blue),
        if (note.imageCount > 1)
          Positioned(
            right: -6,
            top: -6,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.amber,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${note.imageCount}',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
      ],
    );
  }
}