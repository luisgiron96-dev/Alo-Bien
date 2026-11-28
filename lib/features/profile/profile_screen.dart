import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  final UserProfile profile;
  const ProfileScreen({super.key, required this.profile});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _maxBytes = 5 * 1024 * 1024; // 5 MB
  late UserProfile profile = widget.profile;
  bool _busy = false;

  void _toast(String t) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(t)));
  }

  Future<void> _changePhoto() async {
    // Abre la galería del celular para ver y elegir tus fotos.
    final XFile? x;
    try {
      x = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
    } catch (_) {
      _toast('No se pudo abrir la galería.');
      return;
    }
    if (x == null) return;
    final ext = x.name.contains('.') ? x.name.split('.').last.toLowerCase() : '';
    if (!const ['jpg', 'jpeg', 'png', 'webp'].contains(ext)) {
      _toast('Elige una foto JPG, PNG o WebP.');
      return;
    }
    if (await x.length() > _maxBytes) {
      _toast('La foto pesa demasiado. El máximo es 5 MB.');
      return;
    }
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Vista previa'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          CircleAvatar(
            radius: 80,
            backgroundImage: FileImage(File(x!.path)),
          ),
          const SizedBox(height: 12),
          const Text('¿Usar esta foto de perfil?'),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Guardar')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      final path = await AuthService.uploadAvatar(
        uid: profile.id,
        file: File(x.path),
        ext: ext,
        oldPath: profile.avatarPath,
      );
      if (!mounted) return;
      setState(() => profile = profile.copyWith(avatarPath: path));
      _toast('Foto actualizada.');
    } on StorageException catch (e) {
      _toast('No se pudo subir la foto: ${e.message}');
    } on PostgrestException catch (e) {
      _toast('No se pudo guardar en tu perfil: ${e.message}');
    } catch (e) {
      debugPrint('Error foto de perfil: $e');
      _toast('No se pudo guardar la foto ($e).');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _viewPhoto() {
    final url = profile.avatarUrl;
    if (url == null) return;
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Text(profile.displayName),
        ),
        body: Center(
          child: InteractiveViewer(
            minScale: 1,
            maxScale: 5,
            child: Image.network(
              url,
              fit: BoxFit.contain,
              loadingBuilder: (_, child, p) => p == null
                  ? child
                  : const Center(child: CircularProgressIndicator()),
              errorBuilder: (_, __, ___) => const Text(
                  'No se pudo cargar la foto.',
                  style: TextStyle(color: Colors.white70)),
            ),
          ),
        ),
      ),
    ));
  }

  Future<void> _removePhoto() async {
    setState(() => _busy = true);
    try {
      await AuthService.removeAvatar(
          uid: profile.id, path: profile.avatarPath);
      if (!mounted) return;
      setState(() => profile = profile.copyWith(clearAvatar: true));
      _toast('Foto eliminada.');
    } catch (_) {
      _toast('No se pudo eliminar la foto.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _photoMenu() {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (profile.avatarUrl != null)
            ListTile(
              leading: const Icon(Icons.zoom_in_rounded),
              title: const Text('Ver foto'),
              onTap: () {
                Navigator.pop(ctx);
                _viewPhoto();
              },
            ),
          ListTile(
            leading: const Icon(Icons.photo_library_rounded),
            title: const Text('Elegir foto'),
            onTap: () {
              Navigator.pop(ctx);
              _changePhoto();
            },
          ),
          if (profile.avatarUrl != null)
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded),
              title: const Text('Quitar foto'),
              onTap: () {
                Navigator.pop(ctx);
                _removePhoto();
              },
            ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initial = profile.displayName.characters.first.toUpperCase();
    final hasName = (profile.fullName ?? '').trim().isNotEmpty;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 8),
        Center(
          child: GestureDetector(
            onTap: _busy ? null : _photoMenu,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: AloColors.violet,
                  foregroundImage: profile.avatarUrl == null
                      ? null
                      : NetworkImage(profile.avatarUrl!),
                  child: Text(initial,
                      style: const TextStyle(
                          fontSize: 34, fontWeight: FontWeight.w800)),
                ),
                if (_busy)
                  const SizedBox(
                      width: 96,
                      height: 96,
                      child: CircularProgressIndicator(strokeWidth: 3)),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                        color: AloColors.indicator, shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt_rounded, size: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(profile.displayName,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        ),
        if (hasName) Center(child: Text(profile.email)),
        const SizedBox(height: 10),
        Center(
          child: Chip(
            avatar: Icon(
                profile.isCreator
                    ? Icons.auto_awesome_rounded
                    : Icons.person_rounded,
                size: 16),
            label: Text(profile.isCreator ? 'Creador de contenido' : 'Usuario'),
          ),
        ),
        const SizedBox(height: 8),
        const Divider(height: 32),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.settings_rounded, color: AloColors.lavender),
          title: const Text('Configuración'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => SettingsScreen(email: profile.email),
          )),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.logout_rounded),
          title: const Text('Cerrar sesión'),
          onTap: () async {
            final nav = Navigator.of(context);
            try {
              await AuthService.signOut();
            } catch (_) {}
            // Vuelve de una vez a la pantalla raíz (el inicio de sesión).
            nav.popUntil((route) => route.isFirst);
          },
        ),
      ],
    );
  }
}