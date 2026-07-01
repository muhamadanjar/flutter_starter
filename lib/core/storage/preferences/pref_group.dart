import 'package:hive/hive.dart';
import 'pref.dart';

/// Base class for grouping related preferences
abstract class PrefGroup {
  String get boxName;

  late Box box;

  /// Initialize Hive box
  Future<void> initBox() async {
    try {
      box = await Hive.openBox(boxName);
    } catch (e) {
      throw Exception('Failed to initialize box $boxName: $e');
    }
  }

  /// Create typed preference with default value
  Pref<T> pref<T>(String key, T defaultValue) {
    return Pref<T>(
      box: box,
      key: key,
      defaultValue: defaultValue,
    );
  }

  /// Clear all preferences in this group
  Future<void> clear() async {
    try {
      await box.clear();
    } catch (e) {
      throw Exception('Failed to clear preferences: $e');
    }
  }

  /// Close the box
  Future<void> close() async {
    try {
      await box.close();
    } catch (e) {
      throw Exception('Failed to close box: $e');
    }
  }
}
