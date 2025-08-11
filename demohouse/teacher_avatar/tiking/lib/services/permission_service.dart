import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService extends ChangeNotifier {
  bool _cameraPermissionGranted = false;
  bool _microphonePermissionGranted = false;
  bool _storagePermissionGranted = false;

  bool get cameraPermissionGranted => _cameraPermissionGranted;
  bool get microphonePermissionGranted => _microphonePermissionGranted;
  bool get storagePermissionGranted => _storagePermissionGranted;

  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    _cameraPermissionGranted = status == PermissionStatus.granted;
    notifyListeners();
    return _cameraPermissionGranted;
  }

  Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    _microphonePermissionGranted = status == PermissionStatus.granted;
    notifyListeners();
    return _microphonePermissionGranted;
  }

  Future<bool> requestStoragePermission() async {
    final status = await Permission.storage.request();
    _storagePermissionGranted = status == PermissionStatus.granted;
    notifyListeners();
    return _storagePermissionGranted;
  }

  Future<void> checkAllPermissions() async {
    _cameraPermissionGranted = await Permission.camera.isGranted;
    _microphonePermissionGranted = await Permission.microphone.isGranted;
    _storagePermissionGranted = await Permission.storage.isGranted;
    notifyListeners();
  }

  Future<bool> requestAllPermissions() async {
    final results =
        await [
          Permission.camera,
          Permission.microphone,
          Permission.storage,
        ].request();

    _cameraPermissionGranted =
        results[Permission.camera] == PermissionStatus.granted;
    _microphonePermissionGranted =
        results[Permission.microphone] == PermissionStatus.granted;
    _storagePermissionGranted =
        results[Permission.storage] == PermissionStatus.granted;

    notifyListeners();

    return _cameraPermissionGranted &&
        _microphonePermissionGranted &&
        _storagePermissionGranted;
  }

  Future<void> openAppSettings() async {
    await openAppSettings();
  }
}
