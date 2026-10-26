class UserProfile {
  final String id;
  final String email;
  final String? fullName;
  final String role; // 'user' | 'creator'

  const UserProfile({
    required this.id,
    required this.email,
    required this.role,
    this.fullName,
  });

  bool get isCreator => role == 'creator';
  String get displayName =>
      (fullName != null && fullName!.trim().isNotEmpty) ? fullName! : email;
}