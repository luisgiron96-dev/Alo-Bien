import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/content_item.dart';
import '../../services/notifications_controller.dart';
import '../../widgets/content_detail_sheet.dart';
import '../../widgets/cover_image.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = NotificationsController.instance;
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 4),
              child: Row(children: [
                const Expanded(
                  child: Text('Novedades',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                ),
                TextButton(
                  onPressed: c.unread == 0 ? null : c.markAllRead,
                  child: const Text('Marcar como leídas'),
                ),
              ]),
            ),
            Expanded(
              child: c.items.isEmpty
                  ? const Center(child: Text('No hay novedades todavía.'))
                  : RefreshIndicator(
                      onRefresh: c.load,
                      child: ListView.builder(
                        itemCount: c.items.length,
                        itemBuilder: (context, i) {
                          final n = c.items[i];
                          final ContentItem item = n.content;
                          final d = n.createdAt;
                          final date =
                              '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
                          return ListTile(
                            onTap: () {
                              c.markRead(n);
                              showContentDetail(context, item);
                            },
                            leading: SizedBox(
                              width: 52,
                              height: 52,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: CoverImage(item: item),
                              ),
                            ),
                            title: Text(item.title,
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text('Nuevo ${item.type.label} • $date'),
                            trailing: n.read
                                ? null
                                : const Icon(Icons.circle,
                                    size: 10, color: AloColors.lavender),
                          );
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}