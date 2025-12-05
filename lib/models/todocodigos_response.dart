/// Todocodigos 페이지네이션 정보 모델
class TodocodigosPagination {
  final int count;
  final int total;
  final bool hasMore;
  final String? idTodocodigo; // 다음 요청을 위한 커서 값

  TodocodigosPagination({
    required this.count,
    required this.total,
    required this.hasMore,
    this.idTodocodigo,
  });

  factory TodocodigosPagination.fromMap(Map<String, dynamic> map) {
    return TodocodigosPagination(
      count: map['count'] as int? ?? 0,
      total: map['total'] as int? ?? 0,
      hasMore: map['hasMore'] as bool? ?? false,
      idTodocodigo: map['id_todocodigo']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'count': count,
      'total': total,
      'hasMore': hasMore,
      if (idTodocodigo != null) 'id_todocodigo': idTodocodigo,
    };
  }
}

/// Todocodigo 아이템 모델
class TodocodigoItem {
  final String? idTodocodigo;
  final String? tcodigo;
  final String? tdesc;
  final double? tpre1;
  final double? tpre2;
  final double? tpre3;
  final double? torgpre;
  final String? ttelacodigo;
  final double? ttelakg;
  final String? tinfo1;
  final String? tinfo2;
  final String? tinfo3;
  final String? utime;
  final bool? borrado;
  final String? fotonombre;
  final double? tpre4;
  final double? tpre5;
  final String? pubip;
  final String? ip;
  final String? mac;
  final bool? bmobile;
  final String? refIdTemporada;
  final String? refIdTipo;
  final String? refIdOrigen;
  final String? refIdEmpresa;
  final String? memo;
  final String? estatusPrecios;
  final double? tprecioDolar;
  final String? utimeModificado;
  final String? idTodocodigoCentralizado;
  final bool? bMostrarVcontrol;
  final String? dOfertaMode;
  final String? idSerial;
  final String? strPrefijo;

  TodocodigoItem({
    this.idTodocodigo,
    this.tcodigo,
    this.tdesc,
    this.tpre1,
    this.tpre2,
    this.tpre3,
    this.torgpre,
    this.ttelacodigo,
    this.ttelakg,
    this.tinfo1,
    this.tinfo2,
    this.tinfo3,
    this.utime,
    this.borrado,
    this.fotonombre,
    this.tpre4,
    this.tpre5,
    this.pubip,
    this.ip,
    this.mac,
    this.bmobile,
    this.refIdTemporada,
    this.refIdTipo,
    this.refIdOrigen,
    this.refIdEmpresa,
    this.memo,
    this.estatusPrecios,
    this.tprecioDolar,
    this.utimeModificado,
    this.idTodocodigoCentralizado,
    this.bMostrarVcontrol,
    this.dOfertaMode,
    this.idSerial,
    this.strPrefijo,
  });

