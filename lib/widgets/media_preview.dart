import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../core/supabase_config.dart';
import '../core/theme.dart';
import '../models/content_item.dart';
import 'cover_image.dart';

/// Dirección del archivo principal para verlo o reproducirlo.
/// Primero intenta un enlace firmado (sirve con bucket público o privado);
/// si falla, usa el enlace público.
Future<String?> resolveMediaUrl(ContentItem item) async {
  final path = item.filePath;
  if (path == null || path.isEmpty) return null;
  try {
    return await db.storage.from('media').createSignedUrl(path, 3600);
  } catch (_) {
    return db.storage.from('media').getPublicUrl(path);
  }
}

String _fmt(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return h > 0 ? '$h:$m:$s' : '$m:$s';
}

/// Portada COMPLETA (sin recortar) centrada sobre un fondo desenfocado de la
/// misma imagen. Se ve bien con cualquier proporción de foto.
class _CoverFit extends StatelessWidget {
  final ContentItem item;
  final double height;
  final Widget? overlay;
  const _CoverFit({required this.item, this.height = 280, this.overlay});

  @override
  Widget build(BuildContext context) {
    final hasCover = item.coverUrl != null && item.coverUrl!.isNotEmpty;
    if (!hasCover) {
      return SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(fit: StackFit.expand, children: [
          CoverImage(item: item),
          if (overlay != null) overlay!,
        ]),
      );
    }
    return SizedBox(
      height: height,
      width: double.infinity,
      child: ClipRect(
        child: Stack(fit: StackFit.expand, children: [
          ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 28, sigmaY: 28),
            child: CoverImage(item: item, showIcon: false),
          ),
          const ColoredBox(color: Colors.black45),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: CoverImage(item: item, fit: BoxFit.contain, showIcon: false),
          ),
          if (overlay != null) overlay!,
        ]),
      ),
    );
  }
}

/// Zona superior del detalle: muestra/reproduce el contenido según su tipo.
class MediaPreview extends StatefulWidget {
  final ContentItem item;
  const MediaPreview({super.key, required this.item});

  @override
  State<MediaPreview> createState() => _MediaPreviewState();
}

class _MediaPreviewState extends State<MediaPreview> {
  late final Future<String?> _url = resolveMediaUrl(widget.item);

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return FutureBuilder<String?>(
      future: _url,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return _Loading(item: item);
        }
        final url = snap.data;
        if (url == null) {
          return _Problem(item: item, text: 'Este contenido no tiene archivo.');
        }
        switch (item.type) {
          case ContentType.image:
            return _ImagePreview(item: item, url: url);
          case ContentType.video:
            return _PlayerView(
                key: ValueKey(url), item: item, url: url, audio: false);
          case ContentType.audio:
            return _PlayerView(
                key: ValueKey(url), item: item, url: url, audio: true);
          case ContentType.pdf:
            return _PdfPreview(item: item, url: url);
        }
      },
    );
  }
}

// ------------------------------------------------------------ Estados

class _Loading extends StatelessWidget {
  final ContentItem item;
  const _Loading({required this.item});
  @override
  Widget build(BuildContext context) => _CoverFit(
        item: item,
        height: 260,
        overlay: const Center(child: CircularProgressIndicator()),
      );
}

class _Problem extends StatelessWidget {
  final ContentItem item;
  final String text;
  const _Problem({required this.item, required this.text});
  @override
  Widget build(BuildContext context) => _CoverFit(
        item: item,
        height: 260,
        overlay: Stack(fit: StackFit.expand, children: [
          const ColoredBox(color: Colors.black54),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      );
}

// ------------------------------------------------------------- Imagen

class _ImagePreview extends StatelessWidget {
  final ContentItem item;
  final String url;
  const _ImagePreview({required this.item, required this.url});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => _FullImageScreen(title: item.title, url: url),
      )),
      child: Container(
        color: Colors.black,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 420),
            child: Image.network(
              url,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => _CoverFit(item: item, height: 260),
              loadingBuilder: (_, child, progress) =>
                  progress == null ? child : _Loading(item: item),
            ),
          ),
        ),
      ),
    );
  }
}

class _FullImageScreen extends StatelessWidget {
  final String title;
  final String url;
  const _FullImageScreen({required this.title, required this.url});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(title: Text(title), backgroundColor: Colors.black),
        body: Center(
          child: InteractiveViewer(
            minScale: 1,
            maxScale: 5,
            child: Image.network(url, fit: BoxFit.contain),
          ),
        ),
      );
}

