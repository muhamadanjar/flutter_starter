import 'package:equatable/equatable.dart';

class UserMeta extends Equatable {
  const UserMeta({
    required this.id,
    required this.key,
    required this.value,
  });

  final String id;
  final String key;
  final String value;

  @override
  List<Object?> get props => [id, key, value];
}
