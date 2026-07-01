
import 'package:equatable/equatable.dart';

class UserMeta extends Equatable {
  final String id;
  final String key;
  final String value;
  const UserMeta({
    required this.id,
    required this.key,
    required this.value
  })
}