  factory TodocodigoItem.fromMap(Map<String, dynamic> map) {
    return TodocodigoItem(
      idTodocodigo: map['id_todocodigo']?.toString(),
      tcodigo: map['tcodigo']?.toString(),
      tdesc: map['tdesc']?.toString(),
      tpre1: _parseDouble(map['tpre1']),
      tpre2: _parseDouble(map['tpre2']),
      tpre3: _parseDouble(map['tpre3']),
      torgpre: _parseDouble(map['torgpre']),
      ttelacodigo: map['ttelacodigo']?.toString(),
      ttelakg: _parseDouble(map['ttelakg']),
      tinfo1: map['tinfo1']?.toString(),
      tinfo2: map['tinfo2']?.toString(),
      tinfo3: map['tinfo3']?.toString(),
      utime: map['utime']?.toString(),
      borrado: map['borrado'] as bool? ?? (map['borrado']?.toString() == '1' || map['borrado']?.toString() == 'true'),
      fotonombre: map['fotonombre']?.toString(),
      tpre4: _parseDouble(map['tpre4']),
      tpre5: _parseDouble(map['tpre5']),
      pubip: map['pubip']?.toString(),
      ip: map['ip']?.toString(),
      mac: map['mac']?.toString(),
      bmobile: map['bmobile'] as bool? ?? (map['bmobile']?.toString() == '1' || map['bmobile']?.toString() == 'true'),
      refIdTemporada: map['ref_id_temporada']?.toString(),
      refIdTipo: map['ref_id_tipo']?.toString(),
      refIdOrigen: map['ref_id_origen']?.toString(),
      refIdEmpresa: map['ref_id_empresa']?.toString(),
      memo: map['memo']?.toString(),
      estatusPrecios: map['estatus_precios']?.toString(),
      tprecioDolar: _parseDouble(map['tprecio_dolar']),
      utimeModificado: map['utime_modificado']?.toString(),
      idTodocodigoCentralizado: map['id_todocodigo_centralizado']?.toString(),
      bMostrarVcontrol: map['b_mostrar_vcontrol'] as bool? ?? (map['b_mostrar_vcontrol']?.toString() == '1' || map['b_mostrar_vcontrol']?.toString() == 'true'),
      dOfertaMode: map['d_oferta_mode']?.toString(),
      idSerial: map['id_serial']?.toString(),
      strPrefijo: map['str_prefijo']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    
    if (idTodocodigo != null) map['id_todocodigo'] = idTodocodigo;
    if (tcodigo != null) map['tcodigo'] = tcodigo;
    if (tdesc != null) map['tdesc'] = tdesc;
    if (tpre1 != null) map['tpre1'] = tpre1;
    if (tpre2 != null) map['tpre2'] = tpre2;
    if (tpre3 != null) map['tpre3'] = tpre3;
    if (torgpre != null) map['torgpre'] = torgpre;
    if (ttelacodigo != null) map['ttelacodigo'] = ttelacodigo;
    if (ttelakg != null) map['ttelakg'] = ttelakg;
    if (tinfo1 != null) map['tinfo1'] = tinfo1;
    if (tinfo2 != null) map['tinfo2'] = tinfo2;
    if (tinfo3 != null) map['tinfo3'] = tinfo3;
    if (utime != null) map['utime'] = utime;
    if (borrado != null) map['borrado'] = borrado;
    if (fotonombre != null) map['fotonombre'] = fotonombre;
    if (tpre4 != null) map['tpre4'] = tpre4;
    if (tpre5 != null) map['tpre5'] = tpre5;
    if (pubip != null) map['pubip'] = pubip;
    if (ip != null) map['ip'] = ip;
    if (mac != null) map['mac'] = mac;
    if (bmobile != null) map['bmobile'] = bmobile;
    if (refIdTemporada != null) map['ref_id_temporada'] = refIdTemporada;
    if (refIdTipo != null) map['ref_id_tipo'] = refIdTipo;
    if (refIdOrigen != null) map['ref_id_origen'] = refIdOrigen;
    if (refIdEmpresa != null) map['ref_id_empresa'] = refIdEmpresa;
    if (memo != null) map['memo'] = memo;
    if (estatusPrecios != null) map['estatus_precios'] = estatusPrecios;
    if (tprecioDolar != null) map['tprecio_dolar'] = tprecioDolar;
    if (utimeModificado != null) map['utime_modificado'] = utimeModificado;
    if (idTodocodigoCentralizado != null) map['id_todocodigo_centralizado'] = idTodocodigoCentralizado;
    if (bMostrarVcontrol != null) map['b_mostrar_vcontrol'] = bMostrarVcontrol;
    if (dOfertaMode != null) map['d_oferta_mode'] = dOfertaMode;
    if (idSerial != null) map['id_serial'] = idSerial;
    if (strPrefijo != null) map['str_prefijo'] = strPrefijo;
    
    return map;
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

/// Todocodigos 응답 모델
class TodocodigosResponse {
  final Map<String, dynamic>? filters;
  final String? filteringWord;
  final String? sortColumn;
  final bool? sortAscending;
  final List<TodocodigoItem> data;
  final TodocodigosPagination pagination;

  TodocodigosResponse({
    this.filters,
    this.filteringWord,
    this.sortColumn,
    this.sortAscending,
    required this.data,
    required this.pagination,
  });

  factory TodocodigosResponse.fromMap(Map<String, dynamic> map) {
    // data 배열 파싱
    final dataList = map['data'] as List<dynamic>? ?? [];
    final todocodigoItems = dataList
        .map((item) => TodocodigoItem.fromMap(item as Map<String, dynamic>))
        .toList();

    // pagination 파싱
    final paginationMap = map['pagination'] as Map<String, dynamic>? ?? {};
    final pagination = TodocodigosPagination.fromMap(paginationMap);

    return TodocodigosResponse(
      filters: map['filters'] as Map<String, dynamic>?,
      filteringWord: map['filtering_word']?.toString(),
      sortColumn: map['sort_column']?.toString(),
      sortAscending: map['sort_ascending'] as bool?,
      data: todocodigoItems,
      pagination: pagination,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (filters != null) 'filters': filters,
      if (filteringWord != null) 'filtering_word': filteringWord,
      if (sortColumn != null) 'sort_column': sortColumn,
      if (sortAscending != null) 'sort_ascending': sortAscending,
      'data': data.map((item) => item.toMap()).toList(),
      'pagination': pagination.toMap(),
    };
  }
}

