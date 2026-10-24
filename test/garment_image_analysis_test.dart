import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:stylr/services/garment_image_analysis.dart';

void main() {
  test('colour analysis ignores fully transparent pixels', () {
    final image = img.Image(width: 8, height: 8, numChannels: 4);
    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        image.setPixelRgba(x, y, 240, 20, 180, 0);
      }
    }
    for (var y = 0; y < 4; y++) {
      for (var x = 0; x < image.width; x++) {
        image.setPixelRgba(x, y, 128, 128, 128, 255);
      }
    }

    final result = analyzeGarmentColors(image);

    expect(result.colors, ['Grey']);
    expect(result.suggestedName, 'Grey garment');
  });

  test('empty alpha mask returns no colour guess', () {
    final image = img.Image(width: 8, height: 8, numChannels: 4);

    final result = analyzeGarmentColors(image);

    expect(result.colors, isEmpty);
    expect(result.suggestedName, 'Garment');
  });

  test('dominant colours are derived from visible garment pixels', () {
    final image = img.Image(width: 8, height: 8, numChannels: 4);
    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        image.setPixelRgba(x, y, 10, 20, 100, 255);
      }
    }
    for (var y = 0; y < 3; y++) {
      for (var x = 0; x < image.width; x++) {
        image.setPixelRgba(x, y, 220, 30, 30, 255);
      }
    }

    final result = analyzeGarmentColors(image);

    expect(result.colors, ['Navy blue', 'Red']);
    expect(result.suggestedName, 'Navy blue garment');
  });
}
