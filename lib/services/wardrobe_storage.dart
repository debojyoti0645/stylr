
import 'package:hive_flutter/hive_flutter.dart';
import 'package:stylr/models/clothing_item.dart';

class WardrobeStorage {
  static const String _boxName = 'wardrobe';
  static Box<dynamic>? _box;

  static Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox<dynamic>(_boxName);
  }

  static Box<dynamic> get _storage {
    final box = _box;
    if (box == null || !box.isOpen) {
      throw StateError(
        'WardrobeStorage is not initialized. Call init() first.',
      );
    }
    return box;
  }

  static List<ClothingItem> getAll() {
    return _storage.values.map((value) {
      return ClothingItem.fromMap(
        Map<dynamic, dynamic>.from(value as Map),
      );
    }).toList();
  }

  static ClothingItem? getById(String id) {
    final value = _storage.get(id);
    if (value == null) return null;

    return ClothingItem.fromMap(
      Map<dynamic, dynamic>.from(value as Map),
    );
  }

  static Future<void> save(ClothingItem item) async {
    await _storage.put(item.id, item.toMap());
  }

  static Future<void> delete(String id) async {
    await _storage.delete(id);
  }

  static Future<void> clearAll() async {
    await _storage.clear();
  }
}
