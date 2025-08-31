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
