import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../services/camera_service.dart';

class CameraControlsWidget extends StatelessWidget {
  final Function(String) onCapture;

  const CameraControlsWidget({super.key, required this.onCapture});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: const BoxDecoration(color: Colors.black),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // 相册按钮
            _buildControlButton(
              icon: Icons.image,
              onPressed: () => _openGallery(context),
            ),

            // 拍照按钮
            _buildCaptureButton(context),

            // 闪光灯按钮
            _buildControlButton(
              icon: Icons.flash_off,
              onPressed: () => _toggleFlash(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 50,
      height: 50,
      decoration: const BoxDecoration(
        color: Colors.white24,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildCaptureButton(BuildContext context) {
    return Consumer<CameraService>(
      builder: (context, cameraService, child) {
        return GestureDetector(
          onTap: () => _captureImage(context, cameraService),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
            ),
            child: Container(
              margin: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _captureImage(
    BuildContext context,
    CameraService cameraService,
  ) async {
    try {
      final imagePath = await cameraService.captureImage();
      if (imagePath != null) {
        onCapture(imagePath);
      } else {
        if (context.mounted) {
          _showError(context, '拍照失败，请重试');
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showError(context, '拍照失败: $e');
      }
    }
  }

  void _toggleFlash(BuildContext context) {
    final cameraService = context.read<CameraService>();
    cameraService.toggleFlash();
  }

  Future<void> _openGallery(BuildContext context) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 95,
      );

      if (image != null) {
        // 调用拍照回调，传递选择的图片路径
        onCapture(image.path);
      }
    } catch (e) {
      if (context.mounted) {
        _showError(context, '选择图片失败: $e');
      }
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
