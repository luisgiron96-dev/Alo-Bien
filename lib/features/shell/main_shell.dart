import 'package:flutter/material.dart';

import '../../core/config.dart';
import '../../core/theme.dart';
import '../../models/user_profile.dart';
import '../../services/content_repository.dart';
import '../../services/notifications_controller.dart';
import '../../services/push_service.dart';
import '../../widgets/alo_logo.dart';
import '../../widgets/content_detail_sheet.dart';
import '../home/home_screen.dart';
import '../more/more_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/web_page_screen.dart';
import '../web/web_tab.dart';

class _Tab {
  final String label;
  final IconData icon;
  final Widget Function() build;
  const _Tab(this.label, this.icon, this.build);
}

class MainShell extends StatefulWidget {
  final UserProfile profile;
  const MainShell({super.key, required this.profile});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  late final List<_Tab> _tabs;

  // Las pestañas se crean la primera vez que se visitan (las web pesan).
  final Set<int> _visited = {0};

  // Para que el botón "atrás" retroceda dentro de la web de cada pestaña.
  final Map<int, GlobalKey<WebTabState>> _webKeys = {
    2: GlobalKey<WebTabState>(),
    3: GlobalKey<WebTabState>(),
  };

  @override
  void initState() {
    super.initState();
    // Pestañas: nativas (Inicio, Novedades, Más) + páginas del sitio
    // (Comunidad, Tienda). El panel de creador vive dentro de "Más" y solo
    // existe para el rol 'creator'; la seguridad real la aplica Supabase (RLS).
    _tabs = [
      _Tab('Inicio', Icons.home_rounded, () => const HomeScreen()),
      _Tab('Novedades', Icons.notifications_rounded,
          () => const NotificationsScreen()),
      _Tab(
          AppConfig.tabs[2].label,
          AppConfig.tabs[2].icon,
          () => WebTab(key: _webKeys[2], uri: AppConfig.tabs[2].uri)),
      _Tab(
          AppConfig.tabs[3].label,
          AppConfig.tabs[3].icon,
          () => WebTab(key: _webKeys[3], uri: AppConfig.tabs[3].uri)),
      _Tab('Más', Icons.menu_rounded,
          () => MoreScreen(profile: widget.profile)),
    ];
    NotificationsController.instance.start();
    PushService.instance.pendingLink.addListener(_openPush);
    PushService.instance.pendingContentId.addListener(_openPush);
    PushService.instance.foregroundMessage.addListener(_showForeground);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PushService.instance.requestPermissionAndSubscribe();
      _openPush();
    });
  }

  @override
  void dispose() {
    PushService.instance.pendingLink.removeListener(_openPush);
    PushService.instance.pendingContentId.removeListener(_openPush);
    PushService.instance.foregroundMessage.removeListener(_showForeground);
    NotificationsController.instance.stop();
    super.dispose();
  }

  /// Toque en una notificación: abre el contenido de la app o la página del sitio.
  Future<void> _openPush() async {
    if (!mounted) return;
    final push = PushService.instance;

    final id = push.pendingContentId.value;
    if (id != null) {
      push.pendingContentId.value = null;
      try {
        final item = await ContentRepository.byId(id);
        if (item != null && mounted) {
          push.pendingLink.value = null;
          showContentDetail(context, item);
          return;
        }
      } catch (_) {
        // Si no se pudo cargar, se intenta con el enlace del sitio.
      }
    }

    final u = push.pendingLink.value;
    if (u == null || !mounted) return;
    push.pendingLink.value = null;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => WebPageScreen(title: 'ALO BIEN', uri: u),
    ));
  }

  void _showForeground() {
    final m = PushService.instance.foregroundMessage.value;
    if (m == null || !mounted) return;
    final text =
        m.notification?.title ?? m.notification?.body ?? 'Novedad en ALO BIEN';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(text),
        action: PushService.instance.hasTarget(m)
            ? SnackBarAction(
                label: 'Ver',
                onPressed: () => PushService.instance.handleTap(m),
              )
            : null,
      ));
  }

  Future<void> _onBack(bool didPop) async {
    if (didPop) return;
    // Primero retrocede dentro de la página web de la pestaña (si la hay).
    final handled =
        await _webKeys[_index]?.currentState?.goBackIfPossible() ?? false;
    if (!handled && mounted) setState(() => _index = 0);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) => _onBack(didPop),
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 64,
          title: const AloLogo(height: 34, alignment: Alignment.centerLeft),
          actions: [
            if (widget.profile.isCreator)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AloColors.indicator,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: const Color(0xCCFFFFFF), width: 1.5),
                  ),
                  child: const Text('CREADOR',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5)),
                ),
              ),
          ],
        ),
        body: IndexedStack(
          index: _index,
          children: [
            for (var i = 0; i < _tabs.length; i++)
              _visited.contains(i) ? _tabs[i].build() : const SizedBox.shrink(),
          ],
        ),
        bottomNavigationBar: ListenableBuilder(
          listenable: NotificationsController.instance,
          builder: (context, _) {
            final unread = NotificationsController.instance.unread;
            return NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (i) {
                setState(() {
                  _index = i;
                  _visited.add(i);
                });
                // Al entrar a Novedades se marcan como vistas.
                if (_tabs[i].label == 'Novedades') {
                  NotificationsController.instance.markAllRead();
                }
              },
              destinations: [
                for (final t in _tabs)
                  NavigationDestination(
                    icon: t.label == 'Novedades'
                        ? Badge(
                            isLabelVisible: unread > 0,
                            label: Text('$unread'),
                            child: Icon(t.icon),
                          )
                        : Icon(t.icon),
                    label: t.label,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}