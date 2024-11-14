import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:onnxruntime/onnxruntime.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';

class ImageProcessingService {
  static const int INPUT_SIZE = 256;
  late OrtSession _session;
  bool _isInitialized = false;

  ImageProcessingService() {
    initModel().then((_) {
      _isInitialized = true;
      print('Model initialized successfully');
    }).catchError((e) {
      print('Failed to initialize model: $e');
    });
  }

  Future<void> initModel() async {
    if (_isInitialized) return;

    try {
      OrtEnv.instance.init();

      final sessionOptions = OrtSessionOptions()
        ..setIntraOpNumThreads(1)
        ..setInterOpNumThreads(1);

      final modelData = await rootBundle.load('assets/models/modnet.onnx');
      _session = OrtSession.fromBuffer(
        modelData.buffer.asUint8List(),
        sessionOptions,
      );

      _isInitialized = true;
    } catch (e) {
      print('Error initializing model: $e');
      rethrow;
    }
  }

  Future<String> removeBackground(File imageFile) async {
    try {
      if (!_isInitialized) {
        await initModel();
      }

      // 1. 预处理图像
      final processedInput = await _preprocessImage(imageFile);

      // 2. 创建输入张量
      final inputTensor = OrtValueTensor.createTensorWithDataList(
        Float32List.fromList(processedInput),
        [1, 3, INPUT_SIZE, INPUT_SIZE],
      );

      // 3. 运行推理
      final runOptions = OrtRunOptions();
      final outputs = await _session.run(
        runOptions,
        {'input': inputTensor},
      );

      // 4. 获取输出数据
      final output = outputs[0];
      final rawMaskData = output?.value as List<List<List<List<double>>>>;
      final maskData = rawMaskData[0][0].expand((row) => row).toList();

      // 5. 后处理并保存结果
      final tempDir = await getTemporaryDirectory();
      final processedImage = File(
        '${tempDir.path}/nobg_${DateTime.now().millisecondsSinceEpoch}.png',
      );

      // 应用 alpha 遮罩并保存
      final bytes = await imageFile.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final originalImage = frame.image;

      final resultImage = await _applyMask(originalImage, maskData);
      await processedImage.writeAsBytes(resultImage);

      // 6. 保存到相册
      await _saveToGallery(processedImage);

      // 7. 释放资源
      inputTensor.release();
      runOptions.release();
      for (var output in outputs) {
        output?.release();
      }
      originalImage.dispose();

      return processedImage.path;
    } catch (e) {
      print('Background removal failed: $e');
      rethrow;
    }
  }

  Future<List<double>> _preprocessImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    final inputData = List<double>.filled(INPUT_SIZE * INPUT_SIZE * 3, 0);
    final imageBytes =
        await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (imageBytes == null) return inputData;

    final scaleX = image.width / INPUT_SIZE;
    final scaleY = image.height / INPUT_SIZE;

    final means = [0.5, 0.5, 0.5];
    final stds = [0.5, 0.5, 0.5];

    for (var y = 0; y < INPUT_SIZE; y++) {
      for (var x = 0; x < INPUT_SIZE; x++) {
        final srcX = (x * scaleX).round();
        final srcY = (y * scaleY).round();
        final pixelOffset = (srcY * image.width + srcX) * 4;

        for (var c = 0; c < 3; c++) {
          final value = imageBytes.getUint8(pixelOffset + c) / 255.0;
          final index = c * INPUT_SIZE * INPUT_SIZE + y * INPUT_SIZE + x;
          inputData[index] = (value - means[c]) / stds[c];
        }
      }
    }

    image.dispose();
    return inputData;
  }

  Future<Uint8List> _applyMask(ui.Image original, List<double> mask) async {
    final maskImage =
        await _createMaskImage(mask, original.width, original.height);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    canvas.drawImage(original, Offset.zero, Paint());
    canvas.drawImage(
      maskImage,
      Offset.zero,
      Paint()..blendMode = BlendMode.dstIn,
    );

    final picture = recorder.endRecording();
    final resultImage = await picture.toImage(original.width, original.height);
    final byteData =
        await resultImage.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }

  Future<ui.Image> _createMaskImage(
      List<double> mask, int width, int height) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final scaleX = width / INPUT_SIZE;
    final scaleY = height / INPUT_SIZE;

    for (var y = 0; y < INPUT_SIZE; y++) {
      for (var x = 0; x < INPUT_SIZE; x++) {
        final maskIndex = y * INPUT_SIZE + x;
        if (maskIndex >= mask.length) continue;

        final alpha = (mask[maskIndex] * 255.0).round().clamp(0, 255);
        final targetX = (x * scaleX).round();
        final targetY = (y * scaleY).round();
        final targetWidth = (scaleX.ceil()).clamp(1, width - targetX);
        final targetHeight = (scaleY.ceil()).clamp(1, height - targetY);

        canvas.drawRect(
          Rect.fromLTWH(
            targetX.toDouble(),
            targetY.toDouble(),
            targetWidth.toDouble(),
            targetHeight.toDouble(),
          ),
          Paint()
            ..color = ui.Color(
              (alpha << 24) | (0xFF << 16) | (0xFF << 8) | 0xFF,
            ),
        );
      }
    }

    final picture = recorder.endRecording();
    return await picture.toImage(width, height);
  }

  Future<void> _saveToGallery(File imageFile) async {
    try {
      final result = await ImageGallerySaver.saveFile(
        imageFile.path,
        isReturnPathOfIOS: true,
      );

      if (result['isSuccess']) {
        print('Image saved to gallery: ${result['filePath']}');
      } else {
        throw Exception('Failed to save image: ${result['error']}');
      }
    } catch (e) {
      print('Error saving to gallery: $e');
      rethrow;
    }
  }

  void dispose() {
    if (_isInitialized) {
      _session.release();
      OrtEnv.instance.release();
    }
  }
}
