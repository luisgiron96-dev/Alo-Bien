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
      );

  static Future<void> signOut() => db.auth.signOut();

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
    );
  }
}