import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'pages/splash_page.dart';
import 'services/camera_service.dart';
import 'services/permission_service.dart';
import 'services/enhanced_multimodal_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 设置状态栏样式
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.dark),
  );

  // 设置屏幕方向为竖屏
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const TikingApp());
}

class TikingApp extends StatelessWidget {
  const TikingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CameraService()),
        ChangeNotifierProvider(create: (_) => PermissionService()),
        ChangeNotifierProvider(create: (_) => EnhancedMultimodalService()),
      ],
      child: MaterialApp(
        title: 'Teacher Avatar',
        theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.light)),
        debugShowCheckedModeBanner: false,
        home: const SplashPage(),
      ),
    );
  }
}
