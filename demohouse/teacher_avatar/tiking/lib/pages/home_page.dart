import 'package:flutter/material.dart';
import 'enhanced_camera_page.dart';
import '../services/enhanced_multimodal_service.dart';

/// 主页面 - 提供功能选择
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('教师分身'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 40),

            // 标题
            const Text('AI教学助手', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87)),

            const SizedBox(height: 10),

            const Text('选择您需要的功能', style: TextStyle(fontSize: 16, color: Colors.grey)),

            const SizedBox(height: 50),

            // 功能选择卡片
            Expanded(
              child: Column(
                children: [
                  // 拍照解题和作业批改功能
                  _buildFeatureCard(
                    context,
                    title: '智能解题批改',
                    subtitle: '拍照解题 • 作业批改 • AI分析',
                    description: '使用AI技术快速解答题目\n智能批改学生作业\n提供详细解析和建议',
                    icon: Icons.psychology,
                    gradient: const LinearGradient(
                      colors: [Colors.green, Colors.teal],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const EnhancedCameraPage())),
                  ),

                  const SizedBox(height: 20),

                  // 作业批改入口（直接进入增强相机并默认作业批改模式）
                  _buildFeatureCard(
                    context,
                    title: '作业批改',
                    subtitle: '整页批改 • 错因分析 • 建议',
                    description: '对整页作业进行检测\n指出错误并提供建议\n支持多题型',
                    icon: Icons.assignment_turned_in,
                    gradient: const LinearGradient(
                      colors: [Colors.orange, Colors.deepOrange],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap:
                        () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const EnhancedCameraPage(initialMode: CameraMode.homeworkCorrection)),
                        ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 底部信息
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[100]!),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '智能解题批改功能使用先进的AI技术，可以快速准确地分析题目和批改作业，是教师和学生的得力助手。',
                      style: TextStyle(color: Colors.blue, fontSize: 14, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String description,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            // 图标
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 32, color: Colors.white),
            ),

            const SizedBox(width: 20),

            // 文本内容
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),

                  const SizedBox(height: 4),

                  Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.w500)),

                  const SizedBox(height: 8),

                  Text(description, style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.8), height: 1.3)),
                ],
              ),
            ),

            // 箭头
            Icon(Icons.arrow_forward_ios, color: Colors.white.withValues(alpha: 0.8), size: 16),
          ],
        ),
      ),
    );
  }
}
