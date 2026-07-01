/// Simple mutex (mutual exclusion) lock for thread-safe operations
class Mutex {
  bool _locked = false;
  final List<Future<void> Function()> _queue = [];

  /// Lock resource and execute callback
  Future<T> lock<T>(Future<T> Function() callback) async {
    while (_locked) {
      await Future.delayed(const Duration(milliseconds: 10));
    }

    _locked = true;
    try {
      return await callback();
    } finally {
      _locked = false;
    }
  }

  /// Check if locked
  bool get isLocked => _locked;

  /// Wait for lock to be released
  Future<void> waitUntilUnlocked() async {
    while (_locked) {
      await Future.delayed(const Duration(milliseconds: 10));
    }
  }

  /// Force unlock (use with caution)
  void forceUnlock() {
    _locked = false;
  }
}
