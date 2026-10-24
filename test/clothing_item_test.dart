import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:stylr/models/clothing_item.dart';

void main() {
  final dateAdded = DateTime(2026, 10, 24);

  test('older wardrobe records load with safe optional defaults', () {
    final item = ClothingItem.fromMap({
      'id': 'legacy-1',
      'name': 'Blue shirt',
      'category': 'Topwear',
      'originalImagePath': 'wardrobe/legacy.jpg',
      'dateAdded': dateAdded.toIso8601String(),
    });

    expect(item.colors, isEmpty);
    expect(item.pattern, isEmpty);
    expect(item.measurements, isEmpty);
    expect(item.measurementUnit, 'cm');
    expect(item.purchasePrice, isNull);
    expect(item.purchaseDate, isNull);
  });

  test(
    'copying an item preserves unchanged details and supports clearing price',
    () {
      final item = ClothingItem(
        id: 'garment-copy',
        name: 'Green coat',
        category: 'Outerwear',
        colors: const ['Green'],
        measurements: const {'Chest': '52'},
        purchasePrice: 49,
        originalImagePath: 'wardrobe/coat.jpg',
        cleanImagePath: 'wardrobe/coat-cutout.png',
        dateAdded: dateAdded,
      );

      final updated = item.copyWith(
        name: 'Olive coat',
        clearPurchasePrice: true,
      );

      expect(updated.name, 'Olive coat');
      expect(updated.colors, ['Green']);
      expect(updated.measurements, {'Chest': '52'});
      expect(updated.purchasePrice, isNull);
      expect(updated.originalImagePath, item.originalImagePath);
      expect(updated.cleanImagePath, item.cleanImagePath);
    },
  );

  test('extended garment details survive a Hive close and reopen', () async {
    final directory = await Directory.systemTemp.createTemp('stylr_hive_test_');
    Hive.init(directory.path);
    final item = ClothingItem(
      id: 'garment-1',
      name: 'Grey garment',
      category: 'Unclassified',
      colors: const ['Grey'],
      occasions: const ['Everyday'],
      pattern: 'Solid',
      measurementUnit: 'in',
      measurements: const {'Chest': '20'},
      purchasePrice: 29.5,
      purchaseDate: DateTime(2026, 9, 1),
      notes: 'User-entered note',
      originalImagePath: 'wardrobe/garment.jpg',
      dateAdded: dateAdded,
    );

    try {
      var box = await Hive.openBox<dynamic>('wardrobe-test');
      await box.put(item.id, item.toMap());
      await box.close();

      box = await Hive.openBox<dynamic>('wardrobe-test');
      final restored = ClothingItem.fromMap(
        Map<dynamic, dynamic>.from(box.get(item.id) as Map),
      );

      expect(restored.colors, ['Grey']);
      expect(restored.measurements, {'Chest': '20'});
      expect(restored.measurementUnit, 'in');
      expect(restored.purchasePrice, 29.5);
      expect(restored.purchaseDate, DateTime(2026, 9, 1));
      expect(restored.notes, 'User-entered note');
      await box.close();
    } finally {
      await Hive.close();
      await directory.delete(recursive: true);
    }
  });
}
