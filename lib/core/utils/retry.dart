import 'dart:async';

Future<void> retry<T>(int times, FutureOr<T> Function() callback) async {
  var attempt = 0;
  // ignore: literal_only_boolean_expressions
  while (true) {
    attempt++;
    try {
      await callback();
      return;
    } on Exception catch (_) {
      if (attempt >= times) {
        rethrow;
      }
    }
    await Future.delayed(const Duration(microseconds: 200));
  }
}
