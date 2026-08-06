/// FVentas 응답의 `summary` 블록.
///
/// 서버(routes/fventas.js)가 요청 기간 **전체**를 집계해서 준다. `data` 는
/// limit=100 으로 잘려 오지만 `summary` 는 기간 전체 기준이므로, 푸터는
/// 페이지를 다 받지 않아도 정확한 합계를 그릴 수 있다.
///
/// 응답 예시:
/// ```json
/// "summary": {
///   "iva_rate": 0.21,
///   "monto_incluye_iva": true,
///   "facturas":      { "subtotal": {...}, "A": {...}, "B": {...}, "C": {...}, "M": {...} },
///   "notas_debito":  { ... },
///   "notas_credito": { ... },
///   "otros": [],
///   "total": { "count": 498, "monto": 68703800, "neto": 56780000, "iva": 11923800 }
/// }
/// ```
///
/// 총합 규칙(서버가 이미 반영해서 `total` 로 준다):
///   monto = facturas + notas_debito - notas_credito
///   count = facturas + notas_debito + notas_credito  (건수는 빼지 않는다)
library;

/// 한 칸의 집계값: 건수와 금액(총액/순액/IVA).
class FventasAmount {
  final int count;

  /// 세금 포함 금액 (`monto_incluye_iva` 가 true 일 때)
  final double monto;

  /// 세금 제외 금액
  final double neto;

  final double iva;

  const FventasAmount({
    this.count = 0,
    this.monto = 0,
    this.neto = 0,
    this.iva = 0,
  });

  static const FventasAmount zero = FventasAmount();

  bool get isEmpty => count == 0 && monto == 0;

  factory FventasAmount.fromJson(Map<String, dynamic> json) => FventasAmount(
        count: _toInt(json['count']),
        monto: _toDouble(json['monto']),
        neto: _toDouble(json['neto']),
        iva: _toDouble(json['iva']),
      );

  FventasAmount operator +(FventasAmount other) => FventasAmount(
        count: count + other.count,
        monto: monto + other.monto,
        neto: neto + other.neto,
        iva: iva + other.iva,
      );

  @override
  String toString() =>
      'count=$count, monto=$monto, neto=$neto, iva=$iva';
}

/// Factura / Nota de Débito / Nota de Crédito 한 묶음.
///
/// 서버는 letra(A/B/C/M)별 칸과 `subtotal` 을 함께 준다. 서버가 A~M 말고
/// 다른 letra 를 보내더라도 버리지 않고 그대로 담는다.
class FventasGroup {
  /// letra → 집계값 ('A', 'B', 'C', 'M', 그 밖의 값도 올 수 있다)
  final Map<String, FventasAmount> byLetra;

  final FventasAmount subtotal;

  const FventasGroup({
    this.byLetra = const {},
    this.subtotal = FventasAmount.zero,
  });

  static const FventasGroup empty = FventasGroup();

  /// 표시 순서. A, B, C, M 을 먼저 놓고 나머지는 알파벳순으로 뒤에 붙인다.
  static const List<String> _letraOrder = ['A', 'B', 'C', 'M'];

  List<String> get letras {
    final known = _letraOrder.where(byLetra.containsKey).toList();
    final rest = byLetra.keys.where((l) => !_letraOrder.contains(l)).toList()
      ..sort();
    return [...known, ...rest];
  }

  factory FventasGroup.fromJson(Map<String, dynamic> json) {
    final byLetra = <String, FventasAmount>{};
    FventasAmount? subtotal;

    json.forEach((key, value) {
      if (value is! Map) return;
      final amount = FventasAmount.fromJson(Map<String, dynamic>.from(value));
      if (key == 'subtotal') {
        subtotal = amount;
      } else {
        byLetra[key.toUpperCase()] = amount;
      }
    });

    // subtotal 이 없으면 letra 들을 더해서 만든다.
    return FventasGroup(
      byLetra: byLetra,
      subtotal: subtotal ??
          byLetra.values.fold(FventasAmount.zero, (sum, a) => sum + a),
    );
  }

  @override
  String toString() => 'subtotal($subtotal), letras=${byLetra.keys.toList()}';
}

/// 세 그룹 어디에도 안 들어가는 comprobante.
class FventasOtro {
  /// 화면에 그대로 보여줄 이름 (tipofactura 코드 또는 서버가 준 라벨)
  final String label;
  final FventasAmount amount;

