/// Register request DTO
class RegisterRequestDto {
  final String username;
  final String name;
  final String email;
  final String password;
  final String confirmPassword;

  const RegisterRequestDto({
    required this.username,
    required this.name,
    required this.email,
    required this.password,
    required this.confirmPassword,
  });

  Map<String, dynamic> toJson() => {
    'username': username,
    'name': name,
    'email': email,
    'password': password,
    'password_confirmation': confirmPassword,
  };
}
