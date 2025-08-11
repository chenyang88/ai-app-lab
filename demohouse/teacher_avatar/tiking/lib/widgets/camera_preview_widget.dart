import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import '../services/camera_service.dart';

class CameraPreviewWidget extends StatelessWidget {
  const CameraPreviewWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CameraService>(
      builder: (context, cameraService, child) {
        if (!cameraService.isInitialized ||
            cameraService.cameraController == null) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        final cameraController = cameraService.cameraController!;
        final aspectRatio = cameraController.value.aspectRatio;

        return ClipRect(
          child: OverflowBox(
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.fitWidth,
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.width / aspectRatio,
                child: Stack(
                  children: [
                    CameraPreview(cameraController),
                    // 参考线框
                    const CameraReferenceLines(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class CameraReferenceLines extends StatelessWidget {
  const CameraReferenceLines({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.3,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            // 四角的装饰线
            _buildCornerLine(Alignment.topLeft),
            _buildCornerLine(Alignment.topRight),
            _buildCornerLine(Alignment.bottomLeft),
            _buildCornerLine(Alignment.bottomRight),
          ],
        ),
      ),
    );
  }

  Widget _buildCornerLine(Alignment alignment) {
    return Positioned.fill(
      child: Align(
        alignment: alignment,
        child: Container(
          width: 20,
          height: 20,
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Colors.white,
                width:
                    alignment == Alignment.topLeft ||
                            alignment == Alignment.topRight
                        ? 3
                        : 0,
              ),
              bottom: BorderSide(
                color: Colors.white,
                width:
                    alignment == Alignment.bottomLeft ||
                            alignment == Alignment.bottomRight
                        ? 3
                        : 0,
              ),
              left: BorderSide(
                color: Colors.white,
                width:
                    alignment == Alignment.topLeft ||
                            alignment == Alignment.bottomLeft
                        ? 3
                        : 0,
              ),
              right: BorderSide(
                color: Colors.white,
                width:
                    alignment == Alignment.topRight ||
                            alignment == Alignment.bottomRight
                        ? 3
                        : 0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