// ------------------------------------------------------ Video y música

class _PlayerView extends StatefulWidget {
  final ContentItem item;
  final String url;
  final bool audio;
  const _PlayerView(
      {super.key, required this.item, required this.url, required this.audio});

  @override
  State<_PlayerView> createState() => _PlayerViewState();
}

class _PlayerViewState extends State<_PlayerView> {
  late final VideoPlayerController _c;
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _c = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _c.initialize().then((_) {
      if (!mounted) return;
      setState(() => _ready = true);
      _c.play();
    }).catchError((_) {
      if (mounted) setState(() => _failed = true);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_c.value.isPlaying) {
      _c.pause();
    } else {
      _c.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return _Problem(
          item: widget.item,
          text: 'No se pudo reproducir el archivo. Revisa tu conexión.');
    }
    if (!_ready) return _Loading(item: widget.item);

    final ratio = _c.value.aspectRatio > 0 ? _c.value.aspectRatio : 16 / 9;
    final screen = widget.audio
        ? _CoverFit(item: widget.item, height: 300)
        : GestureDetector(
            onTap: _toggle,
            child: Container(
              color: Colors.black,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 420),
                  child: AspectRatio(
                      aspectRatio: ratio, child: VideoPlayer(_c)),
                ),
              ),
            ),
          );

    return Column(children: [screen, _Controls(c: _c)]);
  }
}

class _Controls extends StatefulWidget {
  final VideoPlayerController c;
  const _Controls({required this.c});

  @override
  State<_Controls> createState() => _ControlsState();
}

class _ControlsState extends State<_Controls> {
  double? _drag;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: widget.c,
      builder: (context, v, _) {
        final total = math.max(v.duration.inMilliseconds, 1).toDouble();
        final pos =
            (_drag ?? v.position.inMilliseconds.toDouble()).clamp(0.0, total);
        final ended = v.duration > Duration.zero &&
            v.position >= v.duration &&
            !v.isPlaying;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(children: [
            IconButton(
              iconSize: 34,
              onPressed: () {
                if (ended) {
                  widget.c.seekTo(Duration.zero);
                  widget.c.play();
                } else if (v.isPlaying) {
                  widget.c.pause();
                } else {
                  widget.c.play();
                }
              },
              icon: Icon(ended
                  ? Icons.replay_rounded
                  : (v.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded)),
            ),
            Expanded(
              child: Slider(
                value: pos,
                max: total,
                activeColor: AloColors.violet,
                onChanged: (x) => setState(() => _drag = x),
                onChangeEnd: (x) {
                  widget.c.seekTo(Duration(milliseconds: x.round()));
                  setState(() => _drag = null);
                },
              ),
            ),
            Text(
              '${_fmt(Duration(milliseconds: pos.round()))} / ${_fmt(v.duration)}',
              style: const TextStyle(fontSize: 11),
            ),
          ]),
        );
      },
    );
  }
}

// ---------------------------------------------------------------- PDF

class _PdfPreview extends StatelessWidget {
  final ContentItem item;
  final String url;
  const _PdfPreview({required this.item, required this.url});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _CoverFit(item: item, height: 300),
      Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => PdfViewerScreen(title: item.title, url: url),
              )),
              icon: const Icon(Icons.visibility_rounded),
              label: const Text('Ver PDF'),
              style: FilledButton.styleFrom(backgroundColor: AloColors.violet),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () =>
                  launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('Abrir fuera'),
            ),
          ),
        ]),
      ),
    ]);
  }
}

class PdfViewerScreen extends StatefulWidget {
  final String title;
  final String url;
  const PdfViewerScreen({super.key, required this.title, required this.url});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  late final WebViewController _wc;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    // Android no muestra PDF dentro del WebView; se usa el visor de Google.
    // iPhone lo muestra directamente.
    final target = defaultTargetPlatform == TargetPlatform.android
        ? 'https://docs.google.com/gview?embedded=true&url='
            '${Uri.encodeComponent(widget.url)}'
        : widget.url;
    _wc = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) {
          if (mounted) setState(() => _loading = false);
        },
      ))
      ..loadRequest(Uri.parse(target));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'Abrir fuera de la app',
            icon: const Icon(Icons.open_in_new_rounded),
            onPressed: () => launchUrl(Uri.parse(widget.url),
                mode: LaunchMode.externalApplication),
          ),
        ],
      ),
      body: Stack(children: [
        WebViewWidget(controller: _wc),
        if (_loading) const Center(child: CircularProgressIndicator()),
      ]),
    );
  }
}