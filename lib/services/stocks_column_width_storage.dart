import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Stocks 테이블 칼럼 너비를 DB별로 저장·로드합니다.
class StocksColumnWidthStorage {
  static const String _keyPrefix = 'stocks_column_widths';

  static String _storageKey(String databaseName) {
    final db = databaseName.isEmpty ? 'default' : databaseName;
    return '${_keyPrefix}_$db';
  }

  /// 저장된 칼럼 너비 로드 (DB명별). 없으면 null.
  static Future<Map<String, double>?> load(String databaseName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _storageKey(databaseName);
      final jsonStr = prefs.getString(key);
      if (jsonStr == null || jsonStr.isEmpty) return null;
      final map = json.decode(jsonStr) as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(k, (v is num) ? v.toDouble() : 100.0));
    } catch (e) {
      return null;
    }
  }

  /// 칼럼 너비 저장 (DB명별).
  static Future<void> save(String databaseName, Map<String, double> widths) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _storageKey(databaseName);
      final jsonStr = json.encode(widths);
      await prefs.setString(key, jsonStr);
    } catch (e) {
      // ignore
    }
  }
}
