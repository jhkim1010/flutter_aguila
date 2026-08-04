/// Resumen del Día 응답을 지점(sucursal)별로 가르는 유틸.
///
/// 서버는 지점 필터 없이 요청하면 전 지점 데이터를 한 번에 내려준다.
/// 특정 지점만 보려고 서버를 다시 부를 필요가 없으므로, 응답을 그대로 두고
/// 얕은 사본에서 해당 지점 행만 남긴다.
class SucursalDataFilter {
  /// 행에서 sucursal 값을 문자열로 뽑는다.
  /// 원본이 int일 수도 String일 수도 있어 toString()으로 정규화한다.
  static String? _sucursalOf(Map item) {
    final value = item['sucursal'];
    if (value == null) return null;
    return value.toString();
  }

  /// 응답에 실제로 존재하는 sucursal 번호 목록 (숫자 오름차순).
  ///
  /// 0 이하는 버린다 — resumen_del_dia_screen의 _hasMultipleSucursales()가
  /// sucursal > 0만 세는 것과 판정 기준을 맞추기 위함이다.
  static List<String> availableSucursales(Map<String, dynamic> data) {
    final found = <int>{};

    for (final value in data.values) {
      if (value is! List) continue;
      for (final item in value) {
        if (item is! Map) continue;
        final raw = _sucursalOf(item);
        if (raw == null) continue;
        final parsed = int.tryParse(raw);
        if (parsed != null && parsed > 0) {
          found.add(parsed);
        }
      }
    }

    final sorted = found.toList()..sort();
    return sorted.map((e) => e.toString()).toList();
  }

  /// [sucursal] 행만 남긴 얕은 사본을 만든다.
  ///
  /// [sucursal]이 null이거나 비어 있으면 Total — 원본을 그대로 돌려준다.
  /// 원본 맵과 내부 행 객체는 변형하지 않는다.
  static Map<String, dynamic> filterBySucursal(
    Map<String, dynamic> data,
    String? sucursal,
  ) {
    if (sucursal == null || sucursal.isEmpty) {
      return data;
    }

    final result = <String, dynamic>{};

    data.forEach((key, value) {
      // 리스트가 아닌 값(stock_resumen Map, fecha String 등)은 지점 구분이 없다.
      if (value is! List) {
        result[key] = value;
        return;
      }

      // 행들이 sucursal 키를 아예 갖지 않는 리스트는 전역 데이터다.
      // 필터를 걸면 빈 리스트가 되어 섹션이 통째로 사라지므로 그대로 통과시킨다.
      final hasSucursalKey = value.any(
        (item) => item is Map && item.containsKey('sucursal'),
      );
      if (!hasSucursalKey) {
        result[key] = value;
        return;
      }

      result[key] = value
          .where((item) => item is Map && _sucursalOf(item) == sucursal)
          .toList();
    });

    return result;
  }
}
