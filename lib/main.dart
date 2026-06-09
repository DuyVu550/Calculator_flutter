// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ui/screens/calculator_screen.dart';
import 'ui/theme/app_colors.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Cho phép xoay mọi hướng để dùng máy tính khoa học
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Thanh trạng thái trong suốt, icon màu trắng cho nền tối
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // ProviderScope bắt buộc để Riverpod hoạt động
  runApp(
    const ProviderScope(
      child: CalculatorApp(),
    ),
  );
}

class CalculatorApp extends StatelessWidget {
  const CalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Roboto',
        splashColor: Colors.white12,
        highlightColor: Colors.transparent,
      ),
      home: const CalculatorScreen(),
    );
  }
}