  const FventasOtro(this.label, this.amount);

  factory FventasOtro.fromJson(Map<String, dynamic> json) {
    final label = (json['tipofactura'] ??
            json['tipo'] ??
            json['codigo'] ??
            json['label'] ??
            '?')
        .toString();
    return FventasOtro(label, FventasAmount.fromJson(json));
  }
}

class FventasSummary {
  /// 서버가 알려준 IVA 세율 (예: 0.21)
  final double ivaRate;

  /// monto 가 IVA 포함 금액인지. true 면 neto = monto / (1 + ivaRate).
  final bool montoIncluyeIva;

  final FventasGroup facturas;
  final FventasGroup notasDebito;
  final FventasGroup notasCredito;
  final List<FventasOtro> otros;
  final FventasAmount total;

  /// 서버 `summary` 블록에서 온 값인지. false 면 화면에 받아둔 행으로 직접
  /// 계산한 값이라 기간 전체가 아닐 수 있다.
  final bool fromServer;

  const FventasSummary({
    required this.ivaRate,
    required this.montoIncluyeIva,
    required this.facturas,
    required this.notasDebito,
    required this.notasCredito,
    required this.otros,
    required this.total,
    required this.fromServer,
  });

  static const double defaultIvaRate = 0.21;

  /// 서버 응답의 `summary` 블록을 읽는다. 블록이 없거나 모양이 다르면 null.
  static FventasSummary? fromJson(dynamic json) {
    if (json is! Map) return null;
    final map = Map<String, dynamic>.from(json);

    final facturas = _group(map['facturas']);
    final notasDebito = _group(map['notas_debito']);
    final notasCredito = _group(map['notas_credito']);

    final otros = <FventasOtro>[];
    final rawOtros = map['otros'];
    if (rawOtros is List) {
      for (final o in rawOtros) {
        if (o is Map) {
          otros.add(FventasOtro.fromJson(Map<String, dynamic>.from(o)));
        }
      }
    }

    // total 이 없으면 규칙대로 직접 만든다 (NC 는 금액만 빼고 건수는 더한다).
    final rawTotal = map['total'];
    final total = rawTotal is Map
        ? FventasAmount.fromJson(Map<String, dynamic>.from(rawTotal))
        : _computeTotal(facturas, notasDebito, notasCredito, otros);

    return FventasSummary(
      ivaRate: _toDouble(map['iva_rate'], fallback: defaultIvaRate),
      montoIncluyeIva: map['monto_incluye_iva'] != false,
      facturas: facturas,
      notasDebito: notasDebito,
      notasCredito: notasCredito,
      otros: otros,
      total: total,
      fromServer: true,
    );
  }

  static FventasGroup _group(dynamic value) => value is Map
      ? FventasGroup.fromJson(Map<String, dynamic>.from(value))
      : FventasGroup.empty;

  static FventasAmount _computeTotal(
    FventasGroup facturas,
    FventasGroup debitos,
    FventasGroup creditos,
    List<FventasOtro> otros,
  ) {
    final otrosSum =
        otros.fold(FventasAmount.zero, (sum, o) => sum + o.amount);
    final positives = facturas.subtotal + debitos.subtotal + otrosSum;
    final c = creditos.subtotal;
    return FventasAmount(
      // 건수는 Nota de Crédito 도 발행된 comprobante 이므로 더한다.
      count: positives.count + c.count,
      monto: positives.monto - c.monto,
      neto: positives.neto - c.neto,
      iva: positives.iva - c.iva,
    );
  }

