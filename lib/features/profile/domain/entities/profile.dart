import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final String? bio;
  final String? address;
  final String? city;
  final String? country;
  final String? postalCode;
  final DateTime? dateOfBirth;
  final String? gender;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatarUrl,
    this.bio,
    this.address,
    this.city,
    this.country,
    this.postalCode,
    this.dateOfBirth,
    this.gender,
    this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [id, name, email, phone, avatarUrl, bio, address, city, country, postalCode, dateOfBirth, gender];
}
