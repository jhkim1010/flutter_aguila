import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Gastos 테이블 칼럼 너비를 저장·로드합니다.
class GastosColumnWidthStorage {
  static const String _key = 'gastos_column_widths';

  /// 저장된 칼럼 너비 로드. 없으면 null.
  static Future<Map<String, double>?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_key);
      if (jsonStr == null || jsonStr.isEmpty) return null;
      final map = json.decode(jsonStr) as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(k, (v is num) ? v.toDouble() : 100.0));
    } catch (e) {
      return null;
    }
  }

  /// 칼럼 너비 저장.
  static Future<void> save(Map<String, double> widths) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = json.encode(widths);
      await prefs.setString(_key, jsonStr);
    } catch (e) {
      // ignore
    }
  }
}
