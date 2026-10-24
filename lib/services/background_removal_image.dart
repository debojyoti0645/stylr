import 'package:image/image.dart' as img;

({img.Image image, int foregroundPixels}) applyForegroundMask(
  img.Image source,
  img.Image mask, {
  required double threshold,
}) {
  if (source.width != mask.width || source.height != mask.height) {
    throw ArgumentError(
      'Source image and foreground mask must have equal size.',
    );
  }

  final cutout = img.Image(
    width: source.width,
    height: source.height,
    numChannels: 4,
  );
  var foregroundPixels = 0;
  for (var y = 0; y < source.height; y++) {
    for (var x = 0; x < source.width; x++) {
      final pixel = source.getPixel(x, y);
      final maskValue = mask.getPixel(x, y).r.toDouble() / 255.0;
      final alpha = maskValue >= threshold ? (maskValue * 255).round() : 0;
      if (alpha > 0) foregroundPixels++;
      cutout.setPixelRgba(x, y, pixel.r, pixel.g, pixel.b, alpha);
    }
  }

  return (image: cutout, foregroundPixels: foregroundPixels);
}

img.Image centerCutoutOnWhiteCanvas(img.Image cropped, int size) {
  if (size <= 96) {
    throw ArgumentError.value(size, 'size', 'Must be greater than 96.');
  }

  final canvas = img.Image(width: size, height: size, numChannels: 4);
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      canvas.setPixelRgba(x, y, 255, 255, 255, 0);
    }
  }

  final aspectRatio = cropped.width / cropped.height;
  final maxDimension = size - 96;
  int targetWidth;
  int targetHeight;

  if (aspectRatio >= 1) {
    targetWidth = maxDimension;
    targetHeight = (maxDimension / aspectRatio).round();
  } else {
    targetHeight = maxDimension;
    targetWidth = (maxDimension * aspectRatio).round();
  }

  final scaled = img.copyResize(
    cropped,
    width: targetWidth,
    height: targetHeight,
    interpolation: img.Interpolation.linear,
  );
  final offsetX = ((size - targetWidth) / 2).round();
  final offsetY = ((size - targetHeight) / 2).round();

  for (var y = 0; y < scaled.height; y++) {
    for (var x = 0; x < scaled.width; x++) {
      final pixel = scaled.getPixel(x, y);
      canvas.setPixelRgba(
        x + offsetX,
        y + offsetY,
        pixel.r,
        pixel.g,
        pixel.b,
        pixel.a,
      );
    }
  }

  return canvas;
}

int countTransparentPixels(img.Image image) {
  var count = 0;
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      if (image.getPixel(x, y).a == 0) count++;
    }
  }
  return count;
}
