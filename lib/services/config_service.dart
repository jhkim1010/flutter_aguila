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
  
  /// Resumen del Día 보고서 설정 가져오기
  /// ventas 설정을 재사용함
  Map<String, dynamic>? getResumenDelDiaConfig() {
    return getVentasConfig();
  }
  
  /// 특정 필드 표시 여부 확인 (Ventas 보고서용)
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
  
  /// Resumen del Día 보고서의 특정 필드 표시 여부 확인
  /// 항상 표시되어야 하는 필드: operation_count (evento de venta), total_count_ropas, last_venta_hour (ultima venta)
  /// ventas 설정을 재사용함
  bool shouldShowResumenField(String fieldKey) {
    // 항상 표시되어야 하는 필드들
    if (fieldKey == 'operation_count' || 
        fieldKey == 'total_count_ropas' || 
        fieldKey == 'last_venta_hour') {
      return true; // 항상 표시
    }
    
    // ventas 설정을 재사용
    final ventasConfig = getVentasConfig();
    if (ventasConfig == null) return true; // 기본값: 표시
    
    // 필드 키 매핑: resumenDelDia 필드를 ventas 설정으로 매핑
    switch (fieldKey) {
      case 'total_venta_day':
        // tpago는 전체 결제를 의미하므로 showTpago 사용
        return ventasConfig['showTpago'] as bool? ?? true;
      case 'total_efectivo_day':
        return ventasConfig['showTefectivo'] as bool? ?? true;
      case 'total_credito_day':
        // credito는 treservado와 유사하므로 showTreservado 사용
        return ventasConfig['showTreservado'] as bool? ?? true;
      case 'total_banco_day':
        // banco는 treservado와 유사하므로 showTreservado 사용
        return ventasConfig['showTreservado'] as bool? ?? true;
      case 'total_favor_day':
        return ventasConfig['showTfavor'] as bool? ?? true;
      default:
        return true;
    }
  }
  
  /// 설정 업데이트 및 저장 (Ventas 보고서용)
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
  
  /// 설정 업데이트 및 저장 (Resumen del Día 보고서용)
  /// ventas 설정을 업데이트함
  Future<void> updateResumenDelDiaConfig({
    bool? showTotalVentaDay,
    bool? showTotalEfectivoDay,
    bool? showTotalCreditoDay,
    bool? showTotalBancoDay,
    bool? showTotalFavorDay,
  }) async {
    // ventas 설정을 업데이트
    await updateVentasConfig(
      showTpago: showTotalVentaDay,
      showTefectivo: showTotalEfectivoDay,
      showTreservado: showTotalCreditoDay ?? showTotalBancoDay,
      showTfavor: showTotalFavorDay,
    );
  }
  
  /// 새롭게 기록한 내용을 적용할 변수
  /// 이 변수는 향후 새로운 설정을 추가할 때 사용할 수 있습니다
  Map<String, dynamic>? _newConfig;
  
  /// 새 설정 가져오기
  Map<String, dynamic>? getNewConfig() => _newConfig;
  
  /// 새 설정 설정하기
  void setNewConfig(Map<String, dynamic>? config) {
    _newConfig = config;
  }
  
  /// 새 설정 초기화
  void initializeNewConfig() {
    _newConfig = {};
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
