import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

class MultimodalService extends ChangeNotifier {
  static const String _baseUrl = 'https://ark.cn-beijing.volces.com/api/v3';

  // 环境变量配置 - 实际使用时应该从配置文件或环境变量读取
  static const String _vlmModel = 'your_vlm_model';
  static const String _teacherModel = 'your_teacher_model';
  static const String _teacherApiKey = 'your_teacher_apikey';
  static const String _deepSeekModel = 'deepseek_model';

  bool _isProcessing = false;
  String? _lastError;
  String? _lastResponse;

  bool get isProcessing => _isProcessing;
  String? get lastError => _lastError;
  String? get lastResponse => _lastResponse;

  /// VLM 图像识别聊天
  Future<Stream<String>> vlmChat(String imagePath, CameraMode mode) async {
    _isProcessing = true;
    _lastError = null;
    notifyListeners();

    try {
      // 上传图片并获取URL
      final imageUrl = await _uploadImage(imagePath);

      final response = await http.post(
        Uri.parse('$_baseUrl/bots/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_teacherApiKey',
          'Accept': 'text/event-stream',
        },
        body: jsonEncode({
          'model': _teacherModel,
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'image_url',
                  'image_url': {
                    'url': imageUrl,
                  },
                },
              ],
            },
          ],
          'stream': true,
          if (mode == CameraMode.homeworkCorrection)
            'metadata': {
              'mode': 'correct',
            },
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('HTTP error! status: ${response.statusCode}');
      }

      return _parseStreamResponse(response);
    } catch (e) {
      _lastError = e.toString();
      _isProcessing = false;
      notifyListeners();
      rethrow;
    }
  }

  /// 聊天对话
  Future<Stream<String>> chat(List<ChatMessage> messages) async {
    _isProcessing = true;
    _lastError = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/bots/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_teacherApiKey',
          'Accept': 'text/event-stream',
        },
        body: jsonEncode({
          'model': _teacherModel,
          'messages': messages.map((m) => m.toJson()).toList(),
          'stream': true,
          'metadata': {
            'mode': 'chat',
          },
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('HTTP error! status: ${response.statusCode}');
      }

      return _parseStreamResponse(response);
    } catch (e) {
      _lastError = e.toString();
      _isProcessing = false;
      notifyListeners();
      rethrow;
    }
  }

  /// 解析流式响应
  Stream<String> _parseStreamResponse(http.Response response) async* {
    final lines = response.body.split('\n');

    for (final line in lines) {
      if (line.isEmpty) continue;

      final jsonStr = line.replaceFirst('data: ', '').trim();
      if (jsonStr == '[DONE]') break;

      if (jsonStr.isNotEmpty) {
        try {
          final json = jsonDecode(jsonStr);
          final choices = json['choices'] as List?;
          if (choices != null && choices.isNotEmpty) {
            final choice = choices[0];
            final delta = choice['delta'];
            final content = delta?['content'] as String?;

            if (content != null && content.isNotEmpty) {
              yield content;
            }

            if (choice['finish_reason'] != null) {
              break;
            }
          }
        } catch (e) {
          debugPrint('Failed to parse JSON: $e, Raw data: $jsonStr');
        }
      }
    }

    _isProcessing = false;
    notifyListeners();
  }

  /// 上传图片到服务器
  Future<String> _uploadImage(String imagePath) async {
    // 这里应该实现实际的图片上传逻辑
    // 暂时返回本地文件路径，实际使用时需要上传到云存储
    final file = File(imagePath);
    if (!await file.exists()) {
      throw Exception('Image file not found: $imagePath');
    }

    // 临时实现：将文件转换为base64
    final bytes = await file.readAsBytes();
    final base64String = base64Encode(bytes);
    return 'data:image/jpeg;base64,$base64String';
  }

  /// 获取题目分割列表
  Future<List<QuestionSegment>> getQuestionSegmentList(String imageId) async {
    try {
      // 这里应该调用实际的题目分割API
      // 暂时返回空列表
      await Future.delayed(const Duration(milliseconds: 500));
      return [];
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
      return [];
    }
  }

  /// 获取图像信息
  Future<ImageInfo?> getImageInfo(String imageId) async {
    try {
      final file = File(imageId);
      if (await file.exists()) {
        final stats = await file.stat();
        final bytes = await file.readAsBytes();

        return ImageInfo(
          path: imageId,
          size: stats.size,
          width: 0, // 实际使用时需要解析图片获取尺寸
          height: 0,
          format: path.extension(imageId),
          data: bytes,
        );
      }
      return null;
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// 清除错误状态
  void clearError() {
    _lastError = null;
    notifyListeners();
  }
}

/// 相机模式枚举
enum CameraMode {
  homeworkCorrection,
  questionSolving,
}

/// 聊天消息模型
class ChatMessage {
  final String role;
  final dynamic content;

  ChatMessage({required this.role, required this.content});

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': content,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      role: json['role'],
      content: json['content'],
    );
  }
}

/// 题目分割模型
class QuestionSegment {
  final String id;
  final Map<String, double> boundingBox;
  final String? text;

  QuestionSegment({
    required this.id,
    required this.boundingBox,
    this.text,
  });

  factory QuestionSegment.fromJson(Map<String, dynamic> json) {
    return QuestionSegment(
      id: json['id'],
      boundingBox: Map<String, double>.from(json['boundingBox']),
      text: json['text'],
    );
  }
}

/// 图像信息模型
class ImageInfo {
  final String path;
  final int size;
  final int width;
  final int height;
  final String format;
  final List<int> data;

  ImageInfo({
    required this.path,
    required this.size,
    required this.width,
    required this.height,
    required this.format,
    required this.data,
  });
}
