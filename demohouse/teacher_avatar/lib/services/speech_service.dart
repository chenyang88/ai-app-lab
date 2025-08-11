import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class SpeechService extends ChangeNotifier {
  bool _isListening = false;
  bool _isSpeaking = false;
  String _recognizedText = '';
  String? _lastError;

  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  String get recognizedText => _recognizedText;
  String? get lastError => _lastError;

  StreamController<String>? _asrController;
  Stream<String>? _asrStream;

  /// 开始语音识别 (ASR)
  Future<void> startASR() async {
    if (_isListening) return;

    try {
      _isListening = true;
      _lastError = null;
      _recognizedText = '';

      // 创建ASR流
      _asrController = StreamController<String>.broadcast();
      _asrStream = _asrController!.stream;

      notifyListeners();

      // 这里应该调用实际的ASR SDK
      // 暂时模拟语音识别
      _simulateASR();
    } catch (e) {
      _lastError = e.toString();
      _isListening = false;
      notifyListeners();
    }
  }

  /// 停止语音识别
  Future<void> stopASR() async {
    if (!_isListening) return;

    try {
      _isListening = false;
      _asrController?.close();
      _asrController = null;
      _asrStream = null;

      notifyListeners();
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
    }
  }

  /// 监听ASR结果
  Stream<String>? onASRResult() {
    return _asrStream;
  }

  /// 创建流式TTS
  Future<void> createStreamingTTS({
    required String text,
    String? voice,
    double? speed,
    double? pitch,
  }) async {
    if (_isSpeaking) {
      await cancelStreamingTTS();
    }

    try {
      _isSpeaking = true;
      _lastError = null;
      notifyListeners();

      // 这里应该调用实际的TTS SDK
      // 暂时模拟TTS播放
      await _simulateTTS(text);
    } catch (e) {
      _lastError = e.toString();
      _isSpeaking = false;
      notifyListeners();
    }
  }

  /// 追加流式TTS
  Future<void> appendStreamingTTS(String text) async {
    if (!_isSpeaking) {
      await createStreamingTTS(text: text);
      return;
    }

    try {
      // 这里应该追加到TTS队列
      await _simulateTTS(text);
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
    }
  }

  /// 取消流式TTS
  Future<void> cancelStreamingTTS() async {
    if (!_isSpeaking) return;

    try {
      _isSpeaking = false;
      // 这里应该停止TTS播放
      notifyListeners();
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
    }
  }

  /// 模拟ASR识别过程
  void _simulateASR() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isListening) {
        timer.cancel();
        return;
      }

      // 模拟识别结果
      final mockTexts = [
        '这是',
        '这是一道',
        '这是一道数学题',
        '这是一道数学题，请帮我解答',
      ];

      if (timer.tick <= mockTexts.length) {
        _recognizedText = mockTexts[timer.tick - 1];
        _asrController?.add(_recognizedText);
        notifyListeners();
      }

      if (timer.tick >= 4) {
        timer.cancel();
        stopASR();
      }
    });
  }

  /// 模拟TTS播放过程
  Future<void> _simulateTTS(String text) async {
    // 根据文本长度计算播放时间
    final duration = Duration(milliseconds: text.length * 100);
    await Future.delayed(duration);

    _isSpeaking = false;
    notifyListeners();
  }

  /// 清除错误状态
  void clearError() {
    _lastError = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _asrController?.close();
    super.dispose();
  }
}

/// TTS配置选项
class TTSOptions {
  final String text;
  final String? voice;
  final double? speed;
  final double? pitch;
  final double? volume;

  TTSOptions({
    required this.text,
    this.voice,
    this.speed,
    this.pitch,
    this.volume,
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      if (voice != null) 'voice': voice,
      if (speed != null) 'speed': speed,
      if (pitch != null) 'pitch': pitch,
      if (volume != null) 'volume': volume,
    };
  }
}

/// ASR结果模型
class ASRResult {
  final String text;
  final bool isFinished;
  final double? confidence;

  ASRResult({
    required this.text,
    required this.isFinished,
    this.confidence,
  });

  factory ASRResult.fromJson(Map<String, dynamic> json) {
    return ASRResult(
      text: json['text'] ?? '',
      isFinished: json['isFinished'] ?? false,
      confidence: json['confidence']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isFinished': isFinished,
      if (confidence != null) 'confidence': confidence,
    };
  }
}
