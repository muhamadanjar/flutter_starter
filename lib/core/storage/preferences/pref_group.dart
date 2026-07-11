import 'package:hive/hive.dart';
import 'pref.dart';

/// Base class for grouping related preferences
abstract class PrefGroup {
  String get boxName;

  Box? _box;

  /// Resolves the box lazily: any instance of this group works as long as
  /// the box was opened once (e.g. via initBox() in main), since Hive
  /// caches open boxes by name.
  Box get box {
    final cached = _box;
    if (cached != null && cached.isOpen) return cached;
    if (Hive.isBoxOpen(boxName)) return _box = Hive.box(boxName);
    throw StateError(
      'Hive box "$boxName" is not open. Call initBox() during app startup.',
    );
  }

  /// Initialize Hive box
  Future<void> initBox() async {
    try {
      _box = await Hive.openBox(boxName);
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
