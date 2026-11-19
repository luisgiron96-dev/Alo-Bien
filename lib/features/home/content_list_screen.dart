import 'package:flutter/material.dart';

import '../../models/content_item.dart';
import '../../widgets/content_card.dart';
import '../../widgets/content_detail_sheet.dart';

class ContentListScreen extends StatelessWidget {
  final String title;
  final List<ContentItem> items;
  const ContentListScreen({super.key, required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: items.isEmpty
          ? const Center(child: Text('No hay contenido todavía.'))
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 12,
                childAspectRatio: 0.52,
              ),
              itemCount: items.length,
              itemBuilder: (context, i) => ContentCard(
                item: items[i],
                onTap: () => showContentDetail(context, items[i]),
              ),
            ),
    );
  }
}