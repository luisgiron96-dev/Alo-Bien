import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase_config.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../shell/main_shell.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: db.auth.onAuthStateChange,
      builder: (context, snap) {
        final session = snap.data?.session ?? db.auth.currentSession;
        if (session == null) return const LoginScreen();
        return _RoleLoader(key: ValueKey(session.user.id));
      },
    );
  }
}

class _RoleLoader extends StatefulWidget {
  const _RoleLoader({super.key});
  @override
  State<_RoleLoader> createState() => _RoleLoaderState();
}

class _RoleLoaderState extends State<_RoleLoader> {
  late Future<UserProfile?> _future = AuthService.loadProfile();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserProfile?>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final profile = snap.data;
        if (snap.hasError || profile == null) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: 12),
                  const Text('No pudimos cargar tu perfil.',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () =>
                        setState(() => _future = AuthService.loadProfile()),
                    child: const Text('Reintentar'),
                  ),
                  TextButton(
                    onPressed: AuthService.signOut,
                    child: const Text('Cerrar sesión'),
                  ),
                ]),
              ),
            ),
          );
        }
        return MainShell(profile: profile);
      },
    );
  }
}