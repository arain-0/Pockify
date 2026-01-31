import 'package:hive_flutter/hive_flutter.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static const String settingsBox = 'settings';
  static const String downloadsBox = 'downloads';

  Box? _settingsBox;
  Box? _downloadsBox;

  Future<void> init() async {
    _settingsBox = await Hive.openBox(settingsBox);
    _downloadsBox = await Hive.openBox(downloadsBox);
  }

  // Generic get/put methods
  dynamic get(String boxName, String key, {dynamic defaultValue}) {
    var box = Hive.box(boxName);
    return box.get(key, defaultValue: defaultValue);
  }

  Future<void> put(String boxName, String key, dynamic value) async {
    var box = Hive.box(boxName);
    await box.put(key, value);
  }

  // Settings methods
  T? getValue<T>(String key) {
    return _settingsBox?.get(key) as T?;
  }

  Future<void> setValue<T>(String key, T value) async {
    await _settingsBox?.put(key, value);
  }

  // Generic box methods
  Box<T>? getBox<T>(String boxName) {
    try {
      return Hive.box<T>(boxName);
    } catch (_) {
      return null;
    }
  }

  List<T> getAll<T>(String boxName) {
    try {
      final box = Hive.box<T>(boxName);
      return box.values.toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> delete(String boxName, String key) async {
    var box = Hive.box(boxName);
    await box.delete(key);
  }

  Future<void> clearBox(String boxName) async {
    var box = Hive.box(boxName);
    await box.clear();
  }

  Future<void> clearAll() async {
    await _settingsBox?.clear();
    await _downloadsBox?.clear();
  }
}
