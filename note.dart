class Note {
  final String id;
  final String title;
  final String content;
  final bool hasImage;
  final String lastModified;
  final int imageCount;
  final bool isPinned;
  final String colorTag; // hex color string, e.g. 'FFFFEB3B' or '' untuk default

  const Note({
    required this.id,
    required this.title,
    required this.content,
    this.hasImage = false,
    this.lastModified = '',
    this.imageCount = 0,
    this.isPinned = false,
    this.colorTag = '',
  });
}