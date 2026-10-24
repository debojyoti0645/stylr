import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:stylr/services/background_removal_image.dart';

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

    debugPrint('[BackgroundRemoval] Initializing U2-NetP on CPU.');
    _initialization = _initializeInternal();
    try {
      await _initialization;
    } catch (error, stackTrace) {
      debugPrint('[BackgroundRemoval] Initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
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
      options: OrtSessionOptions(providers: [OrtProvider.CPU]),
    );

    debugPrint('[BackgroundRemoval] U2-NetP initialized successfully.');
    debugPrint('[BackgroundRemoval] Model inputs: ${_session!.inputNames}');
    debugPrint('[BackgroundRemoval] Model outputs: ${_session!.outputNames}');
  }

  Future<File> processImageFile(
    File sourceFile, {
    double threshold = 0.62,
    int squareSize = 1024,
  }) async {
    if (!await sourceFile.exists()) {
      throw FileSystemException(
        'Image file could not be found',
        sourceFile.path,
      );
    }

    debugPrint('[BackgroundRemoval] Processing image: ${sourceFile.path}');
    try {
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
      debugPrint('[BackgroundRemoval] Processed PNG saved: ${outputFile.path}');
      return outputFile;
    } catch (error, stackTrace) {
      debugPrint('[BackgroundRemoval] Processing failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
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

    debugPrint(
      '[BackgroundRemoval] Inference started; input image ${decoded.width}x${decoded.height}.',
    );
    final rgb = resized.getBytes(order: img.ChannelOrder.rgb);
    const planeSize = 320 * 320;
    final normalized = Float32List(3 * planeSize);
    final mean = [0.485, 0.456, 0.406];
    final std = [0.229, 0.224, 0.225];

    for (var i = 0; i < rgb.length; i += 3) {
      final pixelIndex = i ~/ 3;
      normalized[pixelIndex] = ((rgb[i] / 255.0) - mean[0]) / std[0];
      normalized[planeSize + pixelIndex] =
          ((rgb[i + 1] / 255.0) - mean[1]) / std[1];
      normalized[(2 * planeSize) + pixelIndex] =
          ((rgb[i + 2] / 255.0) - mean[2]) / std[2];
    }

    debugPrint(
      '[BackgroundRemoval] Input tensor: float32 [1, 3, 320, 320], RGB, '
      'ImageNet normalized (NCHW).',
    );
    final inputTensor = await OrtValue.fromList(normalized, [1, 3, 320, 320]);

    final outputs = await _session!.run({'input.1': inputTensor});
    debugPrint(
      '[BackgroundRemoval] Inference completed; output tensors: '
      '${outputs.entries.map((entry) => '${entry.key}:${entry.value.shape}').join(', ')}',
    );
    final mainOutputName = _session!.outputNames.first;
    final maskValue = outputs[mainOutputName];
    if (maskValue == null) {
      throw StateError(
        'The segmentation model did not return its primary output '
        '"$mainOutputName".',
      );
    }
    if (maskValue.shape.length != 4 ||
        maskValue.shape[0] != 1 ||
        maskValue.shape[1] != 1 ||
        maskValue.shape[2] != 320 ||
        maskValue.shape[3] != 320) {
      throw StateError(
        'Unexpected primary output shape ${maskValue.shape}; '
        'expected [1, 1, 320, 320].',
      );
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

    var minimum = double.infinity;
    var maximum = double.negativeInfinity;
    var sum = 0.0;
    for (final value in maskPixels) {
      if (!value.isFinite) {
        throw StateError('The primary output contains non-finite mask values.');
      }
      if (value < minimum) minimum = value;
      if (value > maximum) maximum = value;
      sum += value;
    }
    final average = sum / maskPixels.length;
    debugPrint(
      '[BackgroundRemoval] Primary output "$mainOutputName" shape '
      '${maskValue.shape}; mask min=$minimum max=$maximum mean=$average.',
    );
    if (minimum < 0 || maximum > 1) {
      throw StateError(
        'The primary output range [$minimum, $maximum] is outside the '
        'expected sigmoid mask range [0, 1].',
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

    final cutoutResult = applyForegroundMask(
      rgbImage,
      resizedMask,
      threshold: threshold,
    );
    final cutout = cutoutResult.image;
    final foregroundPercent =
        cutoutResult.foregroundPixels *
        100 /
        (rgbImage.width * rgbImage.height);
    debugPrint(
      '[BackgroundRemoval] Foreground after threshold $threshold: '
      '${foregroundPercent.toStringAsFixed(2)}%.',
    );

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
      numChannels: 4,
    );
    for (var y = 0; y < cropHeight; y++) {
      for (var x = 0; x < cropWidth; x++) {
        final pixel = cutout.getPixel(cropX + x, cropY + y);
        cropped.setPixel(x, y, pixel);
      }
    }

    final padded = centerCutoutOnWhiteCanvas(cropped, squareSize);
    final outputBytes = img.encodePng(padded);
    final encodedImage = img.decodeImage(outputBytes);
    if (encodedImage == null ||
        encodedImage.width != squareSize ||
        encodedImage.height != squareSize ||
        encodedImage.numChannels != 4) {
      throw StateError(
        'Encoded PNG did not preserve the expected ${squareSize}x$squareSize '
        'RGBA canvas.',
      );
    }
    final transparentPixels = countTransparentPixels(encodedImage);
    if (transparentPixels == 0) {
      throw StateError(
        'Encoded PNG contains no transparent pixels outside the foreground.',
      );
    }
    debugPrint(
      '[BackgroundRemoval] PNG verified: ${encodedImage.width}x'
      '${encodedImage.height}, RGBA, '
      '${(transparentPixels * 100 / (squareSize * squareSize)).toStringAsFixed(2)}%'
      ' transparent.',
    );
    return outputBytes;
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

    return (minX, minY, maxX - minX + 1, maxY - minY + 1);
  }

  Future<void> dispose() async {
    await _session?.close();
    _session = null;
    _runtime = null;
    _initialization = null;
  }
}
