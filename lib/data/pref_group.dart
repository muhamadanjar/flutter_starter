import 'package:enterprise_flutter_app/data/pref.dart';
import 'package:hive_flutter/hive_flutter.dart';

abstract class PrefGroup {
  abstract String name;

  late Box box;

  Future initBox() async {
    box = await Hive.openBox(name);
  }

  Pref<T> pref<T>(String name, T defaultValue) =>
      Pref<T>(box, name, defaultValue);

  void clear() {
    box.clear();
  }
}
