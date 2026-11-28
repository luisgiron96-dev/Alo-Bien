import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_config.dart';
import '../models/content_item.dart';

class ContentRepository {
  /// Carga única del contenido publicado.
  static Future<List<ContentItem>> fetchPublished() async {
    final rows = await db
        .from('content')
        .select()
        .eq('status', 'published')
        .order('published_at', ascending: false);
    return rows.map(ContentItem.fromMap).toList();
  }

  /// Un contenido por su id (por ejemplo, desde una notificación push).
  static Future<ContentItem?> byId(String id) async {
    final row = await db.from('content').select().eq('id', id).maybeSingle();
    return row == null ? null : ContentItem.fromMap(row);
  }

  /// Canal en tiempo real SIN filtro. El stream con `.eq('status', ...)` no
  /// recibe los eventos DELETE (Supabase no puede filtrarlos), por eso el
  /// contenido eliminado seguía apareciendo en Inicio. Aquí escuchamos
  /// insert/update/delete y el llamador recarga la lista.
  static RealtimeChannel subscribeChanges(void Function() onChange) {
    return db
        .channel('home-content-${DateTime.now().microsecondsSinceEpoch}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'content',
          callback: (_) => onChange(),
        )
        .subscribe();
  }
}