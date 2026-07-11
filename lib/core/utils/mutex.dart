import 'dart:async';

/// Simple mutex (mutual exclusion) lock for thread-safe operations
class Mutex {
  bool _locked = false;
  final List<Completer<void>> _queue = [];

  /// Lock resource and execute callback
  Future<T> lock<T>(Future<T> Function() callback) async {
    /// Jika sedang dikunci, masukkan ke dalam antrean dan tunggu giliran
    if (_locked) {
      final completer = Completer<void>();
      _queue.add(completer);
      await completer.future;
    }

    _locked = true;
    try {
      return await callback();
    } finally {
      _release();
    }
  }

  /// Mengecek apakah sedang dikunci
  bool get isLocked => _locked;

  /// Melepaskan kunci dan memberikan izin ke antrean berikutnya
  void _release() {
    if (_queue.isNotEmpty) {
      // Ambil antrean pertama, dan izinkan dia berjalan
      final next = _queue.removeAt(0);
      next.complete();
    } else {
      _locked = false;
    }
  }

  /// Membuka paksa seluruh antrean dan meriset status lock
  void forceUnlock() {
    _locked = false;
    for (var completer in _queue) {
      if (!completer.isCompleted) {
        completer.complete();
      }
    }
    _queue.clear();
  }
}
