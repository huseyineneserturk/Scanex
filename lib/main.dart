import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_theme.dart';
import 'providers/exam_provider.dart';
import 'providers/results_provider.dart';

import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));



  // Load exams
  final examProvider = ExamProvider();
  await examProvider.loadExams();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: examProvider),
        ChangeNotifierProvider(create: (_) => ResultsProvider()),

      ],
      child: const ScanexApp(),
    ),
  );
}

class ScanexApp extends StatelessWidget {
  const ScanexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scanex',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}
