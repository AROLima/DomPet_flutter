// DIDACTIC: AuthResponse — token payload returned by the auth endpoint
// Purpose:
// - Simple DTO containing the raw token and its lifetime in milliseconds.
// Contract:
// - `token` must be the Bearer/JWT string used in Authorization headers.
// - `expiresIn` is used by the session layer to schedule proactive refreshes.
// Edge cases / Notes:
// - If tokens are missing or malformed the higher-level session provider
//   should clear the session and surface a login flow.

// Implementação manual para evitar dependência de arquivos gerados do Freezed.

class AuthResponse {
  const AuthResponse({
    required this.token,
    required this.expiresIn, // milliseconds
  });

  final String token;
  final int expiresIn;

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        token: json['token'] as String,
        expiresIn: (json['expiresIn'] as num).toInt(),
      );

  Map<String, dynamic> toJson() => {
        'token': token,
        'expiresIn': expiresIn,
      };
}
