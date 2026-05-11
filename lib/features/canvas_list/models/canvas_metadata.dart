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

class CanvasListItemData {
  const CanvasListItemData({
    required this.id,
    required this.displayName,
    required this.fileName,
    required this.editedLabel,
    this.thumbnailBytes,
  });

  final String id;
  final String displayName;
  final String fileName;
  final String editedLabel;
  final Uint8List? thumbnailBytes;
}

extension CanvasMetadataUi on CanvasMetadata {
  CanvasListItemData toListItemData() {
    final fileName = _fileNameFromPath(filePath);
    final editedLabel = _formatLastEdited(lastEditedTime);
    return CanvasListItemData(
      id: id,
      displayName: name,
      fileName: fileName.isEmpty ? 'Untitled' : fileName,
      editedLabel: editedLabel,
      thumbnailBytes: thumbnailData,
    );
  }

  String _fileNameFromPath(String path) {
    final normalized = path.replaceAll('\\', '/');
    final index = normalized.lastIndexOf('/');
    if (index == -1 || index == normalized.length - 1) {
      return normalized;
    }
    return normalized.substring(index + 1);
  }

  String _formatLastEdited(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 1) {
      return 'Edited just now';
    }
    if (difference.inHours < 1) {
      return 'Edited ${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    }
    if (difference.inDays < 1) {
      return 'Edited ${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    }
    return 'Edited ${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
  }
}
