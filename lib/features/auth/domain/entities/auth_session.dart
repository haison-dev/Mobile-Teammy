class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.userId,
    required this.email,
    required this.displayName,
    required this.role,
  });

  final String accessToken;
  final String userId;
  final String email;
  final String displayName;
  final String role;
}
