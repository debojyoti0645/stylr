
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class WardrobeImageStorage {
  static Future<String> saveImage(File image, String id) async {
    final appDirectory = await getApplicationDocumentsDirectory();

    final wardrobeDirectory = Directory(
      '${appDirectory.path}/wardrobe_images',
    );

    if (!await wardrobeDirectory.exists()) {
      await wardrobeDirectory.create(recursive: true);
    }

    final extension = image.path.contains('.')
        ? '.${image.path.split('.').last}'
        : '.jpg';

    final destination = File(
      '${wardrobeDirectory.path}/$id$extension',
    );

    await image.copy(destination.path);
    return destination.path;
  }

  static Future<void> deleteImage(String? path) async {
    if (path == null || path.isEmpty) return;

    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
