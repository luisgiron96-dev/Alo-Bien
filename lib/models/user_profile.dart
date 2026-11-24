import '../core/supabase_config.dart';

class UserProfile {
  final String id;
  final String email;
  final String? fullName;
  final String role; // 'user' | 'creator'
  final String? avatarPath; // ruta en el bucket público 'avatars'

  const UserProfile({
    required this.id,
    required this.email,
    required this.role,
    this.fullName,
    this.avatarPath,
  });

  bool get isCreator => role == 'creator';
  String get displayName =>
      (fullName != null && fullName!.trim().isNotEmpty) ? fullName! : email;

  String? get avatarUrl => (avatarPath == null || avatarPath!.isEmpty)
      ? null
      : db.storage.from('avatars').getPublicUrl(avatarPath!);

  UserProfile copyWith({String? avatarPath, bool clearAvatar = false}) =>
      UserProfile(
        id: id,
        email: email,
        role: role,
        fullName: fullName,
        avatarPath: clearAvatar ? null : (avatarPath ?? this.avatarPath),
      );
}
