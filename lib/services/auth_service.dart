import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_config.dart';
import '../models/user_profile.dart';

class AuthService {
  static Future<void> signIn(String email, String password) =>
      db.auth.signInWithPassword(email: email, password: password);

  static Future<AuthResponse> signUp(
          String email, String password, String name) =>
      db.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': name},
        // Al tocar "Confirmar" en el correo, Android abre la app (no una web).
        emailRedirectTo: 'alobien://login-callback',
      );

  static Future<void> signOut() => db.auth.signOut();

  /// Envía el correo para recuperar la contraseña. El enlace abre la app.
  static Future<void> sendPasswordReset(String email) =>
      db.auth.resetPasswordForEmail(email, redirectTo: 'alobien://login-callback');

  /// Guarda la nueva contraseña (la sesión de recuperación ya está activa).
  static Future<void> setNewPassword(String newPassword) =>
      db.auth.updateUser(UserAttributes(password: newPassword));

  /// Verifica la contraseña actual (iniciando sesión de nuevo) y cambia a la nueva.
  static Future<void> changePassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    await db.auth.signInWithPassword(email: email, password: currentPassword);
    await db.auth.updateUser(UserAttributes(password: newPassword));
  }

  /// Sube la foto de perfil a avatars/<uid>/<ts>.<ext>, la guarda en el
  /// perfil y borra la anterior. Devuelve la nueva ruta.
  static Future<String> uploadAvatar({
    required String uid,
    required File file,
    required String ext,
    String? oldPath,
  }) async {
    final path = '$uid/${DateTime.now().millisecondsSinceEpoch}.$ext';
    const mimes = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'webp': 'image/webp',
    };
    await db.storage.from('avatars').upload(
          path,
          file,
          fileOptions: FileOptions(contentType: mimes[ext], upsert: false),
        );
    try {
      await db.from('profiles').update({'avatar_path': path}).eq('id', uid);
    } catch (e) {
      await db.storage.from('avatars').remove([path]);
      rethrow;
    }
    if (oldPath != null && oldPath.isNotEmpty) {
      try {
        await db.storage.from('avatars').remove([oldPath]);
      } catch (_) {}
    }
    return path;
  }

  static Future<void> removeAvatar({required String uid, String? path}) async {
    await db.from('profiles').update({'avatar_path': null}).eq('id', uid);
    if (path != null && path.isNotEmpty) {
      try {
        await db.storage.from('avatars').remove([path]);
      } catch (_) {}
    }
  }

  /// El rol se lee SIEMPRE de la base de datos (fuente de verdad).
  static Future<UserProfile?> loadProfile() async {
    final user = db.auth.currentUser;
    if (user == null) return null;
    final row =
        await db.from('profiles').select().eq('id', user.id).maybeSingle();
    if (row == null) return null;
    return UserProfile(
      id: user.id,
      email: user.email ?? '',
      fullName: row['full_name'] as String?,
      role: (row['role'] as String?) ?? 'user',
      avatarPath: row['avatar_path'] as String?,
    );
  }
}