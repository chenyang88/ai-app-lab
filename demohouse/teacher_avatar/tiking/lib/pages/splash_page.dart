import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'home_page.dart';
import '../services/permission_service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  static const int delayMillis = 2000; // 启动页显示2秒

  @override
  void initState() {
    super.initState();
    _startMainActivity();
  }

  void _startMainActivity() {
    // 延迟后跳转到主页面
    Timer(const Duration(milliseconds: delayMillis), () async {
      if (!mounted) return;

      // 请求必要权限
      final permissionService = context.read<PermissionService>();
      await permissionService.requestCameraPermission();
      await permissionService.requestMicrophonePermission();

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 主Logo
            Image.asset(
              'assets/images/start_logo.png',
              width: 106.91,
              height: 144,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 106.91,
                  height: 144,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.image, color: Colors.grey, size: 40),
                );
              },
            ),

            const Spacer(),

            // 底部支持Logo
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Image.asset(
                'assets/images/start_support.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox(
                    height: 30,
                    child: Text(
                      'Powered by AI',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