  /// 서버가 `summary` 를 주지 않을 때 쓰는 대체 계산.
  ///
  /// 옛 서버로도 푸터가 비지 않게 하려고 남겨둔 경로다. 받아둔 행만 더하므로
  /// 아직 다 못 받은 페이지가 있으면 기간 전체 합계가 아니다 —
  /// 그래서 [fromServer] 가 false 이고, 화면에 그 사실을 표시한다.
  factory FventasSummary.fromRows(
    List<dynamic> rows, {
    double ivaRate = defaultIvaRate,
  }) {
    final facturas = <String, FventasAmount>{};
    final debitos = <String, FventasAmount>{};
    final creditos = <String, FventasAmount>{};
    final otrosByCode = <String, FventasAmount>{};

    for (final row in rows) {
      if (row is! Map) continue;
      final tipo = row['tipofactura']?.toString().trim().toUpperCase() ?? '';
      if (tipo.isEmpty) continue;

      final monto = _toDouble(row['monto']);
      final neto = montoToNeto(monto, ivaRate);
      final amount = FventasAmount(
        count: 1,
        monto: monto,
        neto: neto,
        iva: monto - neto,
      );

      final kind = classify(tipo);
      if (kind == null) {
        otrosByCode[tipo] = (otrosByCode[tipo] ?? FventasAmount.zero) + amount;
        continue;
      }

      final target = switch (kind.$1) {
        FventasKind.factura => facturas,
        FventasKind.debito => debitos,
        FventasKind.credito => creditos,
      };
      target[kind.$2] = (target[kind.$2] ?? FventasAmount.zero) + amount;
    }

    FventasGroup toGroup(Map<String, FventasAmount> byLetra) => FventasGroup(
          byLetra: byLetra,
          subtotal:
              byLetra.values.fold(FventasAmount.zero, (sum, a) => sum + a),
        );

    final f = toGroup(facturas);
    final d = toGroup(debitos);
    final c = toGroup(creditos);
    final otros = otrosByCode.entries
        .map((e) => FventasOtro(e.key, e.value))
        .toList()
      ..sort((a, b) => a.label.compareTo(b.label));

    return FventasSummary(
      ivaRate: ivaRate,
      montoIncluyeIva: true,
      facturas: f,
      notasDebito: d,
      notasCredito: c,
      otros: otros,
      total: _computeTotal(f, d, c, otros),
      fromServer: false,
    );
  }

  /// IVA 포함 금액에서 순액을 뽑는다.
  static double montoToNeto(double monto, double ivaRate) =>
      ivaRate <= 0 ? monto : monto / (1 + ivaRate);

  /// AFIP comprobante 코드 → (종류, letra).
  ///
  /// DB 의 tipofactura 는 `"01"`, `"06"` 같은 AFIP 숫자 코드다.
  /// 예전 데이터에 남아 있을 수 있는 문자 코드('A', 'NCA' …)도 함께 받는다.
  /// 모르는 코드는 null 을 돌려주고 호출부가 '기타'로 모은다 — 임의로
  /// Factura 로 넘겨버리면 합계가 조용히 틀어지기 때문이다.
  static (FventasKind, String)? classify(String tipo) {
    const afip = <String, (FventasKind, String)>{
      '01': (FventasKind.factura, 'A'),
      '02': (FventasKind.debito, 'A'),
      '03': (FventasKind.credito, 'A'),
      '06': (FventasKind.factura, 'B'),
      '07': (FventasKind.debito, 'B'),
      '08': (FventasKind.credito, 'B'),
      '11': (FventasKind.factura, 'C'),
      '12': (FventasKind.debito, 'C'),
      '13': (FventasKind.credito, 'C'),
      '51': (FventasKind.factura, 'M'),
      '52': (FventasKind.debito, 'M'),
      '53': (FventasKind.credito, 'M'),
    };

    final padded = tipo.length == 1 && int.tryParse(tipo) != null
        ? '0$tipo'
        : tipo;
    final hit = afip[padded];
    if (hit != null) return hit;

    // 레거시 문자 코드
    if (tipo.startsWith('NC') && tipo.length == 3) {
      return (FventasKind.credito, tipo.substring(2));
    }
    if (tipo.startsWith('ND') && tipo.length == 3) {
      return (FventasKind.debito, tipo.substring(2));
    }
    if (tipo == 'C') return (FventasKind.credito, 'C'); // resumen_del_dia 의 레거시 'C'
    if (const ['A', 'B', 'M'].contains(tipo)) return (FventasKind.factura, tipo);

    return null;
  }

  bool get isEmpty => total.count == 0;

  String debugDescription() => 'fromServer=$fromServer, ivaRate=$ivaRate, '
      'facturas($facturas), debitos($notasDebito), creditos($notasCredito), '
      'otros=${otros.length}, total($total)';
}

enum FventasKind { factura, debito, credito }

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _toDouble(dynamic value, {double fallback = 0}) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}
