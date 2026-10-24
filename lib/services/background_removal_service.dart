
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class BackgroundRemovalService {
  static final BackgroundRemovalService _instance =
      BackgroundRemovalService._internal();

  factory BackgroundRemovalService() => _instance;

  BackgroundRemovalService._internal();

  OnnxRuntime? _runtime;
  OrtSession? _session;
  Future<void>? _initialization;

  Future<void> initialize() async {
    if (_session != null) return;
    if (_initialization != null) {
      await _initialization;
      return;
    }

    _initialization = _initializeInternal();
    try {
      await _initialization;
    } finally {
      if (_session == null) {
        _initialization = null;
      }
    }
  }

  Future<void> _initializeInternal() async {
    _runtime = OnnxRuntime();
    _session = await _runtime!.createSessionFromAsset(
      'assets/models/u2netp.onnx',
      options: OrtSessionOptions(
        providers: [OrtProvider.CPU],
      ),
    );

    debugPrint('U2-NetP model loaded successfully.');
    debugPrint('Model inputs: ${_session!.inputNames}');
    debugPrint('Model outputs: ${_session!.outputNames}');
  }

  Future<File> processImageFile(
    File sourceFile, {
    double threshold = 0.62,
    int squareSize = 1024,
  }) async {
    if (!await sourceFile.exists()) {
      throw FileSystemException('Image file could not be found', sourceFile.path);
    }

    await initialize();

    final sourceBytes = await sourceFile.readAsBytes();
    final outputBytes = await removeBackgroundFromBytes(
      sourceBytes,
      threshold: threshold,
      squareSize: squareSize,
    );

    final documentsDir = await getApplicationDocumentsDirectory();
    final outputDir = Directory('${documentsDir.path}/processed_clothing');
    if (!await outputDir.exists()) {
      await outputDir.create(recursive: true);
    }

    final outputFile = File(
      '${outputDir.path}/processed_${DateTime.now().microsecondsSinceEpoch}.png',
    );
    await outputFile.writeAsBytes(outputBytes);
    return outputFile;
  }

  Future<Uint8List> removeBackgroundFromBytes(
    Uint8List sourceBytes, {
    double threshold = 0.62,
    int squareSize = 1024,
  }) async {
    if (_session == null) {
      await initialize();
    }

    final decoded = img.decodeImage(sourceBytes);
    if (decoded == null) {
      throw const FormatException('The selected file is not a valid image.');
    }

    final rgbImage = _prepareImage(decoded);
    final resized = img.copyResize(
      rgbImage,
      width: 320,
      height: 320,
      interpolation: img.Interpolation.linear,
    );

    final rgb = resized.getBytes(order: img.ChannelOrder.rgb);
    final normalized = Float32List(rgb.length);
    final mean = [0.485, 0.456, 0.406];
    final std = [0.229, 0.224, 0.225];

    var index = 0;
    for (var i = 0; i < rgb.length; i += 3) {
      normalized[index++] = ((rgb[i] / 255.0) - mean[0]) / std[0];
      normalized[index++] = ((rgb[i + 1] / 255.0) - mean[1]) / std[1];
      normalized[index++] = ((rgb[i + 2] / 255.0) - mean[2]) / std[2];
    }

    final inputTensor = await OrtValue.fromList(
      normalized,
      [1, 3, 320, 320],
    );

    final outputs = await _session!.run({'input.1': inputTensor});
    final maskValue = outputs[_session!.outputNames.first];
    if (maskValue == null) {
      throw StateError('The segmentation model did not return a valid mask.');
    }

    final maskData = await maskValue.asFlattenedList();
    final maskPixels = <double>[];
    for (final value in maskData) {
      if (value is num) {
        maskPixels.add(value.toDouble());
      }
    }

    if (maskPixels.length != 102400) {
      throw StateError(
        'Unexpected mask length: ${maskPixels.length}. Expected 102400 pixels.',
      );
    }

    final maskImage = img.Image(width: 320, height: 320);
    for (var y = 0; y < 320; y++) {
      for (var x = 0; x < 320; x++) {
        final value = maskPixels[(y * 320) + x];
        final alpha = (value.clamp(0.0, 1.0) * 255.0).round();
        maskImage.setPixelRgba(x, y, alpha, alpha, alpha, 255);
      }
    }

    final resizedMask = img.copyResize(
      maskImage,
      width: rgbImage.width,
      height: rgbImage.height,
      interpolation: img.Interpolation.linear,
    );

    final cutout = img.Image(width: rgbImage.width, height: rgbImage.height);
    for (var y = 0; y < rgbImage.height; y++) {
      for (var x = 0; x < rgbImage.width; x++) {
        final source = rgbImage.getPixel(x, y);
        final maskPixel = resizedMask.getPixel(x, y);
        final maskValue = maskPixel.r.toDouble() / 255.0;
        final alpha = maskValue >= threshold ? (maskValue * 255.0).round() : 0;
        cutout.setPixelRgba(x, y, source.r, source.g, source.b, alpha);
      }
    }

    final bounds = _findNonTransparentBounds(cutout);
    if (bounds == null) {
      throw StateError('No foreground pixels were detected in the photo.');
    }

    final cropX = bounds.$1;
    final cropY = bounds.$2;
    final cropWidth = bounds.$3;
    final cropHeight = bounds.$4;

    final cropped = img.Image(
      width: cropWidth,
      height: cropHeight,
    );
    for (var y = 0; y < cropHeight; y++) {
      for (var x = 0; x < cropWidth; x++) {
        final pixel = cutout.getPixel(cropX + x, cropY + y);
        cropped.setPixel(x, y, pixel);
      }
    }

    final padded = _centreOnWhiteCanvas(cropped, squareSize);
    return img.encodePng(padded);
  }

  img.Image _prepareImage(img.Image image) {
    return image;
  }

  (int, int, int, int)? _findNonTransparentBounds(img.Image image) {
    var minX = image.width;
    var minY = image.height;
    var maxX = -1;
    var maxY = -1;

    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        if (pixel.a > 0) {
          if (x < minX) minX = x;
          if (y < minY) minY = y;
          if (x > maxX) maxX = x;
          if (y > maxY) maxY = y;
        }
      }
    }

    if (maxX < minX || maxY < minY) {
      return null;
    }

    return (
      minX,
      minY,
      maxX - minX + 1,
      maxY - minY + 1,
    );
  }

  img.Image _centreOnWhiteCanvas(img.Image cropped, int size) {
    final canvas = img.Image(width: size, height: size);
    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        canvas.setPixelRgba(x, y, 255, 255, 255, 255);
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

  Future<void> dispose() async {
    await _session?.close();
    _session = null;
    _runtime = null;
    _initialization = null;
  }
}
