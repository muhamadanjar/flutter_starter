import 'dart:async';

/// Broadcast channel for session lifecycle events.
///
/// Emitted by core networking (token refresh failure) and consumed by the
/// auth state layer, which cannot be imported from core without a dependency
/// cycle.
class SessionEvents {
  SessionEvents._();

  static final StreamController<void> _expiredController =
      StreamController<void>.broadcast();

  static Stream<void> get onSessionExpired => _expiredController.stream;

  static void notifySessionExpired() {
    _expiredController.add(null);
  }
}
