/// Stocks 페이지네이션 정보 모델
class StocksPagination {
  final int count;
  final int total;
  final bool hasMore;
  final String? nextMaxUtime;

  StocksPagination({
    required this.count,
    required this.total,
    required this.hasMore,
    this.nextMaxUtime,
  });

  factory StocksPagination.fromMap(Map<String, dynamic> map) {
    return StocksPagination(
      count: map['count'] as int? ?? 0,
      total: map['total'] as int? ?? 0,
      hasMore: map['hasMore'] as bool? ?? false,
      nextMaxUtime: map['nextMaxUtime']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'count': count,
      'total': total,
      'hasMore': hasMore,
      if (nextMaxUtime != null) 'nextMaxUtime': nextMaxUtime,
    };
  }
}

/// Stock 아이템 모델 (bcolorview에 따라 다른 필드 지원)
class StockItem {
  // 공통 필드
  final String? firstDate;
  final String? lastDate;
  final double? pre1;
  final double? pre2;
  final double? pre3;
  final double? pre4;
  final double? pre5;
  final double? porcentaje;
  final String? sucursal;

  // bcolorview = false (일반 모드) 필드
  final String? codigo;
  final String? descripcion;
  final double? totaling;
  final double? totalventa;
  final double? todayingreso;
  final double? todayventa;
  final double? totalreservado;
  final double? cntoffset;
  final double? stockreal;
  final String? idCodigo1;

  // bcolorview = true (통합 모드) 필드
  final String? tcode;
  final String? tdesc;
  final double? totaling3;
  final double? totalventa3;
  final double? todaying3;
  final double? todayvnt3;
  final double? totalreservado3;
  final double? cntoffset3;
  final double? stockreal3;
  final String? refIdTodocodigo;

  StockItem({
    this.firstDate,
    this.lastDate,
    this.pre1,
    this.pre2,
    this.pre3,
    this.pre4,
    this.pre5,
    this.porcentaje,
    this.sucursal,
    // 일반 모드 필드
    this.codigo,
    this.descripcion,
    this.totaling,
    this.totalventa,
    this.todayingreso,
    this.todayventa,
    this.totalreservado,
    this.cntoffset,
    this.stockreal,
    this.idCodigo1,
    // 통합 모드 필드
    this.tcode,
    this.tdesc,
    this.totaling3,
    this.totalventa3,
    this.todaying3,
    this.todayvnt3,
    this.totalreservado3,
    this.cntoffset3,
    this.stockreal3,
    this.refIdTodocodigo,
  });

