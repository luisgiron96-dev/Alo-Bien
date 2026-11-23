import 'package:flutter/material.dart';
import '../core/supabase_config.dart';

enum ContentType { video, audio, image, pdf }

/// Sección de la app donde se muestra un contenido. Cada contenido vive en
/// UNA sola sección (la que elige el creador al subirlo), así no se repite.
/// El orden de este enum es el orden en que aparecen en el Inicio.
enum ContentSection {
  destacado('destacado', 'Contenido destacado', Icons.star_rounded),
  producto('productos', 'Productos', Icons.shopping_bag_rounded),
  novedades('novedades', 'Novedades', Icons.fiber_new_rounded),
  video('videos', 'Videos', Icons.play_circle_rounded),
  musica('musica', 'Música', Icons.music_note_rounded),
  imagen('imagenes', 'Imágenes y galerías', Icons.image_rounded),
  pdf('pdf', 'Documentos PDF', Icons.picture_as_pdf_rounded);

  /// Valor guardado en la columna `section` de Supabase.
  final String db;
  final String title;
  final IconData icon;
  const ContentSection(this.db, this.title, this.icon);

  /// Tipos de archivo que se pueden subir en esta sección.
  List<ContentType> get allowedTypes => switch (this) {
        ContentSection.destacado ||
        ContentSection.novedades =>
          ContentType.values,
        ContentSection.producto || ContentSection.imagen => [ContentType.image],
        ContentSection.video => [ContentType.video],
        ContentSection.musica => [ContentType.audio],
        ContentSection.pdf => [ContentType.pdf],
      };

  static ContentSection? fromDb(String? s) {
    for (final v in ContentSection.values) {
      if (v.db == s) return v;
    }
    return null;
  }

  /// Sección por defecto para contenido antiguo que aún no tiene `section`.
  static ContentSection fallback(ContentType type, bool featured) {
    if (featured) return ContentSection.destacado;
    return switch (type) {
      ContentType.video => ContentSection.video,
      ContentType.audio => ContentSection.musica,
      ContentType.image => ContentSection.imagen,
      ContentType.pdf => ContentSection.pdf,
    };
  }
}

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
  final ContentSection section;
  final String? price;
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
    required this.section,
    this.price,
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

  factory ContentItem.fromMap(Map<String, dynamic> m) {
    final type = contentTypeFromDb(m['type'] as String?);
    final legacyFeatured = (m['featured'] ?? false) as bool;
    final section = ContentSection.fromDb(m['section'] as String?) ??
        ContentSection.fallback(type, legacyFeatured);
    return ContentItem(
      id: m['id'] as String,
      type: type,
      section: section,
      price: m['price'] as String?,
      title: (m['title'] ?? '') as String,
      description: m['description'] as String?,
      category: m['category'] as String?,
      artist: m['artist'] as String?,
      filePath: m['file_path'] as String?,
      coverPath: m['cover_path'] as String?,
      durationSeconds: m['duration_seconds'] as int?,
      featured: section == ContentSection.destacado,
      status: (m['status'] ?? 'draft') as String,
      publishedAt: m['published_at'] == null
          ? null
          : DateTime.parse(m['published_at'] as String).toLocal(),
    );
  }

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