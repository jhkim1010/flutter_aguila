import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 설정 서비스 클래스
/// config.json 파일을 읽고, SharedPreferences에 저장하여 런타임에 수정 가능하게 함
class ConfigService {
  static const String _configAssetPath = 'assets/config.json';
  static const String _prefsKey = 'app_config';
  
  static ConfigService? _instance;
  Map<String, dynamic>? _config;
  
  ConfigService._();
  
  factory ConfigService() {
    _instance ??= ConfigService._();
    return _instance!;
  }
  
  /// 초기화: assets/config.json을 읽고 SharedPreferences와 병합
  Future<void> initialize() async {
    try {
      // assets/config.json 읽기
      final String jsonString = await rootBundle.loadString(_configAssetPath);
      final Map<String, dynamic> assetConfig = json.decode(jsonString);
      
      // SharedPreferences에서 저장된 설정 읽기
      final prefs = await SharedPreferences.getInstance();
      final String? savedConfigJson = prefs.getString(_prefsKey);
      
      if (savedConfigJson != null) {
        // 저장된 설정이 있으면 병합 (저장된 설정이 우선)
        final Map<String, dynamic> savedConfig = json.decode(savedConfigJson);
        _config = _mergeConfigs(assetConfig, savedConfig);
      } else {
        // 저장된 설정이 없으면 asset 설정 사용
        _config = assetConfig;
      }
    } catch (e) {
      print('⚠️ ConfigService 초기화 실패: $e');
      // 기본 설정 사용
      _config = {
        'report': {
          'ventas': {
            'showTpago': true,
            'showTefectivo': true,
            'showTreservado': true,
            'showTfavor': true,
          }
        }
      };
    }
  }
  
  /// 설정 병합 (savedConfig가 우선)
  Map<String, dynamic> _mergeConfigs(
    Map<String, dynamic> assetConfig,
    Map<String, dynamic> savedConfig,
  ) {
    final merged = Map<String, dynamic>.from(assetConfig);
    
    savedConfig.forEach((key, value) {
      if (value is Map<String, dynamic> && merged[key] is Map<String, dynamic>) {
        merged[key] = _mergeConfigs(
          merged[key] as Map<String, dynamic>,
          value,
        );
      } else {
        merged[key] = value;
      }
    });
    
    return merged;
  }
  
  /// 설정 가져오기
  Map<String, dynamic>? getConfig() => _config;
  
  /// Ventas 보고서 설정 가져오기
  Map<String, dynamic>? getVentasConfig() {
    return _config?['report']?['ventas'] as Map<String, dynamic>?;
  }
  
  /// 특정 필드 표시 여부 확인
  bool shouldShowField(String fieldName) {
    final ventasConfig = getVentasConfig();
    if (ventasConfig == null) return true; // 기본값: 표시
    
    switch (fieldName) {
      case 'tpago':
        return ventasConfig['showTpago'] as bool? ?? true;
      case 'tefectivo':
        return ventasConfig['showTefectivo'] as bool? ?? true;
      case 'treservado':
        return ventasConfig['showTreservado'] as bool? ?? true;
      case 'tfavor':
        return ventasConfig['showTfavor'] as bool? ?? true;
      default:
        return true;
    }
  }
  
  /// 설정 업데이트 및 저장
  Future<void> updateVentasConfig({
    bool? showTpago,
    bool? showTefectivo,
    bool? showTreservado,
    bool? showTfavor,
  }) async {
    if (_config == null) {
      await initialize();
    }
    
    // 설정 업데이트
    _config ??= {};
    _config!['report'] ??= {};
    _config!['report']!['ventas'] ??= {};
    
    final ventasConfig = _config!['report']!['ventas'] as Map<String, dynamic>;
    
    if (showTpago != null) ventasConfig['showTpago'] = showTpago;
    if (showTefectivo != null) ventasConfig['showTefectivo'] = showTefectivo;
    if (showTreservado != null) ventasConfig['showTreservado'] = showTreservado;
    if (showTfavor != null) ventasConfig['showTfavor'] = showTfavor;
    
    // SharedPreferences에 저장
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, json.encode(_config));
  }
  
  /// 설정 초기화 (assets/config.json으로 되돌리기)
  Future<void> resetConfig() async {
    try {
      final String jsonString = await rootBundle.loadString(_configAssetPath);
      _config = json.decode(jsonString);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
    } catch (e) {
      print('⚠️ ConfigService 초기화 실패: $e');
    }
  }
}
