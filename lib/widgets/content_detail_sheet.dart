import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/content_item.dart';
import 'content_card.dart';
import 'media_preview.dart';

void showContentDetail(BuildContext context, ContentItem item) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AloColors.bgDeep,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (ctx, controller) => ListView(
        controller: controller,
        children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
            child: MediaPreview(item: item),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  if (item.isNew) const NewBadge(),
                  _Chip(icon: item.section.icon, text: item.section.title),
                  if (item.price != null && item.price!.isNotEmpty)
                    _Chip(icon: Icons.sell_rounded, text: item.price!),
                  if (item.category != null && item.category!.isNotEmpty)
                    _Chip(icon: Icons.sell_rounded, text: item.category!),
                  _Chip(icon: Icons.event_rounded, text: item.dateLabel),
                ]),
                if (item.artist != null && item.artist!.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(item.artist!,
                      style: const TextStyle(
                          color: AloColors.lavender,
                          fontWeight: FontWeight.w600)),
                ],
                const SizedBox(height: 14),
                Text(
                  (item.description == null || item.description!.isEmpty)
                      ? 'Sin descripción.'
                      : item.description!,
                  style: const TextStyle(height: 1.5, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Chip({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: AloColors.lavender),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 12)),
        ]),
      );
}