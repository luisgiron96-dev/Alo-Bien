import 'package:flutter/material.dart';
import '../../core/supabase_config.dart';
import '../../core/theme.dart';
import '../../models/content_item.dart';
import '../../widgets/content_detail_sheet.dart';
import '../../widgets/cover_image.dart';

class CreatorDashboardScreen extends StatefulWidget {
  const CreatorDashboardScreen({super.key});
  @override
  State<CreatorDashboardScreen> createState() => _CreatorDashboardScreenState();
}

class _CreatorDashboardScreenState extends State<CreatorDashboardScreen> {
  late Future<List<ContentItem>> _future = _load();

  // El servidor solo devuelve borradores si el rol es 'creator' (RLS).
  Future<List<ContentItem>> _load() async {
    final rows =
        await db.from('content').select().order('created_at', ascending: false);
    return rows.map(ContentItem.fromMap).toList();
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<List<ContentItem>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return ListView(children: const [
              Padding(
                padding: EdgeInsets.all(32),
                child: Text('No pudimos cargar tus publicaciones.'),
              ),
            ]);
          }
          final items = snap.data ?? [];
          final published = items.where((i) => i.status == 'published').length;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Panel de creador',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 14),
              Row(children: [
                _Stat(label: 'Total', value: items.length),
                const SizedBox(width: 10),
                _Stat(label: 'Publicados', value: published),
                const SizedBox(width: 10),
                _Stat(label: 'Borradores', value: items.length - published),
              ]),
              const SizedBox(height: 20),
              const Text('Mis publicaciones',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('Aún no hay publicaciones.'),
                ),
              for (final item in items)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  onTap: () => showContentDetail(context, item),
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
                  subtitle: Text('${item.type.label} • ${item.dateLabel}'),
                  trailing: _StatusChip(published: item.status == 'published'),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final int value;
  const _Stat({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AloColors.bgDeep,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(children: [
            Text('$value',
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 12)),
          ]),
        ),
      );
}

class _StatusChip extends StatelessWidget {
  final bool published;
  const _StatusChip({required this.published});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: published ? AloColors.violet : Colors.white12,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(published ? 'Publicado' : 'Borrador',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
      );
}