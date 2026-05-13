import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final documentFileServiceProvider = Provider<DocumentFileService>(
  (ref) => const MethodChannelDocumentFileService(),
);

class DocumentFileReference {
  const DocumentFileReference({
    required this.uri,
    required this.displayName,
    this.bytes,
  });

  final String uri;
  final String displayName;
  final Uint8List? bytes;

  factory DocumentFileReference.fromMap(Map<Object?, Object?> map) {
    final rawBytes = map['bytes'];
    return DocumentFileReference(
      uri: map['uri'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      bytes: rawBytes is Uint8List ? rawBytes : null,
    );
  }
}

abstract class DocumentFileService {
  Future<bool> isSupported();

  Future<DocumentFileReference?> openDocument();

  Future<DocumentFileReference?> createDocument({
    required String suggestedFileName,
    required Uint8List bytes,
  });

  Future<DocumentFileReference> readDocument(String uri);

  Future<void> writeDocument({required String uri, required Uint8List bytes});
}

class MethodChannelDocumentFileService implements DocumentFileService {
  const MethodChannelDocumentFileService();

  static const MethodChannel _channel = MethodChannel(
    'com.bif.paint.bif_simple_paint/document_file',
  );

  @override
  Future<bool> isSupported() async {
    try {
      final result = await _channel.invokeMethod<bool>('isSupported');
      return result ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  @override
  Future<DocumentFileReference?> openDocument() async {
    try {
      final result = await _channel.invokeMapMethod<Object?, Object?>(
        'openDocument',
      );
      if (result == null) {
        return null;
      }
      return DocumentFileReference.fromMap(result);
    } on MissingPluginException {
      return null;
    }
  }

  @override
  Future<DocumentFileReference?> createDocument({
    required String suggestedFileName,
    required Uint8List bytes,
  }) async {
    try {
      final result = await _channel.invokeMapMethod<Object?, Object?>(
        'createDocument',
        <String, Object?>{
          'suggestedFileName': suggestedFileName,
          'bytes': bytes,
        },
      );
      if (result == null) {
        return null;
      }
      return DocumentFileReference.fromMap(result);
    } on MissingPluginException {
      return null;
    }
  }

  @override
  Future<DocumentFileReference> readDocument(String uri) async {
    try {
      final result = await _channel.invokeMapMethod<Object?, Object?>(
        'readDocument',
        <String, Object?>{'uri': uri},
      );
      if (result == null) {
        throw StateError('Document read returned no payload.');
      }
      return DocumentFileReference.fromMap(result);
    } on MissingPluginException {
      throw UnsupportedError('Document file service is unavailable.');
    }
  }

  @override
  Future<void> writeDocument({
    required String uri,
    required Uint8List bytes,
  }) async {
    try {
      await _channel.invokeMethod<void>('writeDocument', <String, Object?>{
        'uri': uri,
        'bytes': bytes,
      });
    } on MissingPluginException {
      throw UnsupportedError('Document file service is unavailable.');
    }
  }
}
