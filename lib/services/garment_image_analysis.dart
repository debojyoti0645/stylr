import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class GarmentImageAnalysis {
  const GarmentImageAnalysis({
    required this.colors,
    required this.suggestedName,
  });

  final List<String> colors;
  final String suggestedName;
}

class GarmentImageAnalysisService {
  const GarmentImageAnalysisService();

  Future<GarmentImageAnalysis> analyzeFile(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    return compute(_analyzeEncodedImage, bytes);
  }
}

GarmentImageAnalysis _analyzeEncodedImage(Uint8List bytes) {
  final image = img.decodeImage(bytes);
  if (image == null) {
    throw const FormatException('The garment image could not be decoded.');
  }
  return analyzeGarmentColors(image);
}

GarmentImageAnalysis analyzeGarmentColors(img.Image image) {
  const maxSide = 96;
  final scale = maxSide / image.width > maxSide / image.height
      ? maxSide / image.height
      : maxSide / image.width;
  final sampled = scale < 1
      ? img.copyResize(
          image,
          width: (image.width * scale).round().clamp(1, maxSide),
          height: (image.height * scale).round().clamp(1, maxSide),
          interpolation: img.Interpolation.nearest,
        )
      : image;

  final bins = <int, _ColorBin>{};
  var visiblePixels = 0;
  for (final pixel in sampled) {
    if (pixel.a < 128) continue;
    visiblePixels++;
    final red = pixel.r.toInt();
    final green = pixel.g.toInt();
    final blue = pixel.b.toInt();
    final key = ((red ~/ 32) << 8) | ((green ~/ 32) << 4) | (blue ~/ 32);
    final bin = bins.putIfAbsent(key, _ColorBin.new);
    bin.add(red, green, blue);
  }

  if (visiblePixels < 16) {
    return const GarmentImageAnalysis(colors: [], suggestedName: 'Garment');
  }

  final colors = <String, int>{};
  for (final bin in bins.values) {
    final name = _readableColorName(
      bin.red / bin.count,
      bin.green / bin.count,
      bin.blue / bin.count,
    );
    colors.update(
      name,
      (count) => count + bin.count,
      ifAbsent: () => bin.count,
    );
  }

  final ranked = colors.entries.toList()
    ..sort((first, second) => second.value.compareTo(first.value));
  final detected = <String>[ranked.first.key];
  if (ranked.length > 1 &&
      ranked[1].value / visiblePixels >= 0.15 &&
      ranked[1].key != ranked.first.key) {
    detected.add(ranked[1].key);
  }
  return GarmentImageAnalysis(
    colors: detected,
    suggestedName: '${detected.first} garment',
  );
}

String _readableColorName(double red, double green, double blue) {
  final r = red / 255;
  final g = green / 255;
  final b = blue / 255;
  final maximum = [r, g, b].reduce((a, value) => a > value ? a : value);
  final minimum = [r, g, b].reduce((a, value) => a < value ? a : value);
  final delta = maximum - minimum;
  final lightness = (maximum + minimum) / 2;
  final saturation = delta == 0 ? 0.0 : delta / (1 - (2 * lightness - 1).abs());

  if (saturation < 0.16) {
    if (lightness < 0.16) return 'Black';
    if (lightness > 0.9) return 'White';
    if (red > blue * 1.12 && green > blue * 1.04 && lightness > 0.46) {
      return lightness > 0.7 ? 'Beige' : 'Tan';
    }
    return lightness < 0.38 ? 'Charcoal' : 'Grey';
  }

  var hue = switch (maximum) {
    _ when maximum == r => 60 * (((g - b) / delta) % 6),
    _ when maximum == g => 60 * (((b - r) / delta) + 2),
    _ => 60 * (((r - g) / delta) + 4),
  };
  if (hue < 0) hue += 360;

  if (hue < 15 || hue >= 345) {
    if (lightness < 0.35) return 'Maroon';
    return lightness > 0.78 ? 'Pink' : 'Red';
  }
  if (hue < 42) return lightness > 0.72 ? 'Beige' : 'Orange';
  if (hue < 68) return 'Yellow';
  if (hue < 95) return 'Olive';
  if (hue < 155) return 'Green';
  if (hue < 190) return 'Teal';
  if (hue < 250) {
    return lightness < 0.28 ? 'Navy blue' : 'Blue';
  }
  if (hue < 285) return 'Purple';
  if (hue < 330) return 'Pink';
  return 'Red';
}

class _ColorBin {
  int count = 0;
  int red = 0;
  int green = 0;
  int blue = 0;

  void add(int r, int g, int b) {
    count++;
    red += r;
    green += g;
    blue += b;
  }
}
