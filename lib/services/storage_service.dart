import 'package:hive_flutter/hive_flutter.dart';
import '../models/download_model.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static const String settingsBox = 'settings';
  static const String downloadsBox = 'downloads';

  Box? _settingsBox;
  Box<DownloadModel>? _downloadsBox;
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      _settingsBox = await Hive.openBox(settingsBox);
      _downloadsBox = await Hive.openBox<DownloadModel>(downloadsBox);
      _isInitialized = true;
    } catch (e) {
      // Handle corrupted storage
      await Hive.deleteBoxFromDisk(settingsBox);
      await Hive.deleteBoxFromDisk(downloadsBox);
      _settingsBox = await Hive.openBox(settingsBox);
      _downloadsBox = await Hive.openBox<DownloadModel>(downloadsBox);
      _isInitialized = true;
    }
  }

  // Generic get/put methods
  dynamic get(String boxName, String key, {dynamic defaultValue}) {
    if (!_isInitialized) return defaultValue;
    if (boxName == settingsBox) return _settingsBox?.get(key, defaultValue: defaultValue);
    return null;
  }

  Future<void> put(String boxName, String key, dynamic value) async {
    if (!_isInitialized) return;
    if (boxName == settingsBox) await _settingsBox?.put(key, value);
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
    if (boxName == downloadsBox) {
      return _downloadsBox as Box<T>?;
    }
    return null;
  }

  List<T> getAll<T>(String boxName) {
    if (boxName == downloadsBox && _downloadsBox != null) {
      return _downloadsBox!.values.toList().cast<T>();
    }
    return [];
  }

  Future<void> delete(String boxName, String key) async {
     if (boxName == downloadsBox) {
       await _downloadsBox?.delete(key);
     } else if (boxName == settingsBox) {
       await _settingsBox?.delete(key);
     }
  }

  Future<void> clearBox(String boxName) async {
    if (boxName == downloadsBox) {
       await _downloadsBox?.clear();
     } else if (boxName == settingsBox) {
       await _settingsBox?.clear();
     }
  }

  Future<void> clearAll() async {
    await _settingsBox?.clear();
    await _downloadsBox?.clear();
  }
}
