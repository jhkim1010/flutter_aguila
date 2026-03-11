import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/report_utils.dart';

/// Codigos / Todocodigos 테이블 칼럼 너비를 DB별로 저장·로드합니다.
class CodigosColumnWidthStorage {
  static const String _keyPrefix = 'codigos_column_widths';

  static String _storageKey(String databaseName, ReportType reportType) {
    final suffix = reportType == ReportType.todocodigos ? 'todocodigos' : 'codigos';
    final db = databaseName.isEmpty ? 'default' : databaseName;
    return '${_keyPrefix}_${db}_$suffix';
  }

  /// 저장된 칼럼 너비 로드 (DB명 + 보고서 타입별). 없으면 null.
  static Future<Map<String, double>?> load(String databaseName, ReportType reportType) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _storageKey(databaseName, reportType);
      final jsonStr = prefs.getString(key);
      if (jsonStr == null || jsonStr.isEmpty) return null;
      final map = json.decode(jsonStr) as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(k, (v is num) ? v.toDouble() : 100.0));
    } catch (e) {
      return null;
    }
  }

  /// 칼럼 너비 저장 (DB명 + 보고서 타입별).
  static Future<void> save(String databaseName, ReportType reportType, Map<String, double> widths) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _storageKey(databaseName, reportType);
      final jsonStr = json.encode(widths);
      await prefs.setString(key, jsonStr);
    } catch (e) {
      // ignore
    }
  }
}
