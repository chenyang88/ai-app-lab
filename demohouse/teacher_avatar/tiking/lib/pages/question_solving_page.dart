import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../services/enhanced_multimodal_service.dart';

/// 拍照解题页面
class QuestionSolvingPage extends StatefulWidget {
  final String imagePath;

  const QuestionSolvingPage({super.key, required this.imagePath});

  @override
  State<QuestionSolvingPage> createState() => _QuestionSolvingPageState();
}

class _QuestionSolvingPageState extends State<QuestionSolvingPage> {
  final TextEditingController _questionController = TextEditingController();
  bool _isProcessing = false;
  String _answer = '';
  List<DetectedQuestion> _detectedQuestions = [];
  int _selectedQuestionIndex = -1;

  @override
  void initState() {
    super.initState();
    _questionController.text = '请帮我解答这道题目';
    _analyzeImage();
  }

  Future<void> _analyzeImage() async {
    setState(() {
      _isProcessing = true;
    });

    final multimodalService = context.read<EnhancedMultimodalService>();

    try {
      // 首先获取题目分割信息
      final questionSegmentResult = await multimodalService
          .getQuestionSegmentList(imageId: widget.imagePath);

      if (questionSegmentResult != null && questionSegmentResult.pass) {
        setState(() {
          _detectedQuestions = questionSegmentResult.detectedQuestions;
          _selectedQuestionIndex = questionSegmentResult.midBoxIndex;
        });
      }
    } catch (e) {
      _showErrorDialog('图像分析失败: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _solveQuestion() async {
    if (_questionController.text.trim().isEmpty) {
      _showErrorDialog('请输入问题');
      return;
    }

    setState(() {
      _isProcessing = true;
      _answer = '';
    });

    final multimodalService = context.read<EnhancedMultimodalService>();

    try {
      // 获取图片信息
      final imageInfo = await multimodalService.getImageInfo(
        imageId: widget.imagePath,
      );

      if (imageInfo != null) {
        // 调用VLM进行题目解答
        final result = await multimodalService.chatCompletion(
          base64Image: imageInfo.base64Image,
          query: _questionController.text,
          mode: CameraMode.questionSolving,
        );

        if (result != null) {
          setState(() {
            _answer = result.answer;
          });
        } else {
          _showErrorDialog('解题失败，请重试');
        }
      }
    } catch (e) {
      _showErrorDialog('解题失败: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _solveQuestionStreaming() async {
    if (_questionController.text.trim().isEmpty) {
      _showErrorDialog('请输入问题');
      return;
    }

    setState(() {
      _isProcessing = true;
      _answer = '';
    });

    final multimodalService = context.read<EnhancedMultimodalService>();

    try {
      // 获取图片信息
      final imageInfo = await multimodalService.getImageInfo(
        imageId: widget.imagePath,
      );

      if (imageInfo != null) {
        // 创建流式对话
        final streamResult = await multimodalService.chatCompletionStreaming(
          base64Image: imageInfo.base64Image,
          query: _questionController.text,
          mode: CameraMode.questionSolving,
        );

        if (streamResult != null) {
          String accumulatedAnswer = '';
          bool isFinished = false;

          // 持续读取流式内容
          while (!isFinished) {
            final readResult = await multimodalService.readCompletionStreaming(
              streamingId: streamResult.streamingId,
            );

            if (readResult != null) {
              accumulatedAnswer += readResult.newText;
              isFinished = readResult.isFinished;

              setState(() {
                _answer = accumulatedAnswer;
              });

              if (!isFinished) {
                await Future.delayed(const Duration(milliseconds: 500));
              }
            } else {
              break;
            }
          }
        }
      }
    } catch (e) {
      _showErrorDialog('解题失败: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('错误'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('拍照解题'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _analyzeImage,
            tooltip: '重新分析',
          ),
        ],
      ),
      body: Column(
        children: [
          // 图片显示区域
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(widget.imagePath),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Center(child: Text('图片加载失败')),
                    );
                  },
                ),
              ),
            ),
          ),

          // 检测到的题目列表
          if (_detectedQuestions.isNotEmpty) ...[
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text(
                    '检测到的题目：',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _detectedQuestions.length,
                      itemBuilder: (context, index) {
                        final isSelected = index == _selectedQuestionIndex;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedQuestionIndex = index;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isSelected ? Colors.blue : Colors.grey[200],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '题目 ${index + 1}',
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black,
                                fontWeight:
                                    isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],

          // 问题输入区域
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '问题描述：',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _questionController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: '请描述您想要解答的问题...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isProcessing ? null : _solveQuestion,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child:
                            _isProcessing
                                ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                : const Text('立即解答'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed:
                            _isProcessing ? null : _solveQuestionStreaming,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('流式解答'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 答案显示区域
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lightbulb, color: Colors.orange),
                      const SizedBox(width: 8),
                      const Text(
                        '解答结果：',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (_isProcessing) ...[
                        const SizedBox(width: 8),
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        _answer.isEmpty ? '请点击"立即解答"按钮开始解题...' : _answer,
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              _answer.isEmpty ? Colors.grey[600] : Colors.black,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }
}
