import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_config.dart';
import '../models/content_item.dart';

class AppNotification {
  final String id;
  final DateTime createdAt;
  final ContentItem content;
  final bool read;
  const AppNotification({
    required this.id,
    required this.createdAt,
    required this.content,
    required this.read,
  });
}

class NotificationsController extends ChangeNotifier {
  NotificationsController._();
  static final instance = NotificationsController._();

  List<AppNotification> items = [];
  RealtimeChannel? _channel;

  int get unread => items.where((n) => !n.read).length;

  Future<void> start() async {
    await load();
    _channel ??= db
        .channel('public:notifications')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          callback: (_) => load(),
        )
        .subscribe();
  }

  void stop() {
    if (_channel != null) {
      db.removeChannel(_channel!);
      _channel = null;
    }
    items = [];
  }

  Future<void> load() async {
    try {
      final notifs = await db
          .from('notifications')
          .select('id, created_at, content(*)')
          .order('created_at', ascending: false)
          .limit(50);
      final reads = await db.from('notification_reads').select('notification_id');
      final readIds = reads.map((r) => r['notification_id'] as String).toSet();
      items = [
        for (final n in notifs)
          if (n['content'] != null)
            AppNotification(
              id: n['id'] as String,
              createdAt: DateTime.parse(n['created_at'] as String).toLocal(),
              content:
                  ContentItem.fromMap(n['content'] as Map<String, dynamic>),
              read: readIds.contains(n['id']),
            ),
      ];
      notifyListeners();
    } catch (e) {
      debugPrint('Error cargando notificaciones: $e');
    }
  }

  /// Marca como leídas las notificaciones indicadas (o todas las pendientes).
  /// Actualiza la pantalla al instante (el globo rojo desaparece) y luego
  /// guarda en Supabase.
  Future<void> markAllRead() => _markRead(items.where((n) => !n.read).toList());

  Future<void> markRead(AppNotification n) async {
    if (n.read) return;
    await _markRead([n]);
  }

  Future<void> _markRead(List<AppNotification> targets) async {
    final uid = db.auth.currentUser?.id;
    if (uid == null || targets.isEmpty) return;
    final ids = targets.map((n) => n.id).toSet();

    // 1) Cambio inmediato en pantalla.
    items = [
      for (final n in items)
        if (ids.contains(n.id))
          AppNotification(
              id: n.id, createdAt: n.createdAt, content: n.content, read: true)
        else
          n,
    ];
    notifyListeners();

    // 2) Se guarda en la base de datos.
    try {
      await db.from('notification_reads').upsert(
            [for (final id in ids) {'user_id': uid, 'notification_id': id}],
            onConflict: 'user_id,notification_id',
            ignoreDuplicates: true,
          );
    } catch (e) {
      debugPrint('Error marcando como leídas: $e');
    }
  }
}
