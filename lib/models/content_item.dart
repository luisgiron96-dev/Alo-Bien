import 'package:flutter/material.dart';
import '../core/supabase_config.dart';

enum ContentType { video, audio, image, pdf }

ContentType contentTypeFromDb(String? s) => ContentType.values
    .firstWhere((t) => t.name == s, orElse: () => ContentType.video);

extension ContentTypeX on ContentType {
  String get label => switch (this) {
        ContentType.video => 'Video',
        ContentType.audio => 'Música',
        ContentType.image => 'Imagen',
        ContentType.pdf => 'Documento PDF',
      };

  String get rowTitle => switch (this) {
        ContentType.video => 'Videos',
        ContentType.audio => 'Música',
        ContentType.image => 'Imágenes y galerías',
        ContentType.pdf => 'Documentos PDF',
      };

  IconData get icon => switch (this) {
        ContentType.video => Icons.play_circle_rounded,
        ContentType.audio => Icons.music_note_rounded,
        ContentType.image => Icons.image_rounded,
        ContentType.pdf => Icons.picture_as_pdf_rounded,
      };
}

class ContentItem {
  /// Cuánto tiempo se considera "nuevo" un contenido.
  static const newWindow = Duration(days: 7);

  final String id;
  final ContentType type;
  final String title;
  final String? description;
  final String? category;
  final String? artist;
  final String? filePath;
  final String? coverPath;
  final int? durationSeconds;
  final bool featured;
  final String status;
  final DateTime? publishedAt;

  const ContentItem({
    required this.id,
    required this.type,
    required this.title,
    this.description,
    this.category,
    this.artist,
    this.filePath,
    this.coverPath,
    this.durationSeconds,
    this.featured = false,
    this.status = 'draft',
    this.publishedAt,
  });

  factory ContentItem.fromMap(Map<String, dynamic> m) => ContentItem(
        id: m['id'] as String,
        type: contentTypeFromDb(m['type'] as String?),
        title: (m['title'] ?? '') as String,
        description: m['description'] as String?,
        category: m['category'] as String?,
        artist: m['artist'] as String?,
        filePath: m['file_path'] as String?,
        coverPath: m['cover_path'] as String?,
        durationSeconds: m['duration_seconds'] as int?,
        featured: (m['featured'] ?? false) as bool,
        status: (m['status'] ?? 'draft') as String,
        publishedAt: m['published_at'] == null
            ? null
            : DateTime.parse(m['published_at'] as String).toLocal(),
      );

  bool get isNew =>
      publishedAt != null &&
      DateTime.now().difference(publishedAt!) < newWindow;

  String? get coverUrl => (coverPath == null || coverPath!.isEmpty)
      ? null
      : db.storage.from('covers').getPublicUrl(coverPath!);

  String get dateLabel {
    final d = publishedAt;
    if (d == null) return 'Sin publicar';
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}