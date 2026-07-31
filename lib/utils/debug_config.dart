// debugPrint가 import되지 않아 컴파일 에러가 발생했던 문제 수정
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;

/// 디버깅 설정
/// 
/// 이 파일을 통해 앱 전체의 디버깅 출력을 제어할 수 있습니다.
/// 
/// 사용법:
/// ```dart
/// if (DebugConfig.enableVerboseLogging) {
///   debugPrint('상세한 디버그 정보');
/// }
/// ```
class DebugConfig {
  /// 상세한 로깅 활성화 여부
  /// 
  /// false로 설정하면 빈번한 디버그 출력을 비활성화하여
  /// 디버그 모드에서도 성능을 개선할 수 있습니다.
  static const bool enableVerboseLogging = true;
  
  /// 테이블 빌더 디버깅 활성화 여부
  /// 
  /// report_table_builder.dart의 상세한 디버그 출력을 제어합니다.
  static const bool enableTableBuilderDebugging = true;
  
  /// 보고서 화면 디버깅 활성화 여부
  /// 
  /// report_screen.dart의 상세한 디버그 출력을 제어합니다.
  static const bool enableReportScreenDebugging = true;
  
  /// 빌더 디버깅 활성화 여부
  /// 
  /// items_builder.dart, ingresos_builder.dart 등의 디버그 출력을 제어합니다.
  static const bool enableBuilderDebugging = true;
  
  /// 디버그 모드인지 확인
  /// 
  /// 릴리즈 빌드에서는 항상 false를 반환합니다.
  static bool get isDebugMode => kDebugMode;
  
  /// 조건부 디버그 출력
  /// 
  /// enableVerboseLogging이 true이고 디버그 모드일 때만 출력합니다.
  static void debugPrintIfEnabled(String message, {bool? condition}) {
    if (kDebugMode && (condition ?? enableVerboseLogging)) {
      debugPrint(message);
    }
  }
}