  factory StockItem.fromMap(Map<String, dynamic> map) {
    return StockItem(
      // 공통 필드
      firstDate: map['first_date']?.toString(),
      lastDate: map['last_date']?.toString(),
      pre1: _parseDouble(map['pre1']),
      pre2: _parseDouble(map['pre2']),
      pre3: _parseDouble(map['pre3']),
      pre4: _parseDouble(map['pre4']),
      pre5: _parseDouble(map['pre5']),
      porcentaje: _parseDouble(map['porcentaje']),
      sucursal: map['sucursal']?.toString(),
      // 일반 모드 필드
      codigo: map['codigo']?.toString(),
      descripcion: map['descripcion']?.toString(),
      totaling: _parseDouble(map['totaling']),
      totalventa: _parseDouble(map['totalventa']),
      todayingreso: _parseDouble(map['todayingreso']),
      todayventa: _parseDouble(map['todayventa']),
      totalreservado: _parseDouble(map['totalreservado']),
      cntoffset: _parseDouble(map['cntoffset']),
      stockreal: _parseDouble(map['stockreal']),
      idCodigo1: map['id_codigo1']?.toString(),
      // 통합 모드 필드
      tcode: map['tcode']?.toString(),
      tdesc: map['tdesc']?.toString(),
      totaling3: _parseDouble(map['totaling3']),
      totalventa3: _parseDouble(map['totalventa3']),
      todaying3: _parseDouble(map['todaying3']),
      todayvnt3: _parseDouble(map['todayvnt3']),
      totalreservado3: _parseDouble(map['totalreservado3']),
      cntoffset3: _parseDouble(map['cntoffset3']),
      stockreal3: _parseDouble(map['stockreal3']),
      refIdTodocodigo: map['ref_id_todocodigo']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    
    // 공통 필드
    if (firstDate != null) map['first_date'] = firstDate;
    if (lastDate != null) map['last_date'] = lastDate;
    if (pre1 != null) map['pre1'] = pre1;
    if (pre2 != null) map['pre2'] = pre2;
    if (pre3 != null) map['pre3'] = pre3;
    if (pre4 != null) map['pre4'] = pre4;
    if (pre5 != null) map['pre5'] = pre5;
    if (porcentaje != null) map['porcentaje'] = porcentaje;
    if (sucursal != null) map['sucursal'] = sucursal;
    
    // 일반 모드 필드
    if (codigo != null) map['codigo'] = codigo;
    if (descripcion != null) map['descripcion'] = descripcion;
    if (totaling != null) map['totaling'] = totaling;
    if (totalventa != null) map['totalventa'] = totalventa;
    if (todayingreso != null) map['todayingreso'] = todayingreso;
    if (todayventa != null) map['todayventa'] = todayventa;
    if (totalreservado != null) map['totalreservado'] = totalreservado;
    if (cntoffset != null) map['cntoffset'] = cntoffset;
    if (stockreal != null) map['stockreal'] = stockreal;
    if (idCodigo1 != null) map['id_codigo1'] = idCodigo1;
    
    // 통합 모드 필드
    if (tcode != null) map['tcode'] = tcode;
    if (tdesc != null) map['tdesc'] = tdesc;
    if (totaling3 != null) map['totaling3'] = totaling3;
    if (totalventa3 != null) map['totalventa3'] = totalventa3;
    if (todaying3 != null) map['todaying3'] = todaying3;
    if (todayvnt3 != null) map['todayvnt3'] = todayvnt3;
    if (totalreservado3 != null) map['totalreservado3'] = totalreservado3;
    if (cntoffset3 != null) map['cntoffset3'] = cntoffset3;
    if (stockreal3 != null) map['stockreal3'] = stockreal3;
    if (refIdTodocodigo != null) map['ref_id_todocodigo'] = refIdTodocodigo;
    
    return map;
  }

  /// bcolorview 모드 확인 (tcode 또는 codigo 존재 여부로 판단)
  bool get isBcolorView => tcode != null || tdesc != null;

  /// 코드 가져오기 (일반 모드 또는 통합 모드)
  String? get code => isBcolorView ? tcode : codigo;

  /// 설명 가져오기 (일반 모드 또는 통합 모드)
  String? get description => isBcolorView ? tdesc : descripcion;

  /// Stock Real 가져오기 (일반 모드 또는 통합 모드)
  double? get stockReal => isBcolorView ? stockreal3 : stockreal;

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

/// Stocks 응답 모델
class StocksResponse {
  final Map<String, dynamic>? filters;
  final String? sucursal;
  final bool bcolorview;
  final String? valor1;
  final String? filteringWord;
  final String? sortColumn;
  final bool? sortAscending;
  final Map<String, dynamic>? summary;
  final int totalItems;
  final String? sourceTable;
  final List<StockItem> data;
  final StocksPagination pagination;

  StocksResponse({
    this.filters,
    this.sucursal,
    required this.bcolorview,
    this.valor1,
    this.filteringWord,
    this.sortColumn,
    this.sortAscending,
    this.summary,
    required this.totalItems,
    this.sourceTable,
    required this.data,
    required this.pagination,
  });

  factory StocksResponse.fromMap(Map<String, dynamic> map) {
    // data 배열 파싱
    final dataList = map['data'] as List<dynamic>? ?? [];
    final stockItems = dataList
        .map((item) => StockItem.fromMap(item as Map<String, dynamic>))
        .toList();

    // pagination 파싱
    final paginationMap = map['pagination'] as Map<String, dynamic>? ?? {};
    final pagination = StocksPagination.fromMap(paginationMap);

    return StocksResponse(
      filters: map['filters'] as Map<String, dynamic>?,
      sucursal: map['sucursal']?.toString(),
      bcolorview: map['bcolorview'] as bool? ?? false,
      valor1: map['valor1']?.toString(),
      filteringWord: map['filtering_word']?.toString(),
      sortColumn: map['sort_column']?.toString(),
      sortAscending: map['sort_ascending'] as bool?,
      summary: map['summary'] as Map<String, dynamic>?,
      totalItems: map['total_items'] as int? ?? 0,
      sourceTable: map['source_table']?.toString(),
      data: stockItems,
      pagination: pagination,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (filters != null) 'filters': filters,
      if (sucursal != null) 'sucursal': sucursal,
      'bcolorview': bcolorview,
      if (valor1 != null) 'valor1': valor1,
      if (filteringWord != null) 'filtering_word': filteringWord,
      if (sortColumn != null) 'sort_column': sortColumn,
      if (sortAscending != null) 'sort_ascending': sortAscending,
      if (summary != null) 'summary': summary,
      'total_items': totalItems,
      if (sourceTable != null) 'source_table': sourceTable,
      'data': data.map((item) => item.toMap()).toList(),
      'pagination': pagination.toMap(),
    };
  }
}

