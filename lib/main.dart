import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:ui';
import 'l10n/app_localizations.dart';
import 'screens/main_connection_screen.dart';
import 'screens/biometric_auth_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 데스크톱 환경에서만 window_manager 초기화
  if (isDesktop()) {
    await windowManager.ensureInitialized();
    
    WindowOptions windowOptions = const WindowOptions(
      size: Size(800, 600),
      minimumSize: Size(400, 300),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );
    
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      // 화면 크기가 800x600 이상이면 최대화
      // 800x600보다 작으면 핸드폰이므로 현재 상태 유지 (최대화하지 않음)
      final screenSize = await windowManager.getSize();
      if (screenSize.width >= 800 && screenSize.height >= 600) {
        await windowManager.maximize();
      } else {
        // 핸드폰 환경이므로 기본 크기로 표시 (최대화하지 않음)
        await windowManager.show();
        await windowManager.focus();
      }
    });
  }
  
  runApp(const MyApp());
}

bool isDesktop() {
  return [
    TargetPlatform.windows,
    TargetPlatform.macOS,
    TargetPlatform.linux,
  ].contains(defaultTargetPlatform);
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale? _locale;

  @override
  void initState() {
    super.initState();
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    // 항상 스페인어로 설정
    setState(() {
      _locale = const Locale('es', '');
    });
  }

  void changeLocale(Locale locale) async {
    // 언어 변경을 무시하고 항상 스페인어 유지
    setState(() {
      _locale = const Locale('es', '');
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Database Connection',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', ''), // Spanish (기본)
        Locale('en', ''), // English
        Locale('ko', ''), // Korean
      ],
      locale: _locale ?? const Locale('es', ''),
      home: Builder(
        builder: (context) => MainConnectionScreen(
          onLanguageChanged: changeLocale,
          currentLocale: _locale ?? const Locale('es', ''),
        ),
      ),
    );
  }
}

