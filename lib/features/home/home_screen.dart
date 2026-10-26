import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/content_item.dart';
import '../../services/content_repository.dart';
import '../../widgets/content_card.dart';
import '../../widgets/content_detail_sheet.dart';
import '../../widgets/cover_image.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ContentItem>>(
      stream: ContentRepository.watchPublished(),
      builder: (context, snap) {
        if (snap.hasError) {
          return const _Message(
              icon: Icons.wifi_off_rounded,
              text: 'No pudimos cargar el contenido. Revisa tu conexión.');
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snap.data!;
        if (items.isEmpty) {
          return const _Message(
              icon: Icons.movie_outlined,
              text: 'Aún no hay contenido publicado.');
        }
        final hero = items.firstWhere((i) => i.featured, orElse: () => items.first);
        final rows = <(String, List<ContentItem>)>[
          ('Novedades', items.where((i) => i.isNew).toList()),
          for (final t in ContentType.values)
            (t.rowTitle, items.where((i) => i.type == t).toList()),
        ].where((r) => r.$2.isNotEmpty).toList();

        return ListView(
          padding: EdgeInsets.zero,
          children: [
            _Hero(item: hero),
            for (final r in rows) _Row(title: r.$1, items: r.$2),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }
}

class _Hero extends StatelessWidget {
  final ContentItem item;
  const _Hero({required this.item});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 380,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CoverImage(item: item),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, AloColors.bg],
                begin: Alignment.center,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  if (item.isNew) ...[const NewBadge(), const SizedBox(width: 8)],
                  Text(
                    (item.category != null && item.category!.isNotEmpty)
                        ? item.category!
                        : item.type.label,
                    style: const TextStyle(
                        color: AloColors.lavender, fontWeight: FontWeight.w700),
                  ),
                ]),
                const SizedBox(height: 8),
                Text(item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 26, fontWeight: FontWeight.w800)),
                if (item.description != null && item.description!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(item.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70)),
                ],
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: () => showContentDetail(context, item),
                  icon: const Icon(Icons.info_outline_rounded),
                  label: const Text('Ver detalles'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String title;
  final List<ContentItem> items;
  const _Row({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
          child: Text(title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        ),
        SizedBox(
          height: 256,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) => ContentCard(
              item: items[i],
              onTap: () => showContentDetail(context, items[i]),
            ),
          ),
        ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Message({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 52, color: AloColors.lavender),
            const SizedBox(height: 14),
            Text(text, textAlign: TextAlign.center),
          ]),
        ),
      );
}