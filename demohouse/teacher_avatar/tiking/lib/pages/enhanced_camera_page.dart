import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/camera_service.dart';
import '../services/enhanced_multimodal_service.dart';
import '../widgets/camera_preview_widget.dart';
import '../widgets/camera_controls_widget.dart';
import 'question_solving_page.dart';
import 'homework_correction_page.dart';

/// 增强的相机页面 - 支持拍照解题和作业批改功能
class EnhancedCameraPage extends StatefulWidget {
  final CameraMode initialMode;
  const EnhancedCameraPage({super.key, this.initialMode = CameraMode.questionSolving});

  @override
  State<EnhancedCameraPage> createState() => _EnhancedCameraPageState();
}

class _EnhancedCameraPageState extends State<EnhancedCameraPage> {
  late CameraMode _currentMode;
  late final CameraService _cameraService;

  @override
  void initState() {
    super.initState();
    _cameraService = context.read<CameraService>();
    _currentMode = widget.initialMode;
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    await _cameraService.initializeCamera();
  }

  void _onImageCaptured(String imagePath) {
    // 根据当前模式跳转到不同的处理页面
    switch (_currentMode) {
      case CameraMode.questionSolving:
        Navigator.of(context).push(MaterialPageRoute(builder: (context) => QuestionSolvingPage(imagePath: imagePath)));
        break;
      case CameraMode.homeworkCorrection:
        Navigator.of(context).push(MaterialPageRoute(builder: (context) => HomeworkCorrectionPage(imagePath: imagePath)));
        break;
    }
  }

  void _onModeChanged(CameraMode mode) {
    setState(() {
      _currentMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<CameraService>(
        builder: (context, cameraService, child) {
          if (!cameraService.isInitialized) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }

          return Stack(
            children: [
              // 相机预览
              const Positioned.fill(child: CameraPreviewWidget()),

              // 顶部标题栏
              Positioned(top: 0, left: 0, right: 0, child: _buildTopBar()),

              // 拍照指引
              Positioned(top: 200, left: 0, right: 0, child: _buildGuidanceText()),

              // 相机控制按钮
              Positioned(bottom: 0, left: 0, right: 0, child: CameraControlsWidget(onCapture: _onImageCaptured)),

              // 底部功能切换
              Positioned(bottom: 120, left: 0, right: 0, child: _buildBottomTabs()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 返回按钮
            Container(
              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
              child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.of(context).pop()),
            ),

            // 标题
            Text(
              _currentMode == CameraMode.questionSolving ? '拍照解题' : '作业批改',
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
            ),

            // 帮助按钮
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(16)),
              child: InkWell(
                onTap: () => _showHelpDialog(),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.help_outline, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text('帮助', style: TextStyle(color: Colors.white, fontSize: 14)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuidanceText() {
    String guidanceText;
    switch (_currentMode) {
      case CameraMode.questionSolving:
        guidanceText = '请将题目对准参考线\n确保文字清晰可见';
        break;
      case CameraMode.homeworkCorrection:
        guidanceText = '请将作业页面完整对准画面\n确保所有内容都在框内';
        break;
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
        child: Text(guidanceText, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 16)),
      ),
    );
  }

  Widget _buildBottomTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildTabItem(title: '拍照解题', mode: CameraMode.questionSolving, icon: Icons.quiz),
          _buildTabItem(title: '作业批改', mode: CameraMode.homeworkCorrection, icon: Icons.assignment_turned_in),
        ],
      ),
    );
  }

  Widget _buildTabItem({required String title, required CameraMode mode, required IconData icon}) {
    final bool isActive = _currentMode == mode;

    return InkWell(
      onTap: () => _onModeChanged(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.green.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: isActive ? Border.all(color: Colors.green, width: 1) : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isActive ? Colors.green : Colors.white, size: 24),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: isActive ? Colors.green : Colors.white,
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(_currentMode == CameraMode.questionSolving ? '拍照解题帮助' : '作业批改帮助'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_currentMode == CameraMode.questionSolving) ...[
                const Text('拍照解题功能说明：'),
                const SizedBox(height: 8),
                const Text('1. 确保题目文字清晰可见'),
                const Text('2. 将题目完整放在画面中央'),
                const Text('3. 避免手指遮挡或阴影'),
                const Text('4. 光线充足，避免反光'),
                const Text('5. 支持数学、物理、化学等学科'),
              ] else ...[
                const Text('作业批改功能说明：'),
                const SizedBox(height: 8),
                const Text('1. 将整页作业放在画面中'),
                const Text('2. 确保所有答案都清晰可见'),
                const Text('3. 页面平整，无折痕遮挡'),
                const Text('4. 支持选择题、填空题、计算题'),
                const Text('5. 会自动检测并分析答案'),
              ],
            ],
          ),
          actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('知道了'))],
        );
      },
    );
  }

  @override
  void dispose() {
    _cameraService.disposeController();
    super.dispose();
  }
}
