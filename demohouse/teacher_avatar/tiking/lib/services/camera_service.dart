import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:io';

class CameraService extends ChangeNotifier {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _isRecording = false;
  String? _lastCapturedImagePath;

  CameraController? get cameraController => _cameraController;
  bool get isInitialized => _isInitialized;
  bool get isRecording => _isRecording;
  String? get lastCapturedImagePath => _lastCapturedImagePath;

  Future<void> initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        debugPrint('No cameras available');
        return;
      }

      // 默认使用后置摄像头
      final backCamera = _cameras.firstWhere((camera) => camera.lensDirection == CameraLensDirection.back, orElse: () => _cameras.first);

      _cameraController = CameraController(backCamera, ResolutionPreset.high, enableAudio: true, imageFormatGroup: ImageFormatGroup.jpeg);

      await _cameraController!.initialize();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      _isInitialized = false;
      notifyListeners();
    }
  }

  Future<String?> captureImage() async {
    if (!_isInitialized || _cameraController == null) {
      return null;
    }

    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String imagePath = path.join(appDocDir.path, 'captured_image_$timestamp.jpg');

      final XFile image = await _cameraController!.takePicture();
      await image.saveTo(imagePath);

      _lastCapturedImagePath = imagePath;
      notifyListeners();

      return imagePath;
    } catch (e) {
      debugPrint('Error capturing image: $e');
      return null;
    }
  }

  Future<void> startVideoRecording() async {
    if (!_isInitialized || _cameraController == null || _isRecording) {
      return;
    }

    try {
      await _cameraController!.startVideoRecording();
      _isRecording = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error starting video recording: $e');
    }
  }

  Future<String?> stopVideoRecording() async {
    if (!_isInitialized || _cameraController == null || !_isRecording) {
      return null;
    }

    try {
      final XFile video = await _cameraController!.stopVideoRecording();
      _isRecording = false;
      notifyListeners();
      return video.path;
    } catch (e) {
      debugPrint('Error stopping video recording: $e');
      _isRecording = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> switchCamera() async {
    if (_cameras.length < 2) return;

    try {
      final currentCamera = _cameraController?.description;
      final newCamera = _cameras.firstWhere((camera) => camera != currentCamera, orElse: () => _cameras.first);

      await _cameraController?.dispose();

      _cameraController = CameraController(newCamera, ResolutionPreset.high, enableAudio: true, imageFormatGroup: ImageFormatGroup.jpeg);

      await _cameraController!.initialize();
      notifyListeners();
    } catch (e) {
      debugPrint('Error switching camera: $e');
    }
  }

  Future<void> toggleFlash() async {
    if (!_isInitialized || _cameraController == null) return;

    try {
      final currentFlashMode = _cameraController!.value.flashMode;
      final newFlashMode = currentFlashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;

      await _cameraController!.setFlashMode(newFlashMode);
      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling flash: $e');
    }
  }

  FlashMode get currentFlashMode {
    return _cameraController?.value.flashMode ?? FlashMode.off;
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  /// 仅释放相机控制器资源，不销毁服务本身
  Future<void> disposeController() async {
    try {
      await _cameraController?.dispose();
    } catch (_) {}
    _cameraController = null;
    _isInitialized = false;
    _isRecording = false;
    notifyListeners();
  }
}
