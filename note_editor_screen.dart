// lib/screens/note_editor_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/note.dart';
import '../helpers/file_helper.dart';

// Pilihan warna tag yang tersedia
const List<_ColorOption> kColorOptions = [
  _ColorOption('Default', ''),
  _ColorOption('Kuning', 'FFFFF9C4'),
  _ColorOption('Hijau', 'FFC8E6C9'),
  _ColorOption('Biru', 'FFBBDEFB'),
  _ColorOption('Merah Muda', 'FFF8BBD0'),
  _ColorOption('Oranye', 'FFFFE0B2'),
  _ColorOption('Ungu', 'FFE1BEE7'),
];

class _ColorOption {
  final String label;
  final String hex; // '' = default / tidak ada warna
  const _ColorOption(this.label, this.hex);

  Color? get color => hex.isEmpty ? null : Color(int.parse(hex, radix: 16));
}

class NoteEditorScreen extends StatefulWidget {
  final Note? note;
  const NoteEditorScreen({super.key, this.note});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final FileHelper _fileHelper = FileHelper();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  bool _isSaving = false;
  bool _isPinned = false;
  String _colorTag = ''; // hex string kosong = default

  // Slot gambar: index 0 = image_1.jpg, dst.
  final List<File?> _imageSlots = [null, null, null];
  final List<bool> _isExistingImage = [false, false, false];

  bool get _isEditMode => widget.note != null;
  late final String _resolvedNoteId;

  int get _imageCount => _imageSlots.where((f) => f != null).length;
  bool get _canAddImage => _imageCount < FileHelper.maxImages;

  @override
  void initState() {
    super.initState();
    _resolvedNoteId = widget.note?.id ?? _fileHelper.generateNoteId();
    if (_isEditMode) {
      _titleController.text = widget.note!.title;
      _contentController.text = widget.note!.content;
      _isPinned = widget.note!.isPinned;
      _colorTag = widget.note!.colorTag;
      _loadExistingImages();
    }
  }

  Future<void> _loadExistingImages() async {
    final files = await _fileHelper.getAllNoteImageFiles(_resolvedNoteId);
    if (!mounted) return;
    setState(() {
      for (int i = 0; i < files.length; i++) {
        _imageSlots[i] = files[i];
        _isExistingImage[i] = files[i] != null;
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (!_canAddImage) return;

    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 100,
    );
    if (xFile == null || !mounted) return;

    final emptyIndex = _imageSlots.indexWhere((f) => f == null);
    if (emptyIndex == -1) return;

    setState(() {
      _imageSlots[emptyIndex] = File(xFile.path);
      _isExistingImage[emptyIndex] = false;
    });
  }

  Future<void> _removeImage(int slotIndex) async {
    setState(() {
      _imageSlots[slotIndex] = null;
      _isExistingImage[slotIndex] = false;
    });
  }

  Future<void> _saveNote() async {
    if (_titleController.text.trim().isEmpty &&
        _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Judul atau isi catatan tidak boleh kosong.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _fileHelper.saveNote(
        _resolvedNoteId,
        _titleController.text.trim(),
        _contentController.text.trim(),
        isPinned: _isPinned,
        colorTag: _colorTag,
      );

      for (int i = 0; i < FileHelper.maxImages; i++) {
        final fileInSlot = _imageSlots[i];
        final diskIndex = i + 1;

        if (fileInSlot == null) {
          if (_isExistingImage[i]) {
            await _fileHelper.deleteNoteImage(_resolvedNoteId, diskIndex);
          }
        } else {
          if (!_isExistingImage[i]) {
            await _fileHelper.saveNoteImage(
                _resolvedNoteId, diskIndex, fileInSlot.path);
          }
        }
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan catatan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Color picker bottom sheet ───────────────────────────────────────────────
  void _showColorPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pilih Warna Tag',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: kColorOptions.map((opt) {
                  final isSelected = _colorTag == opt.hex;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _colorTag = opt.hex);
                      Navigator.pop(context);
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: opt.color ??
                                Theme.of(context).colorScheme.surface,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey.shade300,
                              width: isSelected ? 3 : 1,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, size: 18)
                              : null,
                        ),
                        const SizedBox(height: 4),
                        Text(opt.label,
                            style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Background warna tag jika dipilih
    final tagColor = _colorTag.isNotEmpty
        ? Color(int.parse(_colorTag, radix: 16))
        : null;

    return Scaffold(
      backgroundColor: tagColor,
      appBar: AppBar(
        backgroundColor: tagColor,
        title: Text(_isEditMode ? 'Edit Catatan' : 'Catatan Baru'),
        actions: [
          // Tombol pin
          IconButton(
            icon: Icon(
              _isPinned ? Icons.push_pin : Icons.push_pin_outlined,
              color: _isPinned
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            tooltip: _isPinned ? 'Lepas Pin' : 'Pin Catatan',
            onPressed: () => setState(() => _isPinned = !_isPinned),
          ),
          // Tombol warna
          IconButton(
            icon: const Icon(Icons.palette_outlined),
            tooltip: 'Warna Tag',
            onPressed: _showColorPicker,
          ),
          // Tombol simpan
          _isSaving
              ? const Padding(
            padding: EdgeInsets.all(16),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
              : IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Simpan',
            onPressed: _saveNote,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Judul catatan',
                border: InputBorder.none,
              ),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                hintText: 'Tulis catatanmu di sini...',
                border: InputBorder.none,
              ),
              maxLines: null,
              minLines: 8,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            _buildImageSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    final hasAnyImage = _imageSlots.any((f) => f != null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasAnyImage) ...[
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: FileHelper.maxImages,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final file = _imageSlots[i];
                if (file == null) return const SizedBox.shrink();
                return _buildImageTile(file, i);
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
        OutlinedButton.icon(
          onPressed: _canAddImage ? _pickImage : null,
          icon: const Icon(Icons.add_photo_alternate),
          label: Text(
            _canAddImage
                ? 'Tambah Gambar ($_imageCount/${FileHelper.maxImages})'
                : 'Kuota Gambar Penuh (${FileHelper.maxImages}/${FileHelper.maxImages})',
          ),
        ),
      ],
    );
  }

  Widget _buildImageTile(File file, int slotIndex) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            file,
            width: 140,
            height: 160,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: GestureDetector(
            onTap: () => _removeImage(slotIndex),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(4),
              child:
              const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }
}