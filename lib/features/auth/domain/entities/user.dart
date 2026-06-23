import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final String? role;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatarUrl,
    this.role,
    this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [id, name, email, phone, avatarUrl, role, createdAt, updatedAt];
}
