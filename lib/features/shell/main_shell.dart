import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/user_profile.dart';
import '../../services/notifications_controller.dart';
import '../../services/push_service.dart';
import '../about/about_screen.dart';
import '../creator/creator_dashboard_screen.dart';
import '../home/home_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';
import '../profile/web_page_screen.dart';

class _Tab {
  final String label;
  final IconData icon;
  final Widget screen;
  const _Tab(this.label, this.icon, this.screen);
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

  @override
  void initState() {
    super.initState();
    // El panel de creador SOLO existe para el rol 'creator'.
    // La seguridad real la aplica Supabase (RLS), no esta pantalla.
    _tabs = [
      const _Tab('Inicio', Icons.home_rounded, HomeScreen()),
      const _Tab(
          'Novedades', Icons.notifications_rounded, NotificationsScreen()),
      const _Tab('Nosotros', Icons.info_rounded, AboutScreen()),
      if (widget.profile.isCreator)
        const _Tab('Panel', Icons.dashboard_rounded, CreatorDashboardScreen()),
      _Tab('Perfil', Icons.person_rounded,
          ProfileScreen(profile: widget.profile)),
    ];
    NotificationsController.instance.start();
    PushService.instance.pendingLink.addListener(_openPush);
    PushService.instance.foregroundMessage.addListener(_showForeground);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PushService.instance.requestPermissionAndSubscribe();
      _openPush();
    });
  }

  @override
  void dispose() {
    PushService.instance.pendingLink.removeListener(_openPush);
    PushService.instance.foregroundMessage.removeListener(_showForeground);
    NotificationsController.instance.stop();
    super.dispose();
  }

  void _openPush() {
    final u = PushService.instance.pendingLink.value;
    if (u == null || !mounted) return;
    PushService.instance.pendingLink.value = null;
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
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/images/logo.png',
          height: 32,
          errorBuilder: (_, __, ___) => const Text('ALO BIEN',
              style: TextStyle(fontWeight: FontWeight.w800)),
        ),
        actions: [
          if (widget.profile.isCreator)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Chip(
                label: Text('CREADOR', style: TextStyle(fontSize: 10)),
                visualDensity: VisualDensity.compact,
                backgroundColor: AloColors.violet,
              ),
            ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: [for (final t in _tabs) t.screen],
      ),
      bottomNavigationBar: ListenableBuilder(
        listenable: NotificationsController.instance,
        builder: (context, _) {
          final unread = NotificationsController.instance.unread;
          return NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
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
    );
  }
}