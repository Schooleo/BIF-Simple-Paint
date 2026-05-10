import 'dart:convert';
import 'dart:typed_data';

class CanvasMetadata {
  const CanvasMetadata({
    required this.id,
    required this.name,
    required this.filePath,
    required this.lastEditedTime,
    this.thumbnailData,
  });

  final String id;
  final String name;
  final String filePath;
  final DateTime lastEditedTime;
  final Uint8List? thumbnailData;

  factory CanvasMetadata.fromMap(Map<String, Object?> map) {
    final rawThumbnail = map['thumbnailData'];
    Uint8List? thumbnailData;
    if (rawThumbnail is String && rawThumbnail.isNotEmpty) {
      thumbnailData = base64Decode(rawThumbnail);
    }

    return CanvasMetadata(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'Untitled',
      filePath: map['filePath'] as String? ?? '',
      lastEditedTime:
          DateTime.tryParse(map['lastEditedTime'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      thumbnailData: thumbnailData,
    );
  }
}
