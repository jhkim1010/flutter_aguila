/// Ventas (판매) 아이템 모델
class VentasItem {
  final int? id;
  final String? hora;
  final double? tpago;
  final int? cntropas;
  final String? clientenombre;
  final double? tefectivo;
  final double? tcredito;
  final double? tbanco;
  final double? treservado;
  final double? tfavor;
  final String? vendedor;
  final int? tipo;
  final String? dni;
  final int? resiva;
  final dynamic casoesp;
  final dynamic nencargado;
  final int? cretmp;
  final String? fecha;
  final int? sucursal;
  final dynamic ntiqrepetir;
  final int? vcodeId;
  final bool? bMercadopago;
  final int? dNumCaja;
  final int? dNumTerminal;

  VentasItem({
    this.id,
    this.hora,
    this.tpago,
    this.cntropas,
    this.clientenombre,
    this.tefectivo,
    this.tcredito,
    this.tbanco,
    this.treservado,
    this.tfavor,
    this.vendedor,
    this.tipo,
    this.dni,
    this.resiva,
    this.casoesp,
    this.nencargado,
    this.cretmp,
    this.fecha,
    this.sucursal,
    this.ntiqrepetir,
    this.vcodeId,
    this.bMercadopago,
    this.dNumCaja,
    this.dNumTerminal,
  });

  factory VentasItem.fromMap(Map<String, dynamic> map) {
    return VentasItem(
      id: map['id'] as int?,
      hora: map['hora']?.toString(),
      tpago: _parseDouble(map['tpago']),
      cntropas: map['cntropas'] as int?,
      clientenombre: map['clientenombre']?.toString(),
      tefectivo: _parseDouble(map['tefectivo']),
      tcredito: _parseDouble(map['tcredito']),
      tbanco: _parseDouble(map['tbanco']),
      treservado: _parseDouble(map['treservado']),
      tfavor: _parseDouble(map['tfavor']),
      vendedor: map['vendedor']?.toString(),
      tipo: map['tipo'] as int?,
      dni: map['dni']?.toString(),
      resiva: map['resiva'] as int?,
      casoesp: map['casoesp'],
      nencargado: map['nencargado'],
      cretmp: map['cretmp'] as int?,
      fecha: map['fecha']?.toString(),
      sucursal: map['sucursal'] as int?,
      ntiqrepetir: map['ntiqrepetir'],
      vcodeId: map['vcode_id'] as int?,
      bMercadopago: map['b_mercadopago'] as bool?,
      dNumCaja: map['d_num_caja'] as int?,
      dNumTerminal: map['d_num_terminal'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (hora != null) 'hora': hora,
      if (tpago != null) 'tpago': tpago,
      if (cntropas != null) 'cntropas': cntropas,
      if (clientenombre != null) 'clientenombre': clientenombre,
      if (tefectivo != null) 'tefectivo': tefectivo,
      if (tcredito != null) 'tcredito': tcredito,
      if (tbanco != null) 'tbanco': tbanco,
      if (treservado != null) 'treservado': treservado,
      if (tfavor != null) 'tfavor': tfavor,
      if (vendedor != null) 'vendedor': vendedor,
      if (tipo != null) 'tipo': tipo,
      if (dni != null) 'dni': dni,
      if (resiva != null) 'resiva': resiva,
      if (casoesp != null) 'casoesp': casoesp,
      if (nencargado != null) 'nencargado': nencargado,
      if (cretmp != null) 'cretmp': cretmp,
      if (fecha != null) 'fecha': fecha,
      if (sucursal != null) 'sucursal': sucursal,
      if (ntiqrepetir != null) 'ntiqrepetir': ntiqrepetir,
      if (vcodeId != null) 'vcode_id': vcodeId,
      if (bMercadopago != null) 'b_mercadopago': bMercadopago,
      if (dNumCaja != null) 'd_num_caja': dNumCaja,
      if (dNumTerminal != null) 'd_num_terminal': dNumTerminal,
    };
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }
}

/// Ventas 응답 모델
class VentasResponse {
  final bool success;
  final String? fecha;
  final double? total;
  final int count;
  final bool hasMore;
  final int? nextVcodeId;
  final List<VentasItem> data;

  VentasResponse({
    required this.success,
    this.fecha,
    this.total,
    required this.count,
    required this.hasMore,
    this.nextVcodeId,
    required this.data,
  });

  factory VentasResponse.fromMap(Map<String, dynamic> map) {
    // data 배열 파싱
    final dataList = map['data'] as List<dynamic>? ?? [];
    final ventasItems = dataList
        .map((item) => VentasItem.fromMap(item as Map<String, dynamic>))
        .toList();

    return VentasResponse(
      success: map['success'] as bool? ?? false,
      fecha: map['fecha']?.toString(),
      total: _parseDouble(map['total']),
      count: map['count'] as int? ?? 0,
      hasMore: map['hasMore'] as bool? ?? false,
      nextVcodeId: map['next_vcode_id'] as int?,
      data: ventasItems,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'success': success,
      if (fecha != null) 'fecha': fecha,
      if (total != null) 'total': total,
      'count': count,
      'hasMore': hasMore,
      if (nextVcodeId != null) 'next_vcode_id': nextVcodeId,
      'data': data.map((item) => item.toMap()).toList(),
    };
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }
}
