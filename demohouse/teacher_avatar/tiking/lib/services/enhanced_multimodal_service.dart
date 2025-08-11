import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

/// 增强的多模态服务 - 集成拍照解题和作业批改功能
/// 参考 multimodalkit_example 的 API 设计
class EnhancedMultimodalService extends ChangeNotifier {
  static const String _baseUrl = 'https://ark.cn-beijing.volces.com/api/v3';

  // 环境变量配置 - 实际使用时应该从配置文件或环境变量读取
  static const String _teacherModel = 'your_teacher_model';
  static const String _teacherApiKey = 'your_teacher_apikey';

  bool _isProcessing = false;
  String? _lastError;
  String? _lastResponse;

  bool get isProcessing => _isProcessing;
  String? get lastError => _lastError;
  String? get lastResponse => _lastResponse;

  /// 获取图片信息 - 对应 multimodalkit getImageInfo API
  Future<ImageInfoResult?> getImageInfo({required String imageId}) async {
    _isProcessing = true;
    _lastError = null;
    notifyListeners();

    try {
      final file = File(imageId);
      if (!await file.exists()) {
        throw Exception('Image file not found: $imageId');
      }

      // 读取图片并转换为base64
      final bytes = await file.readAsBytes();
      final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      _isProcessing = false;
      notifyListeners();

      return ImageInfoResult(
        base64Image: base64Image,
        imageId: imageId,
        location: '位置信息', // 可以集成地理位置服务
      );
    } catch (e) {
      _lastError = e.toString();
      _isProcessing = false;
      notifyListeners();
      return null;
    }
  }

  /// 获取题目分割列表 - 对应 multimodalkit getQuestionSegmentList API
  Future<QuestionSegmentListResult?> getQuestionSegmentList({
    required String imageId,
    int? rotate,
    SelectRect? selectRect,
  }) async {
    _isProcessing = true;
    _lastError = null;
    notifyListeners();

    try {
      // 这里应该调用实际的AI服务进行题目检测
      // 目前返回模拟数据，实际使用时需要替换为真实的API调用
      await Future.delayed(const Duration(milliseconds: 1000));

      final imageInfo = await getImageInfo(imageId: imageId);
      if (imageInfo == null) {
        throw Exception('Failed to get image info');
      }

      // 模拟题目检测结果
      final detectedQuestions = [
        DetectedQuestion(
          questionImage: imageInfo.base64Image,
          cornerPoints: [
            CornerPoint(x: 50, y: 50),
            CornerPoint(x: 300, y: 50),
            CornerPoint(x: 300, y: 150),
            CornerPoint(x: 50, y: 150),
          ],
          boundingBox: QuestionBoundingBox(
            centerX: 175,
            centerY: 100,
            width: 250,
            height: 100,
            left: 50,
            top: 50,
            right: 300,
            bottom: 150,
          ),
        ),
        DetectedQuestion(
          questionImage: imageInfo.base64Image,
          cornerPoints: [
            CornerPoint(x: 50, y: 200),
            CornerPoint(x: 300, y: 200),
            CornerPoint(x: 300, y: 350),
            CornerPoint(x: 50, y: 350),
          ],
          boundingBox: QuestionBoundingBox(
            centerX: 175,
            centerY: 275,
            width: 250,
            height: 150,
            left: 50,
            top: 200,
            right: 300,
            bottom: 350,
          ),
        ),
      ];

      _isProcessing = false;
      notifyListeners();

      return QuestionSegmentListResult(
        pass: true,
        status: 0,
        midBoxIndex: 0,
        detectedQuestions: detectedQuestions,
      );
    } catch (e) {
      _lastError = e.toString();
      _isProcessing = false;
      notifyListeners();
      return null;
    }
  }

  /// 获取物体检测列表 - 对应 multimodalkit getObjectDetectList API
  Future<ObjectDetectListResult?> getObjectDetectList({
    required String imageId,
  }) async {
    _isProcessing = true;
    _lastError = null;
    notifyListeners();

    try {
      // 这里应该调用实际的物体检测服务
      // 目前返回模拟数据
      await Future.delayed(const Duration(milliseconds: 800));

      final detectedObjects = [
        DetectedObject(
          centerX: 150,
          centerY: 100,
          width: 100,
          height: 80,
          name: '文字内容',
        ),
        DetectedObject(
          centerX: 250,
          centerY: 200,
          width: 120,
          height: 90,
          name: '数学公式',
        ),
      ];

      _isProcessing = false;
      notifyListeners();

      return ObjectDetectListResult(detectedObjects: detectedObjects);
    } catch (e) {
      _lastError = e.toString();
      _isProcessing = false;
      notifyListeners();
      return null;
    }
  }

