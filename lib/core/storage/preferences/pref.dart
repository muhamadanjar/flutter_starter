import 'package:hive/hive.dart';

/// Generic preference wrapper for Hive boxes with type safety
class Pref<T> {
  final Box box;
  final String key;
  final T defaultValue;

  Pref({
    required this.box,
    required this.key,
    required this.defaultValue,
  });

  /// Get preference value
  T get() {
    try {
      return box.get(key, defaultValue: defaultValue) as T;
    } catch (e) {
      return defaultValue;
    }
  }

  /// Set preference value
  Future<void> put(T value) async {
    try {
      await box.put(key, value);
    } catch (e) {
      throw Exception('Failed to save preference $key: $e');
    }
  }

  /// Watch for changes (reactive)
  Stream<T> stream() {
    return box.watch(key: key).map((event) {
      try {
        return (event.value as T?) ?? defaultValue;
      } catch (e) {
        return defaultValue;
      }
    });
  }

  /// Delete preference
  Future<void> delete() async {
    try {
      await box.delete(key);
    } catch (e) {
      throw Exception('Failed to delete preference $key: $e');
    }
  }

  /// Check if preference exists
  bool exists() => box.containsKey(key);
}
