import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

final databaseServiceProvider = Provider<DatabaseService>(
  (ref) => DatabaseService(),
);

class DatabaseService {
  DatabaseService({Directory? storageRootDirectory})
    : _storageRootDirectory = storageRootDirectory;

  final Directory? _storageRootDirectory;

  static const String idKey = 'id';
  static const String nameKey = 'name';
  static const String filePathKey = 'filePath';
  static const String lastEditedTimeKey = 'lastEditedTime';
  static const String thumbnailDataKey = 'thumbnailData';

  Future<List<Map<String, Object?>>> fetchCanvasMetadata() async {
    final entries = await _readMetadataEntries();
    entries.sort(_sortByLastEditedDescending);

    return entries
        .map((entry) => Map<String, Object?>.unmodifiable(entry))
        .toList(growable: false);
  }

  Future<void> insertCanvasMetadata(Map<String, Object?> values) async {
    final normalized = _normalizeMetadata(values);
    final entries = await _readMetadataEntries();
    _upsertEntry(entries, normalized);
    await _writeMetadataEntries(entries);
  }

  Future<void> deleteCanvasMetadata(String canvasId) async {
    final entries = await _readMetadataEntries();
    Map<String, Object?>? deletedEntry;

    entries.removeWhere((entry) {
      final matches = entry[idKey] == canvasId;
      if (matches) {
        deletedEntry = entry;
      }
      return matches;
    });

    await _writeMetadataEntries(entries);

    final deletedFilePath = deletedEntry?[filePathKey] as String?;
    if (deletedFilePath == null || deletedFilePath.isEmpty) {
      return;
    }

    final managedDraftsPath = (await _draftsDirectory()).path;
    if (!deletedFilePath.startsWith(managedDraftsPath)) {
      return;
    }

    final file = File(deletedFilePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<String> resolveDraftFilePath(String canvasId) async {
    final draftsDirectory = await _draftsDirectory();
    return '${draftsDirectory.path}${Platform.pathSeparator}$canvasId.mypt';
  }

  Future<String> persistCanvas({
    required String canvasId,
    required String name,
    String? filePath,
    required Uint8List canvasBytes,
    Uint8List? thumbnailData,
    DateTime? lastEditedTime,
    bool synchronous = false,
  }) async {
    final resolvedFilePath = filePath ?? await resolveDraftFilePath(canvasId);
    final metadata = _normalizeMetadata(<String, Object?>{
      idKey: canvasId,
      nameKey: name,
      filePathKey: resolvedFilePath,
      lastEditedTimeKey: (lastEditedTime ?? DateTime.now()).toIso8601String(),
      thumbnailDataKey: thumbnailData,
    });

    if (synchronous) {
      _writeCanvasBytesSync(resolvedFilePath, canvasBytes);
      _upsertMetadataSync(metadata);
      return resolvedFilePath;
    }

    await _writeCanvasBytes(resolvedFilePath, canvasBytes);
    await insertCanvasMetadata(metadata);
    return resolvedFilePath;
  }

  Future<Uint8List> readCanvasBytes(String filePath) async {
    return File(filePath).readAsBytes();
  }

  Future<List<Map<String, Object?>>> _readMetadataEntries() async {
    final file = await _metadataFile();
    if (!await file.exists()) {
      return <Map<String, Object?>>[];
    }

    final raw = await file.readAsString();
    if (raw.trim().isEmpty) {
      return <Map<String, Object?>>[];
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return <Map<String, Object?>>[];
    }

    return decoded
        .whereType<Map>()
        .map(
          (entry) => _normalizeMetadata(
            entry.map(
              (key, value) => MapEntry(key.toString(), value as Object?),
            ),
          ),
        )
        .toList();
  }

  Future<void> _writeMetadataEntries(List<Map<String, Object?>> entries) async {
    final file = await _metadataFile();
    entries.sort(_sortByLastEditedDescending);
    await file.writeAsString(jsonEncode(entries), flush: true);
  }

  void _upsertMetadataSync(Map<String, Object?> entry) {
    final file = _metadataFileSync();
    final entries = _readMetadataEntriesSync(file);
    _upsertEntry(entries, entry);
    entries.sort(_sortByLastEditedDescending);
    file.writeAsStringSync(jsonEncode(entries), flush: true);
  }

  List<Map<String, Object?>> _readMetadataEntriesSync(File file) {
    if (!file.existsSync()) {
      return <Map<String, Object?>>[];
    }

    final raw = file.readAsStringSync();
    if (raw.trim().isEmpty) {
      return <Map<String, Object?>>[];
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return <Map<String, Object?>>[];
    }

    return decoded
        .whereType<Map>()
        .map(
          (entry) => _normalizeMetadata(
            entry.map(
              (key, value) => MapEntry(key.toString(), value as Object?),
            ),
          ),
        )
        .toList();
  }

  void _upsertEntry(
    List<Map<String, Object?>> entries,
    Map<String, Object?> normalized,
  ) {
    final index = entries.indexWhere(
      (entry) => entry[idKey] == normalized[idKey],
    );
    if (index == -1) {
      entries.add(normalized);
      return;
    }

    entries[index] = normalized;
  }

  Map<String, Object?> _normalizeMetadata(Map<String, Object?> values) {
    final id = _stringValue(values[idKey]).trim();
    if (id.isEmpty) {
      throw ArgumentError.value(values[idKey], idKey, 'Canvas id is required.');
    }

    final primaryName = _stringValue(values[nameKey]).trim();
    final legacyTitle = _stringValue(values['title']).trim();
    final name = primaryName.isEmpty ? legacyTitle : primaryName;
    final filePath = _stringValue(values[filePathKey]);
    final lastEditedTime = _normalizeTimestamp(values[lastEditedTimeKey]);
    final thumbnailData = _normalizeThumbnail(values[thumbnailDataKey]);

    return <String, Object?>{
      idKey: id,
      nameKey: name.isEmpty ? 'Untitled' : name,
      filePathKey: filePath,
      lastEditedTimeKey: lastEditedTime,
      thumbnailDataKey: thumbnailData,
    };
  }

  String _normalizeTimestamp(Object? value) {
    if (value is DateTime) {
      return value.toIso8601String();
    }

    final text = _stringValue(value);
    if (text.isEmpty) {
      return DateTime.now().toIso8601String();
    }

    return DateTime.tryParse(text)?.toIso8601String() ??
        DateTime.now().toIso8601String();
  }

  String _normalizeThumbnail(Object? value) {
    if (value is Uint8List) {
      return base64Encode(value);
    }

    if (value is List<int>) {
      return base64Encode(Uint8List.fromList(value));
    }

    return _stringValue(value);
  }

  String _stringValue(Object? value) =>
      value is String ? value : value?.toString() ?? '';

  int _sortByLastEditedDescending(
    Map<String, Object?> left,
    Map<String, Object?> right,
  ) {
    final leftTime =
        DateTime.tryParse(_stringValue(left[lastEditedTimeKey])) ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final rightTime =
        DateTime.tryParse(_stringValue(right[lastEditedTimeKey])) ??
        DateTime.fromMillisecondsSinceEpoch(0);
    return rightTime.compareTo(leftTime);
  }

  Future<void> _writeCanvasBytes(String filePath, Uint8List bytes) async {
    final file = File(filePath);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
  }

  void _writeCanvasBytesSync(String filePath, Uint8List bytes) {
    final file = File(filePath);
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes, flush: true);
  }

  Future<File> _metadataFile() async {
    final directory = await _storageDirectory();
    return File(
      '${directory.path}${Platform.pathSeparator}project_history.json',
    );
  }

  File _metadataFileSync() {
    final directory = _storageDirectorySync();
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }
    return File(
      '${directory.path}${Platform.pathSeparator}project_history.json',
    );
  }

  Future<Directory> _draftsDirectory() async {
    final directory = await _storageDirectory();
    final drafts = Directory(
      '${directory.path}${Platform.pathSeparator}drafts',
    );
    if (!await drafts.exists()) {
      await drafts.create(recursive: true);
    }
    return drafts;
  }

  Future<Directory> _storageDirectory() async {
    final directory = _storageDirectorySync();
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  Directory _storageDirectorySync() {
    final configuredDirectory = _storageRootDirectory;
    if (configuredDirectory != null) {
      return configuredDirectory;
    }

    final basePath = Platform.environment['HOME']?.trim().isNotEmpty == true
        ? Platform.environment['HOME']!.trim()
        : Directory.current.path;
    final separator = Platform.pathSeparator;
    return Directory('$basePath$separator.bif_simple_paint');
  }
}
