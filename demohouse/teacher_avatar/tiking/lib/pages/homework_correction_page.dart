import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../services/enhanced_multimodal_service.dart';

/// 作业批改页面
class HomeworkCorrectionPage extends StatefulWidget {
  final String imagePath;

  const HomeworkCorrectionPage({super.key, required this.imagePath});

  @override
  State<HomeworkCorrectionPage> createState() => _HomeworkCorrectionPageState();
}

class _HomeworkCorrectionPageState extends State<HomeworkCorrectionPage> {
  bool _isProcessing = false;
  String _correctionResult = '';
  List<DetectedObject> _detectedObjects = [];
  List<DetectedQuestion> _detectedQuestions = [];
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _analyzeHomework();
  }

  Future<void> _analyzeHomework() async {
    setState(() {
      _isProcessing = true;
    });

    final multimodalService = context.read<EnhancedMultimodalService>();

    try {
      // 1. 检测作业中的物体（文字、图形等）
      final objectResult = await multimodalService.getObjectDetectList(
        imageId: widget.imagePath,
      );

      if (objectResult != null) {
        setState(() {
          _detectedObjects = objectResult.detectedObjects;
        });
      }

      // 2. 检测作业中的题目
      final questionResult = await multimodalService.getQuestionSegmentList(
        imageId: widget.imagePath,
      );

      if (questionResult != null && questionResult.pass) {
        setState(() {
          _detectedQuestions = questionResult.detectedQuestions;
        });
      }

      // 3. 进行作业批改
      await _correctHomework();
    } catch (e) {
      _showErrorDialog('作业分析失败: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _correctHomework() async {
    final multimodalService = context.read<EnhancedMultimodalService>();

    try {
      // 获取图片信息
      final imageInfo = await multimodalService.getImageInfo(
        imageId: widget.imagePath,
      );

      if (imageInfo != null) {
        // 使用专门的作业批改提示进行分析
        final result = await multimodalService.chatCompletion(
          base64Image: imageInfo.base64Image,
          query: '请帮我批改这份作业，检查答案正确性，指出错误并给出建议。',
          mode: CameraMode.homeworkCorrection,
        );

        if (result != null) {
          setState(() {
            _correctionResult = result.answer;
          });
        }
      }
    } catch (e) {
      _showErrorDialog('作业批改失败: $e');
    }
  }

  Future<void> _correctSpecificQuestion(int questionIndex) async {
    if (questionIndex >= _detectedQuestions.length) return;

    setState(() {
      _isProcessing = true;
    });

    final multimodalService = context.read<EnhancedMultimodalService>();

    try {
      final question = _detectedQuestions[questionIndex];

      // 使用题目的具体图片进行批改
      final result = await multimodalService.chatCompletion(
        base64Image: question.questionImage,
        query: '请批改这道题目，检查答案是否正确，如有错误请指出并提供正确答案。',
        mode: CameraMode.homeworkCorrection,
      );

      if (result != null) {
        _showQuestionCorrectionDialog(questionIndex + 1, result.answer);
      }
    } catch (e) {
      _showErrorDialog('题目批改失败: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showQuestionCorrectionDialog(int questionNumber, String correction) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('题目 $questionNumber 批改结果'),
          content: SingleChildScrollView(child: Text(correction)),
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
        title: const Text('作业批改'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _analyzeHomework,
            tooltip: '重新分析',
          ),
        ],
        bottom: TabBar(
          controller: TabController(length: 3, vsync: Scaffold.of(context)),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          onTap: (index) {
            setState(() {
              _currentTabIndex = index;
            });
          },
          tabs: const [
            Tab(text: '整体分析', icon: Icon(Icons.assessment)),
            Tab(text: '题目检测', icon: Icon(Icons.quiz)),
            Tab(text: '物体识别', icon: Icon(Icons.visibility)),
          ],
        ),
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

          // 分析结果区域
          Expanded(flex: 3, child: _buildAnalysisResults()),
        ],
      ),
    );
  }

  Widget _buildAnalysisResults() {
    switch (_currentTabIndex) {
      case 0:
        return _buildOverallAnalysis();
      case 1:
        return _buildQuestionDetection();
      case 2:
        return _buildObjectDetection();
      default:
        return _buildOverallAnalysis();
    }
  }

  Widget _buildOverallAnalysis() {
    return Container(
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
              const Icon(Icons.school, color: Colors.green),
              const SizedBox(width: 8),
              const Text(
                '批改结果：',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                _correctionResult.isEmpty
                    ? '正在分析作业内容，请稍候...'
                    : _correctionResult,
                style: TextStyle(
                  fontSize: 14,
                  color:
                      _correctionResult.isEmpty
                          ? Colors.grey[600]
                          : Colors.black,
                  height: 1.5,
                ),
              ),
            ),
          ),
          if (_correctionResult.isNotEmpty) ...[
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _analyzeHomework(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('重新批改'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // 可以添加导出功能
                  },
                  icon: const Icon(Icons.share),
                  label: const Text('分享结果'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuestionDetection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '检测到 ${_detectedQuestions.length} 道题目',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          Expanded(
            child:
                _detectedQuestions.isEmpty
                    ? const Center(child: Text('未检测到题目，请确保图片清晰'))
                    : ListView.builder(
                      itemCount: _detectedQuestions.length,
                      itemBuilder: (context, index) {
                        final question = _detectedQuestions[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.green,
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text('题目 ${index + 1}'),
                            subtitle: Text(
                              '位置: (${question.boundingBox.centerX.toInt()}, ${question.boundingBox.centerY.toInt()})',
                            ),
                            trailing: ElevatedButton(
                              onPressed:
                                  _isProcessing
                                      ? null
                                      : () => _correctSpecificQuestion(index),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(60, 30),
                              ),
                              child: const Text('批改'),
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildObjectDetection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '检测到 ${_detectedObjects.length} 个对象',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          Expanded(
            child:
                _detectedObjects.isEmpty
                    ? const Center(child: Text('未检测到明显的对象'))
                    : ListView.builder(
                      itemCount: _detectedObjects.length,
                      itemBuilder: (context, index) {
                        final object = _detectedObjects[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue,
                              child: Icon(
                                _getObjectIcon(object.name),
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            title: Text(object.name),
                            subtitle: Text(
                              '尺寸: ${object.width.toInt()} × ${object.height.toInt()}px\n'
                              '位置: (${object.centerX.toInt()}, ${object.centerY.toInt()})',
                            ),
                            isThreeLine: true,
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  IconData _getObjectIcon(String objectName) {
    if (objectName.contains('文字') || objectName.contains('text')) {
      return Icons.text_fields;
    } else if (objectName.contains('数学') || objectName.contains('公式')) {
      return Icons.calculate;
    } else if (objectName.contains('图') || objectName.contains('image')) {
      return Icons.image;
    } else {
      return Icons.category;
    }
  }
}
