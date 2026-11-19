import 'package:flutter/material.dart';

import '../../core/supabase_config.dart';
import '../../core/theme.dart';
import '../../models/content_item.dart';
import '../../widgets/content_detail_sheet.dart';
import '../../widgets/cover_image.dart';
import 'upload_content_screen.dart';

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

  void _toast(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _openUpload() async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const UploadContentScreen()),
    );
    if (ok == true) {
      await _refresh();
      _toast('Publicación guardada.');
    }
  }

  Future<void> _setStatus(ContentItem item, bool publish) async {
    try {
      await db
          .from('content')
          .update({'status': publish ? 'published' : 'draft'}).eq('id', item.id);
      await _refresh();
      _toast(publish ? 'Contenido publicado.' : 'Contenido despublicado.');
    } catch (_) {
      _toast('No se pudo cambiar el estado.');
    }
  }

  Future<void> _delete(ContentItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar contenido'),
        content: Text('¿Eliminar "${item.title}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      if (item.filePath != null && item.filePath!.isNotEmpty) {
        await db.storage.from('media').remove([item.filePath!]);
      }
      if (item.coverPath != null && item.coverPath!.isNotEmpty) {
        await db.storage.from('covers').remove([item.coverPath!]);
      }
      await db.from('content').delete().eq('id', item.id);
      await _refresh();
      _toast('Contenido eliminado.');
    } catch (_) {
      _toast('No se pudo eliminar.');
    }
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
              FilledButton.icon(
                onPressed: _openUpload,
                icon: const Icon(Icons.cloud_upload_rounded),
                label: const Text('Subir contenido'),
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: AloColors.violet),
              ),
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
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    _StatusChip(published: item.status == 'published'),
                    PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'toggle') {
                          _setStatus(item, item.status != 'published');
                        } else if (v == 'delete') {
                          _delete(item);
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'toggle',
                          child: Text(item.status == 'published'
                              ? 'Despublicar'
                              : 'Publicar'),
                        ),
                        const PopupMenuItem(
                            value: 'delete', child: Text('Eliminar')),
                      ],
                    ),
                  ]),
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