  /// VLM对话 - 拍照解题功能
  Future<ChatCompletionResult?> chatCompletion({
    required String base64Image,
    required String query,
    String? prompt,
    CameraMode mode = CameraMode.questionSolving,
  }) async {
    _isProcessing = true;
    _lastError = null;
    notifyListeners();

    try {
      final systemPrompt = _getSystemPrompt(mode, prompt);

      final response = await http.post(
        Uri.parse('$_baseUrl/bots/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_teacherApiKey',
        },
        body: jsonEncode({
          'model': _teacherModel,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {
              'role': 'user',
              'content': [
                {'type': 'text', 'text': query},
                {
                  'type': 'image_url',
                  'image_url': {'url': base64Image},
                },
              ],
            },
          ],
          'stream': false,
          'metadata': {
            'mode': mode == CameraMode.homeworkCorrection ? 'correct' : 'solve',
          },
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('HTTP error! status: ${response.statusCode}');
      }

      final responseData = jsonDecode(response.body);
      final answer =
          responseData['choices']?[0]?['message']?['content'] ?? '未收到回复';

      _isProcessing = false;
      notifyListeners();

      return ChatCompletionResult(answer: answer);
    } catch (e) {
      _lastError = e.toString();
      _isProcessing = false;
      notifyListeners();
      return null;
    }
  }

  /// VLM流式对话 - 拍照解题功能
  Future<ChatCompletionStreamingResult?> chatCompletionStreaming({
    required String base64Image,
    required String query,
    String? prompt,
    CameraMode mode = CameraMode.questionSolving,
  }) async {
    _isProcessing = true;
    _lastError = null;
    notifyListeners();

    try {
      // 获取系统提示（用于未来实现）
      _getSystemPrompt(mode, prompt);
      final streamingId = DateTime.now().millisecondsSinceEpoch.toString();

      // 这里应该创建实际的流式连接
      // 目前返回模拟的streamingId

      _isProcessing = false;
      notifyListeners();

      return ChatCompletionStreamingResult(streamingId: streamingId);
    } catch (e) {
      _lastError = e.toString();
      _isProcessing = false;
      notifyListeners();
      return null;
    }
  }

  /// 读取流式对话内容
  Future<CompletionStreamingReadResult?> readCompletionStreaming({
    required String streamingId,
  }) async {
    try {
      // 这里应该读取实际的流式内容
      // 目前返回模拟数据
      await Future.delayed(const Duration(milliseconds: 200));

      // 模拟逐步返回内容
      final responses = [
        '这道题考查的是...',
        '解题思路如下：\n1. 首先观察题目条件\n2. 确定解题方法',
        '具体步骤：\n第一步：...\n第二步：...',
        '因此，答案是：...',
      ];

      final currentIndex =
          DateTime.now().millisecondsSinceEpoch % responses.length;
      final isFinished = currentIndex >= responses.length - 1;

      return CompletionStreamingReadResult(
        newText: responses[currentIndex],
        isFinished: isFinished,
      );
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// 获取SAM分割信息 - 作业批改功能
  Future<SAMInfoResult?> getSAMInfo({
    required String imageId,
    List<SAMPoint>? points,
    List<SAMRectangle>? rectangles,
    int? contourTopN,
  }) async {
    _isProcessing = true;
    _lastError = null;
    notifyListeners();

    try {
      // 这里应该调用实际的SAM分割服务
      // 目前返回模拟数据
      await Future.delayed(const Duration(milliseconds: 1000));

      final maskContour = [
        [
          [100.0, 100.0],
          [200.0, 100.0],
          [200.0, 200.0],
          [100.0, 200.0],
        ],
      ];

      _isProcessing = false;
      notifyListeners();

      return SAMInfoResult(
        maskContour: maskContour,
        segId: 'seg_${DateTime.now().millisecondsSinceEpoch}',
      );
    } catch (e) {
      _lastError = e.toString();
      _isProcessing = false;
      notifyListeners();
      return null;
    }
  }

  /// 根据相机模式获取系统提示
  String _getSystemPrompt(CameraMode mode, String? customPrompt) {
    if (customPrompt != null && customPrompt.isNotEmpty) {
      return customPrompt;
    }

    switch (mode) {
      case CameraMode.questionSolving:
        return '''
你是一个专业的教学助手，擅长解答各种学科问题。请根据图片中的题目内容：
1. 仔细分析题目要求和条件
2. 提供清晰的解题思路和步骤
3. 给出准确的答案
4. 如果是数学题，请显示详细的计算过程
5. 如果是其他学科，请提供相关的知识点解释

请用简洁易懂的语言回答，帮助学生理解解题过程。
        ''';
      case CameraMode.homeworkCorrection:
        return '''
你是一个专业的作业批改助手。请根据图片中的作业内容：
1. 检查答案的正确性
2. 指出错误之处（如果有的话）
3. 提供正确的解答过程
4. 给出改进建议
5. 评估整体完成质量

请用鼓励性的语言给出反馈，既要指出问题，也要肯定做得好的地方。
        ''';
    }
  }

  /// 清除错误状态
  void clearError() {
    _lastError = null;
    notifyListeners();
  }
}

/// 相机模式枚举
enum CameraMode { homeworkCorrection, questionSolving }

/// 图片信息结果
class ImageInfoResult {
  final String base64Image;
  final String imageId;
  final String location;

  ImageInfoResult({
    required this.base64Image,
    required this.imageId,
    required this.location,
  });
}

/// 选择区域
class SelectRect {
  final double left;
  final double top;
  final double right;
  final double bottom;

  SelectRect({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  Map<String, dynamic> toJson() {
    return {'left': left, 'top': top, 'right': right, 'bottom': bottom};
  }
}

/// 角点坐标
class CornerPoint {
  final double x;
  final double y;

  CornerPoint({required this.x, required this.y});

  Map<String, dynamic> toJson() {
    return {'x': x, 'y': y};
  }
}

/// 题目边界框
class QuestionBoundingBox {
  final double centerX;
  final double centerY;
  final double width;
  final double height;
  final double left;
  final double top;
  final double right;
  final double bottom;

  QuestionBoundingBox({
    required this.centerX,
    required this.centerY,
    required this.width,
    required this.height,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  Map<String, dynamic> toJson() {
    return {
      'centerX': centerX,
      'centerY': centerY,
      'width': width,
      'height': height,
      'left': left,
      'top': top,
      'right': right,
      'bottom': bottom,
    };
  }
}

/// 检测到的题目
class DetectedQuestion {
  final String questionImage;
  final List<CornerPoint> cornerPoints;
  final QuestionBoundingBox boundingBox;

  DetectedQuestion({
    required this.questionImage,
    required this.cornerPoints,
    required this.boundingBox,
  });

  Map<String, dynamic> toJson() {
    return {
      'questionImage': questionImage,
      'cornerPoints': cornerPoints.map((p) => p.toJson()).toList(),
      'boundingBox': boundingBox.toJson(),
    };
  }
}

/// 题目分割列表结果
class QuestionSegmentListResult {
  final bool pass;
  final int status;
  final int midBoxIndex;
  final List<DetectedQuestion> detectedQuestions;

  QuestionSegmentListResult({
    required this.pass,
    required this.status,
    required this.midBoxIndex,
    required this.detectedQuestions,
  });

  Map<String, dynamic> toJson() {
    return {
      'pass': pass,
      'status': status,
      'midBoxIndex': midBoxIndex,
      'detectedQuestions': detectedQuestions.map((q) => q.toJson()).toList(),
    };
  }
}

/// 检测到的物体
class DetectedObject {
  final double centerX;
  final double centerY;
  final double width;
  final double height;
  final String name;

  DetectedObject({
    required this.centerX,
    required this.centerY,
    required this.width,
    required this.height,
    required this.name,
  });

  Map<String, dynamic> toJson() {
    return {
      'centerX': centerX,
      'centerY': centerY,
      'width': width,
      'height': height,
      'name': name,
    };
  }
}

/// 物体检测列表结果
class ObjectDetectListResult {
  final List<DetectedObject> detectedObjects;

  ObjectDetectListResult({required this.detectedObjects});

  Map<String, dynamic> toJson() {
    return {'detectedObjects': detectedObjects.map((o) => o.toJson()).toList()};
  }
}

/// 对话完成结果
class ChatCompletionResult {
  final String answer;

  ChatCompletionResult({required this.answer});
}

/// 对话流式结果
class ChatCompletionStreamingResult {
  final String streamingId;

  ChatCompletionStreamingResult({required this.streamingId});
}

/// 流式读取结果
class CompletionStreamingReadResult {
  final String newText;
  final bool isFinished;

  CompletionStreamingReadResult({
    required this.newText,
    required this.isFinished,
  });
}

/// SAM点
class SAMPoint {
  final double x;
  final double y;
  final int label; // 0表示exclude，1表示include

  SAMPoint({required this.x, required this.y, required this.label});

  Map<String, dynamic> toJson() {
    return {'x': x, 'y': y, 'label': label};
  }
}

/// SAM矩形
class SAMRectangle {
  final double top;
  final double left;
  final double right;
  final double bottom;

  SAMRectangle({
    required this.top,
    required this.left,
    required this.right,
    required this.bottom,
  });

  Map<String, dynamic> toJson() {
    return {'top': top, 'left': left, 'right': right, 'bottom': bottom};
  }
}

/// SAM信息结果
class SAMInfoResult {
  final List<List<List<double>>> maskContour;
  final String segId;

  SAMInfoResult({required this.maskContour, required this.segId});

  Map<String, dynamic> toJson() {
    return {'maskContour': maskContour, 'segId': segId};
  }
}
