import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/config.dart';
import '../../core/theme.dart';
import '../../services/push_service.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late final WebViewController _c;
  int _tab = 0;
  bool _loading = true;
  bool _error = false;
  Uri _current = AppConfig.tabs[0].uri;

  @override
  void initState() {
    super.initState();
    final pending = PushService.instance.pendingLink.value;
    if (pending != null) {
      _current = pending;
      _tab = AppConfig.tabFor(pending) ?? 0;
      PushService.instance.pendingLink.value = null;
    }
    _c = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AloColors.bg)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => setState(() {
          _loading = true;
          _error = false;
        }),
        onPageFinished: (_) => setState(() => _loading = false),
        onWebResourceError: (e) {
          if (e.isForMainFrame ?? true) {
            setState(() {
              _error = true;
              _loading = false;
            });
          }
        },
        onNavigationRequest: _onNavigation,
      ))
      ..loadRequest(_current);

    PushService.instance.pendingLink.addListener(_openPending);
    PushService.instance.foregroundMessage.addListener(_showForeground);
    // Permiso de notificaciones tras el primer frame.
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => PushService.instance.requestPermissionAndSubscribe());
  }

  @override
  void dispose() {
    PushService.instance.pendingLink.removeListener(_openPending);
    PushService.instance.foregroundMessage.removeListener(_showForeground);
    super.dispose();
  }

  NavigationDecision _onNavigation(NavigationRequest r) {
    if (!r.isMainFrame) return NavigationDecision.navigate;
    final uri = Uri.tryParse(r.url);
    if (uri == null) return NavigationDecision.prevent;
    if (AppConfig.isInternal(uri)) return NavigationDecision.navigate;
    // Enlaces externos (WhatsApp, redes, mailto, tel...) fuera de la app.
    launchUrl(uri, mode: LaunchMode.externalApplication);
    return NavigationDecision.prevent;
  }

  void _openUri(Uri u) {
    final t = AppConfig.tabFor(u);
    setState(() {
      if (t != null) _tab = t;
      _error = false;
    });
    _current = u;
    _c.loadRequest(u);
  }

  void _openPending() {
    final u = PushService.instance.pendingLink.value;
    if (u == null) return;
    PushService.instance.pendingLink.value = null;
    _openUri(u);
  }

  void _showForeground() {
    final m = PushService.instance.foregroundMessage.value;
    if (m == null || !mounted) return;
    final link = AppConfig.safeLink(m.data['url'] as String?);
    final text =
        m.notification?.title ?? m.notification?.body ?? 'Novedad en ALO BIEN';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(text),
        action: link == null
            ? null
            : SnackBarAction(label: 'VER', onPressed: () => _openUri(link)),
      ));
  }

  Future<void> _onBack(bool didPop, Object? _) async {
    if (didPop) return;
    if (await _c.canGoBack()) {
      await _c.goBack();
    } else {
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _onBack,
      child: Scaffold(
        appBar: AppBar(
          title: Image.asset(
            'assets/images/logo.png',
            height: 32,
            errorBuilder: (_, __, ___) => const Text('ALO BIEN',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
          actions: [
            PopupMenuButton<Section>(
              icon: const Icon(Icons.more_vert),
              onSelected: (s) => _openUri(s.uri),
              itemBuilder: (_) => [
                for (final s in AppConfig.extra)
                  PopupMenuItem(value: s, child: Text(s.label)),
              ],
            ),
          ],
          bottom: _loading
              ? const PreferredSize(
                  preferredSize: Size.fromHeight(2),
                  child: LinearProgressIndicator(minHeight: 2),
                )
              : null,
        ),
        body: _error
            ? _OfflineView(onRetry: () => _c.loadRequest(_current))
            : WebViewWidget(controller: _c),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (i) => _openUri(AppConfig.tabs[i].uri),
          destinations: [
            for (final s in AppConfig.tabs)
              NavigationDestination(icon: Icon(s.icon), label: s.label),
          ],
        ),
      ),
    );
  }
}

class _OfflineView extends StatelessWidget {
  final VoidCallback onRetry;
  const _OfflineView({required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.wifi_off_rounded,
                size: 56, color: AloColors.lavender),
            const SizedBox(height: 16),
            const Text('No pudimos cargar ALO BIEN',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('Revisa tu conexión a internet e inténtalo de nuevo.',
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
          ]),
        ),
      );
}