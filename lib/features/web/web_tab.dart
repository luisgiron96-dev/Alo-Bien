import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/config.dart';
import '../../core/theme.dart';

/// Página del sitio dentro de una pestaña de la app.
/// La sesión del sitio (cookies) se conserva entre aperturas.
class WebTab extends StatefulWidget {
  final Uri uri;
  const WebTab({super.key, required this.uri});

  @override
  State<WebTab> createState() => WebTabState();
}

class WebTabState extends State<WebTab> {
  late final WebViewController _c;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _c = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AloColors.bg)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) {
          if (mounted) {
            setState(() {
              _loading = true;
              _failed = false;
            });
          }
        },
        onPageFinished: (_) {
          if (mounted) setState(() => _loading = false);
        },
        onWebResourceError: (e) {
          if ((e.isForMainFrame ?? true) && mounted) {
            setState(() {
              _failed = true;
              _loading = false;
            });
          }
        },
        onNavigationRequest: (r) {
          if (!r.isMainFrame) return NavigationDecision.navigate;
          final u = Uri.tryParse(r.url);
          if (u == null) return NavigationDecision.prevent;
          if (AppConfig.isInternal(u)) return NavigationDecision.navigate;
          // tel:, mailto:, WhatsApp, redes sociales, etc. se abren fuera.
          launchUrl(u, mode: LaunchMode.externalApplication);
          return NavigationDecision.prevent;
        },
      ))
      ..loadRequest(widget.uri);
  }

  /// Retrocede dentro del sitio. Devuelve false si ya está en la primera página.
  Future<bool> goBackIfPossible() async {
    if (await _c.canGoBack()) {
      await _c.goBack();
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Positioned.fill(child: WebViewWidget(controller: _c)),
      if (_loading)
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: LinearProgressIndicator(minHeight: 2),
        ),
      if (_failed)
        Positioned.fill(
          child: ColoredBox(
            color: AloColors.bg,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.wifi_off_rounded, size: 48),
                  const SizedBox(height: 12),
                  const Text('No se pudo cargar la página.',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  const Text('Revisa tu conexión e inténtalo de nuevo.',
                      textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => _c.loadRequest(widget.uri),
                    child: const Text('Reintentar'),
                  ),
                ]),
              ),
            ),
          ),
        ),
    ]);
  }
}