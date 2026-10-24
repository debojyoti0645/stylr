import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:stylr/services/background_removal_image.dart';

void main() {
  test('foreground mask preserves transparency outside the garment', () {
    final source = img.Image(width: 2, height: 2);
    final mask = img.Image(width: 2, height: 2);
    for (var y = 0; y < 2; y++) {
      for (var x = 0; x < 2; x++) {
        source.setPixelRgb(x, y, 80, 100, 120);
        mask.setPixelRgb(x, y, 0, 0, 0);
      }
    }
    mask.setPixelRgb(1, 1, 255, 255, 255);

    final result = applyForegroundMask(source, mask, threshold: 0.62);

    expect(result.image.numChannels, 4);
    expect(result.foregroundPixels, 1);
    expect(result.image.getPixel(1, 1).a, 255);
    expect(result.image.getPixel(0, 0).a, 0);
  });

  test(
    'PNG canvas is 1024 square, transparent, centered, and proportional',
    () {
      final cropped = img.Image(width: 4, height: 2, numChannels: 4);
      for (var y = 0; y < cropped.height; y++) {
        for (var x = 0; x < cropped.width; x++) {
          cropped.setPixelRgba(x, y, 80, 100, 120, 255);
        }
      }

      final canvas = centerCutoutOnWhiteCanvas(cropped, 1024);
      final decoded = img.decodeImage(img.encodePng(canvas))!;

      expect(decoded.width, 1024);
      expect(decoded.height, 1024);
      expect(decoded.numChannels, 4);
      expect(decoded.getPixel(0, 0).a, 0);
      expect(decoded.getPixel(0, 0).r, 255);

      var minX = decoded.width;
      var minY = decoded.height;
      var maxX = -1;
      var maxY = -1;
      for (var y = 0; y < decoded.height; y++) {
        for (var x = 0; x < decoded.width; x++) {
          if (decoded.getPixel(x, y).a == 0) continue;
          if (x < minX) minX = x;
          if (y < minY) minY = y;
          if (x > maxX) maxX = x;
          if (y > maxY) maxY = y;
        }
      }

      expect(maxX - minX + 1, 928);
      expect(maxY - minY + 1, 464);
      expect(minX + maxX, 1023);
      expect(minY + maxY, 1023);
    },
  );
}
