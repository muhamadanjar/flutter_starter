import 'package:hive/hive.dart';

class Pref<T> {
  final Box box;
  final String name;
  final T defaultValue;

  Pref(this.box, this.name, this.defaultValue);

  void put(T value) {
    box.put(name, value);
  }

  T get() => box.get(name, defaultValue: defaultValue);

  Stream<T?> stream() => box.watch(key: name).map((event) => event.value);
}
