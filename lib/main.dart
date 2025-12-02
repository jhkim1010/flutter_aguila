import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';
import 'l10n/app_localizations.dart';
import 'screens/main_connection_screen.dart';

void main() {
  runApp(const MyApp());
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
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString('app_language');
    
    if (savedLanguage != null) {
      setState(() {
        _locale = Locale(savedLanguage, '');
      });
    } else {
      // 저장된 언어가 없으면 시스템 언어 사용
      final systemLocale = PlatformDispatcher.instance.locale;
      final languageCode = systemLocale.languageCode;
      
      // 지원하는 언어인지 확인
      if (['ko', 'en', 'es'].contains(languageCode)) {
        setState(() {
          _locale = Locale(languageCode, '');
        });
      } else {
        // 지원하지 않는 언어면 스페인어로 폴백
        setState(() {
          _locale = const Locale('es', '');
        });
      }
    }
  }

  void changeLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', locale.languageCode);
    setState(() {
      _locale = locale;
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

