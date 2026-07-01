/// Refresh token request DTO
class RefreshTokenDto {
  final String refreshToken;

  const RefreshTokenDto({
    required this.refreshToken,
  });

  Map<String, dynamic> toJson() => {
    'refresh_token': refreshToken,
  };
}
