class LoginResponse {
  LoginResponse({
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

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['accessToken'] as String,
      userId: json['userId']?.toString() ?? '',
      email: json['email'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      role: json['role'] as String? ?? '',
    );
  }
}
