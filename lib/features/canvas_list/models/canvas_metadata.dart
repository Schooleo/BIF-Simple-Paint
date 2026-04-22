class CanvasMetadata {
  const CanvasMetadata({
    required this.id,
    required this.title,
    required this.createdDate,
    required this.thumbnailPath,
  });

  final String id;
  final String title;
  final DateTime createdDate;
  final String thumbnailPath;
}
