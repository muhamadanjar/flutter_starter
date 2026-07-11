/// Auth response DTO (from login/register)
class AuthResponseDto {

  const AuthResponseDto({
    required this.token,
    this.refreshToken,
    this.user,
  });

  factory AuthResponseDto.fromJson(Map<String, dynamic> json) {
    return AuthResponseDto(
      token: json['token'] as String? ?? '',
      refreshToken: json['refresh_token'] as String?,
      user: json['user'] as Map<String, dynamic>?,
    );
  }
  final String token;
  final String? refreshToken;
  final Map<String, dynamic>? user;

  Map<String, dynamic> toJson() => {
    'token': token,
    if (refreshToken != null) 'refresh_token': refreshToken,
    if (user != null) 'user': user,
  };
}
