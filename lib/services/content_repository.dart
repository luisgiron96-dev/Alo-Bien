import '../core/supabase_config.dart';
import '../models/content_item.dart';

class ContentRepository {
  /// Contenido publicado en tiempo real: cuando el creador publica,
  /// aparece en la app sin reabrirla.
  static Stream<List<ContentItem>> watchPublished() => db
      .from('content')
      .stream(primaryKey: ['id'])
      .eq('status', 'published')
      .order('published_at', ascending: false)
      .map((rows) => rows.map(ContentItem.fromMap).toList());
}