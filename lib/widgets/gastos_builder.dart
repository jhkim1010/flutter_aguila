import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'report_utils.dart';
import 'resizable_data_table.dart';
import '../utils/platform_utils.dart';

/// Gastos 보고서 UI 빌더
class GastosBuilder {
  /// 상세 내역 테이블 칼럼 정의 (ResizableDataTable용)
  static List<TableColumnDef> buildColumnDefs() => [
    const TableColumnDef(key: 'fecha',    label: 'Fecha',    defaultWidth: 120, sortable: true),
    const TableColumnDef(key: 'hora',     label: 'Hora',     defaultWidth: 100, sortable: true),
    const TableColumnDef(key: 'tema',     label: 'Tema',     defaultWidth: 200, sortable: true),
    const TableColumnDef(key: 'rubro',    label: 'Rubro',    defaultWidth: 150, sortable: true),
    const TableColumnDef(key: 'codigo',   label: 'Código',   defaultWidth: 120, sortable: true),
    const TableColumnDef(key: 'costo',    label: 'Costo',    defaultWidth: 150, textAlign: TextAlign.right, sortable: true),
    const TableColumnDef(key: 'sucursal', label: 'Sucursal', defaultWidth: 120, sortable: true),
  ];

  /// 상세 내역 테이블 행 데이터 빌드 (ResizableDataTable용)
  static List<List<Widget>> buildRows(List<dynamic> data) {
    return data
        .whereType<Map<String, dynamic>>()
        .map((item) => _buildRowCells(item))
        .toList();
  }

  static List<Widget> _buildRowCells(Map<String, dynamic> item) {
    String val(String key) => item[key]?.toString() ?? '';

    // costo: 통화 형식
    final costoRaw = item['costo'];
    final costoNum = num.tryParse(
          costoRaw?.toString().replaceAll(',', '').replaceAll('\$', '') ?? '0') ??
        0;
    final formattedCosto = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    ).format(costoNum);

    return [
      Text(val('fecha'),    style: const TextStyle(fontSize: 12)),
      Text(val('hora'),     style: const TextStyle(fontSize: 12)),
      Text(val('tema'),     style: const TextStyle(fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
      Text(val('rubro'),    style: const TextStyle(fontSize: 12)),
      Text(val('codigo'),   style: const TextStyle(fontSize: 12)),
      Text(formattedCosto,  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red), textAlign: TextAlign.right),
      Text(val('sucursal'), style: const TextStyle(fontSize: 12)),
    ];
  }

  /// Gastos 콘텐츠 빌드
  static Widget buildContent({
    required Map<String, dynamic> data,
    required BuildContext context,
    required ScrollController scrollController,
    required Function(String?, bool) onSort,
    String? sortColumn,
    bool sortAscending = true,
    String? filteringWord,
    String? selectedRubroCode,
    Function(String?)? onRubroSelected,
    bool isLoadingDetail = false,
    ScrollController? horizontalScrollController,
    Map<String, double>? columnWidths,
    void Function(String key, double newWidth)? onColumnResize,
  }) {
    // summary 카드
    Widget? summaryCard;
    if (data.containsKey('summary') && data['summary'] is Map) {
      summaryCard = _buildSummaryCard(data['summary'] as Map<String, dynamic>);
    }

    // summary_by_rubro 테이블 (새로운 구조)
    Widget? summaryByRubroTable;
    if (data.containsKey('summary_by_rubro') && data['summary_by_rubro'] is List) {
      final summaryByRubroList = data['summary_by_rubro'] as List;
      summaryByRubroTable = _buildSummaryByRubroTable(
        summaryByRubroList,
        context,
        onSort: onSort,
        sortColumn: sortColumn,
        sortAscending: sortAscending,
        selectedRubroCode: selectedRubroCode,
        onRubroSelected: onRubroSelected,
      );
    }

    // data.summary 카드 그리드 (기존 구조 - 하위 호환성)
    Widget? summaryGrid;
    if (data.containsKey('data') && 
        data['data'] is Map &&
        (data['data'] as Map).containsKey('summary') &&
        (data['data'] as Map)['summary'] is List) {
      summaryGrid = _buildSummaryGrid((data['data'] as Map)['summary'] as List, context);
    }

    // data.detail 테이블 (기존 구조)
    Widget? detailTable;
    if (data.containsKey('data') && 
        data['data'] is Map &&
        (data['data'] as Map).containsKey('detail') &&
        (data['data'] as Map)['detail'] is List) {
      var detailList = (data['data'] as Map)['detail'] as List;
      final originalDetailCount = detailList.length;
      debugPrint('🔍 [GastosBuilder] detail 테이블 처리 시작');
      debugPrint('   → 서버에서 받은 데이터 개수: $originalDetailCount');
      debugPrint('   → selectedRubroCode: $selectedRubroCode (서버에서 이미 필터링됨)');
      debugPrint('   → filteringWord: $filteringWord');
      
      // filteringWord 필터 적용: tema 칼럼에서 대소문자 구분 없이 비교
      if (filteringWord != null && filteringWord.isNotEmpty) {
        final filterLower = filteringWord.toLowerCase();
        final beforeFilterCount = detailList.length;
        detailList = detailList.where((item) {
          if (item is Map<String, dynamic>) {
            final tema = item['tema']?.toString().toLowerCase() ?? '';
            return tema.contains(filterLower);
          }
          return false;
        }).toList();
        debugPrint('   → filteringWord 필터링 후: ${detailList.length}개 (${beforeFilterCount}개 중)');
      }
      
      if (detailList.isEmpty) {
        debugPrint('   ⚠️ 필터링 결과가 비어있음! 테이블이 표시되지 않습니다.');
        debugPrint('   → 원본: $originalDetailCount개, 필터링 후: ${detailList.length}개');
      }
      
      if (detailList.isNotEmpty) {
        detailTable = _buildDetailTable(
          detailList,
          context,
          scrollController,
          onSort,
          sortColumn,
          sortAscending,
          horizontalScrollController: horizontalScrollController,
          columnWidths: columnWidths,
          onColumnResize: onColumnResize,
        );
      }
    }

    // data 배열이 직접 있는 경우 (새로운 구조)
    Widget? dataTable;
    if (data.containsKey('data') && data['data'] is List) {
      var dataList = data['data'] as List;
      final originalDataCount = dataList.length;
      debugPrint('🔍 [GastosBuilder] data 테이블 처리 시작');
      debugPrint('   → 서버에서 받은 데이터 개수: $originalDataCount');
      debugPrint('   → selectedRubroCode: $selectedRubroCode (서버에서 이미 필터링됨)');
      debugPrint('   → filteringWord: $filteringWord');
      
      // filteringWord 필터 적용: tema 칼럼에서 대소문자 구분 없이 비교
      if (filteringWord != null && filteringWord.isNotEmpty) {
        final filterLower = filteringWord.toLowerCase();
        final beforeFilterCount = dataList.length;
        dataList = dataList.where((item) {
          if (item is Map<String, dynamic>) {
            final tema = item['tema']?.toString().toLowerCase() ?? '';
            return tema.contains(filterLower);
          }
          return false;
        }).toList();
        debugPrint('   → filteringWord 필터링 후: ${dataList.length}개 (${beforeFilterCount}개 중)');
      }
      
      if (dataList.isEmpty) {
        debugPrint('   ⚠️ 필터링 결과가 비어있음! 테이블이 표시되지 않습니다.');
        debugPrint('   → 원본: $originalDataCount개, 필터링 후: ${dataList.length}개');
      }
      
      if (dataList.isNotEmpty) {
        dataTable = _buildDetailTable(
          dataList,
          context,
          scrollController,
          onSort,
          sortColumn,
          sortAscending,
          horizontalScrollController: horizontalScrollController,
          columnWidths: columnWidths,
          onColumnResize: onColumnResize,
        );
      }
    }

    // detailTable 또는 dataTable이 있으면 별도 레이아웃 사용
    final tableWidget = detailTable ?? dataTable;
    debugPrint('🔍 [GastosBuilder] 테이블 위젯 상태 확인');
    debugPrint('   → detailTable: ${detailTable != null ? "존재" : "null"}');
    debugPrint('   → dataTable: ${dataTable != null ? "존재" : "null"}');
    debugPrint('   → tableWidget: ${tableWidget != null ? "존재" : "null"}');
    
    if (tableWidget != null) {
      // macOS, Windows, iPad 넓은 화면인지 확인
      final isLargeScreen = PlatformUtils.isDesktop() || 
                            PlatformUtils.isIPad(context) ||
                            (MediaQuery.of(context).size.width >= 1200);
      
      // 넓은 화면이고 summary_by_rubro와 detail table이 모두 있는 경우 좌우 분할 레이아웃
      // 이 경우 summaryByRubroTable을 다시 생성하여 showTitle: false로 설정
      Widget? splitSummaryByRubroTable;
      if (isLargeScreen && data.containsKey('summary_by_rubro') && data['summary_by_rubro'] is List) {
        final summaryByRubroList = data['summary_by_rubro'] as List;
        splitSummaryByRubroTable = _buildSummaryByRubroTable(
          summaryByRubroList,
          context,
          onSort: onSort,
          sortColumn: sortColumn,
          sortAscending: sortAscending,
          showTitle: false, // 좌우 분할 레이아웃에서는 제목 없이 테이블만 표시
          selectedRubroCode: selectedRubroCode,
          onRubroSelected: onRubroSelected,
        );
      }
      
      if (isLargeScreen && splitSummaryByRubroTable != null) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더 부분 (summaryCard, summaryGrid 등)
              if (summaryCard != null) ...[
                summaryCard,
                const SizedBox(height: 24),
              ],
              if (summaryGrid != null) ...[
                summaryGrid,
                const SizedBox(height: 24),
              ],
            // 좌우 분할 레이아웃 (크기 조정 가능)
            Expanded(
              child: _ResizableSplitView(
                leftChild: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Resumen por Rubro',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    splitSummaryByRubroTable,
                  ],
                ),
                rightChild: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Detalle de Gastos',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: isLoadingDetail
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    color: Colors.red,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Cargando detalles...',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : tableWidget,
                    ),
                  ],
                ),
              ),
            ),
            ],
          ),
        );
      }
      
      // 작은 화면이거나 하나만 있는 경우 기존 세로 레이아웃
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더 부분은 controller 없이 사용
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (summaryCard != null) ...[
                  summaryCard,
                  const SizedBox(height: 24),
                ],
                if (summaryByRubroTable != null) ...[
                  summaryByRubroTable,
                  const SizedBox(height: 24),
                ],
                if (summaryGrid != null) ...[
                  summaryGrid,
                  const SizedBox(height: 24),
                ],
                const Text(
                  'Detalle de Gastos',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
            Expanded(child: tableWidget),
          ],
        ),
      );
    }
    
    // 테이블이 없으면 기존 방식 유지
    return SingleChildScrollView(
      controller: scrollController,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (summaryCard != null) ...[
              summaryCard,
              const SizedBox(height: 24),
            ],
            if (summaryByRubroTable != null) ...[
              summaryByRubroTable,
              const SizedBox(height: 24),
            ],
            if (summaryGrid != null) ...[
              summaryGrid,
              const SizedBox(height: 24),
            ],
            if (summaryCard == null && summaryByRubroTable == null && summaryGrid == null)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text(
                    'No hay datos disponibles',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 전체 요약 카드 빌드
  static Widget _buildSummaryCard(Map<String, dynamic> summary) {
    final totalRubros = summary['total_rubros']?.toString() ?? '0';
    final totalItems = summary['total_items']?.toString() ?? '0';
    final totalCosto = summary['total_costo']?.toString() ?? '0.00';
    
    final costoNum = num.tryParse(totalCosto.replaceAll(',', '')) ?? 0;
    final formattedCosto = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    ).format(costoNum);

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0), // 세로 padding을 절반으로 줄임
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSummaryItem(
              'Total Rubros',
              totalRubros,
              Icons.category,
              Colors.blue,
            ),
            _buildSummaryItem(
              'Total Items',
              totalItems,
              Icons.list,
              Colors.green,
            ),
            _buildSummaryItem(
              'Total Costo',
              formattedCosto,
              Icons.attach_money,
              Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  /// 요약 아이템 빌드 (1줄로 표시)
  static Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 22, // 큰 글자로 표시
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Rubro별 요약 테이블 빌드 (새로운 구조: summary_by_rubro)
  static Widget _buildSummaryByRubroTable(
    List summaryByRubroList,
    BuildContext context, {
    Function(String?, bool)? onSort,
    String? sortColumn,
    bool sortAscending = true,
    bool showTitle = true,
    String? selectedRubroCode,
    Function(String?)? onRubroSelected,
  }) {
    if (summaryByRubroList.isEmpty) {
      return const SizedBox.shrink();
    }

    final reportColor = Colors.red;
    
    // 정렬 적용
    List<dynamic> sortedList = List.from(summaryByRubroList);
    if (sortColumn != null && onSort != null) {
      sortedList.sort((a, b) {
        if (a is! Map<String, dynamic> || b is! Map<String, dynamic>) {
          return 0;
        }

        dynamic aValue;
        dynamic bValue;

        // 정렬 칼럼에 따라 값 가져오기
        if (sortColumn == 'codigo_rubro') {
          aValue = a['codigo_rubro']?.toString() ?? '';
          bValue = b['codigo_rubro']?.toString() ?? '';
        } else if (sortColumn == 'descripcion_rubro') {
          aValue = a['descripcion_rubro']?.toString() ?? '';
          bValue = b['descripcion_rubro']?.toString() ?? '';
        } else if (sortColumn == 'cntEvento') {
          aValue = num.tryParse(a['cntEvento']?.toString() ?? '0') ?? 0;
          bValue = num.tryParse(b['cntEvento']?.toString() ?? '0') ?? 0;
        } else if (sortColumn == 'total_Gasto') {
          aValue = num.tryParse(a['total_Gasto']?.toString().replaceAll(',', '') ?? '0') ?? 0;
          bValue = num.tryParse(b['total_Gasto']?.toString().replaceAll(',', '') ?? '0') ?? 0;
        } else {
          return 0;
        }

        if (aValue == null && bValue == null) return 0;
        if (aValue == null) return sortAscending ? -1 : 1;
        if (bValue == null) return sortAscending ? 1 : -1;

        // 숫자 비교
        if (aValue is num && bValue is num) {
          final comparison = aValue.compareTo(bValue);
          return sortAscending ? comparison : -comparison;
        }

        // 문자열 비교
        final aStr = aValue.toString().toLowerCase();
        final bStr = bValue.toString().toLowerCase();
        final comparison = aStr.compareTo(bStr);
        return sortAscending ? comparison : -comparison;
      });
    }
    
    // 컬럼 정의
    final columns = [
      DataColumn(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Código Rubro',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            if (sortColumn == 'codigo_rubro' && onSort != null)
              Icon(
                sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 16,
                color: reportColor,
              ),
          ],
        ),
        onSort: onSort != null ? (columnIndex, ascending) {
          // 같은 칼럼을 클릭하면 정렬 방향 토글, 다른 칼럼이면 새로 정렬
          if (sortColumn == 'codigo_rubro') {
            onSort('codigo_rubro', !sortAscending);
          } else {
            onSort('codigo_rubro', true);
          }
        } : null,
      ),
      DataColumn(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Descripción Rubro',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            if (sortColumn == 'descripcion_rubro' && onSort != null)
              Icon(
                sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 16,
                color: reportColor,
              ),
          ],
        ),
        onSort: onSort != null ? (columnIndex, ascending) {
          // 같은 칼럼을 클릭하면 정렬 방향 토글, 다른 칼럼이면 새로 정렬
          if (sortColumn == 'descripcion_rubro') {
            onSort('descripcion_rubro', !sortAscending);
          } else {
            onSort('descripcion_rubro', true);
          }
        } : null,
      ),
      DataColumn(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Eventos',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            if (sortColumn == 'cntEvento' && onSort != null)
              Icon(
                sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 16,
                color: reportColor,
              ),
          ],
        ),
        numeric: true,
        onSort: onSort != null ? (columnIndex, ascending) {
          // 같은 칼럼을 클릭하면 정렬 방향 토글, 다른 칼럼이면 새로 정렬
          if (sortColumn == 'cntEvento') {
            onSort('cntEvento', !sortAscending);
          } else {
            onSort('cntEvento', true);
          }
        } : null,
      ),
      DataColumn(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Total Gasto',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            if (sortColumn == 'total_Gasto' && onSort != null)
              Icon(
                sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 16,
                color: reportColor,
              ),
          ],
        ),
        numeric: true,
        onSort: onSort != null ? (columnIndex, ascending) {
          // 같은 칼럼을 클릭하면 정렬 방향 토글, 다른 칼럼이면 새로 정렬
          if (sortColumn == 'total_Gasto') {
            onSort('total_Gasto', !sortAscending);
          } else {
            onSort('total_Gasto', true);
          }
        } : null,
      ),
    ];

    // 데이터 행 생성 (정렬된 리스트 사용)
    final rows = sortedList.map<DataRow>((item) {
      if (item is! Map<String, dynamic>) {
        return DataRow(cells: columns.map((_) => const DataCell(Text(''))).toList());
      }
      
      final codigoRubro = item['codigo_rubro']?.toString() ?? '';
      final descripcionRubro = item['descripcion_rubro']?.toString() ?? '';
      final cntEvento = item['cntEvento']?.toString() ?? '0';
      final totalGasto = item['total_Gasto']?.toString() ?? '0.00';
      
      final gastoNum = num.tryParse(totalGasto.toString().replaceAll(',', '')) ?? 0;
      final formattedGasto = NumberFormat.currency(
        symbol: '\$',
        decimalDigits: 2,
      ).format(gastoNum);

      final isSelected = selectedRubroCode != null && codigoRubro == selectedRubroCode;
      
      // 디버깅: rubro 선택 시 로그 출력
      if (isSelected) {
        debugPrint('🔍 [GastosBuilder] Rubro 선택됨: codigo_rubro="$codigoRubro", descripcion="$descripcionRubro"');
      }
      
      return DataRow(
        selected: isSelected,
        color: isSelected 
            ? MaterialStateProperty.all(Colors.blue.withOpacity(0.1))
            : null,
        onSelectChanged: onRubroSelected != null ? (selected) {
          if (selected == true) {
            onRubroSelected(codigoRubro);
          } else {
            onRubroSelected(null); // 선택 해제
          }
        } : null,
        cells: [
          DataCell(
            InkWell(
              onTap: onRubroSelected != null ? () {
                if (isSelected) {
                  onRubroSelected(null); // 선택 해제
                } else {
                  onRubroSelected(codigoRubro); // 선택
                }
              } : null,
              child: Text(codigoRubro),
            ),
          ),
          DataCell(
            InkWell(
              onTap: onRubroSelected != null ? () {
                if (isSelected) {
                  onRubroSelected(null); // 선택 해제
                } else {
                  onRubroSelected(codigoRubro); // 선택
                }
              } : null,
              child: Text(descripcionRubro),
            ),
          ),
          DataCell(
            InkWell(
              onTap: onRubroSelected != null ? () {
                if (isSelected) {
                  onRubroSelected(null); // 선택 해제
                } else {
                  onRubroSelected(codigoRubro); // 선택
                }
              } : null,
              child: Text(
                cntEvento,
                textAlign: TextAlign.right,
              ),
            ),
          ),
          DataCell(
            InkWell(
              onTap: onRubroSelected != null ? () {
                if (isSelected) {
                  onRubroSelected(null); // 선택 해제
                } else {
                  onRubroSelected(codigoRubro); // 선택
                }
              } : null,
              child: Text(
                formattedGasto,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),
          ),
        ],
      );
    }).toList();

    // 총합 계산
    num totalEventos = 0;
    num totalGastos = 0;
    for (var item in summaryByRubroList) {
      if (item is Map<String, dynamic>) {
        final cntEvento = num.tryParse(item['cntEvento']?.toString() ?? '0') ?? 0;
        final totalGasto = num.tryParse(item['total_Gasto']?.toString().replaceAll(',', '') ?? '0') ?? 0;
        totalEventos += cntEvento;
        totalGastos += totalGasto;
      }
    }

    final formattedTotalGasto = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    ).format(totalGastos);

    final tableWidget = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 12,
        dataRowMinHeight: 32,  // items 보고서와 동일하게 2/3로 조정 (48 * 2/3 = 32)
        dataRowMaxHeight: 37,  // items 보고서와 동일하게 2/3로 조정 (56 * 2/3 ≈ 37)
        headingRowHeight: 37,  // items 보고서와 동일하게 조정
        headingRowColor: MaterialStateProperty.all(
          reportColor.withOpacity(0.1),
        ),
        columns: columns,
        rows: [
          ...rows,
          // 총합 행
          DataRow(
            color: MaterialStateProperty.all(reportColor.withOpacity(0.1)),
            cells: [
              const DataCell(Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
              const DataCell(Text('')),
              DataCell(
                Text(
                  totalEventos.toString(),
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataCell(
                Text(
                  formattedTotalGasto,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (showTitle) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen por Rubro',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          tableWidget,
        ],
      );
    }
    
    return tableWidget;
  }

  /// 카테고리별 요약 그리드 빌드 (기존 구조)
  static Widget _buildSummaryGrid(List summaryList, BuildContext context) {
    if (summaryList.isEmpty) {
      return const SizedBox.shrink();
    }

    // LayoutBuilder를 사용하여 실제 사용 가능한 너비 측정
    return LayoutBuilder(
      builder: (context, constraints) {
        // 큰 화면에서는 4개씩, 중간 화면에서는 3개, 작은 화면에서는 2개씩 표시
        final availableWidth = constraints.maxWidth;
        int crossAxisCount;
        double childAspectRatio;
        
        if (availableWidth >= 1200) {
          // 매우 큰 화면: 4개씩
          crossAxisCount = 4;
          childAspectRatio = 2.2 * 1.5; // 높이를 2/3로 줄임 (3.3)
        } else if (availableWidth >= 900) {
          // 큰 화면: 3개씩
          crossAxisCount = 3;
          childAspectRatio = 2.3 * 1.5; // 높이를 2/3로 줄임 (3.45)
        } else {
          // 작은 화면: 2개씩
          crossAxisCount = 2;
          childAspectRatio = 2.5 * 1.5; // 높이를 2/3로 줄임 (3.75)
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: summaryList.length,
          itemBuilder: (context, index) {
            final item = summaryList[index] as Map<String, dynamic>;
            final descGasto = item['desc_gasto']?.toString() ?? '';
            final count = item['count']?.toString() ?? '0';
            final sumCosto = item['sum_costo']?.toString() ?? '0.00';
            final codigoRubro = item['codigo_rubro']?.toString() ?? '';

            final costoNum = num.tryParse(sumCosto.replaceAll(',', '')) ?? 0;
            final formattedCosto = NumberFormat.currency(
              symbol: '\$',
              decimalDigits: 2,
            ).format(costoNum);

            return Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            codigoRubro,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            descGasto,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Items: $count',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          formattedCosto,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// 상세 내역 테이블 빌드
  static Widget _buildDetailTable(
    List detailList,
    BuildContext context,
    ScrollController scrollController,
    Function(String?, bool) onSort,
    String? sortColumn,
    bool sortAscending, {
    ScrollController? horizontalScrollController,
    Map<String, double>? columnWidths,
    void Function(String key, double newWidth)? onColumnResize,
  }) {
    if (detailList.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'No hay detalles disponibles',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    // 정렬 적용
    List<dynamic> sortedList = List.from(detailList);
    if (sortColumn != null) {
      sortedList.sort((a, b) {
        if (a is! Map<String, dynamic> || b is! Map<String, dynamic>) {
          return 0;
        }

        final aValue = a[sortColumn];
        final bValue = b[sortColumn];

        if (aValue == null && bValue == null) return 0;
        if (aValue == null) return sortAscending ? -1 : 1;
        if (bValue == null) return sortAscending ? 1 : -1;

        // 숫자 비교
        final aNum = ReportUtils.isNumeric(aValue) 
            ? num.tryParse(aValue.toString().replaceAll(',', '')) 
            : null;
        final bNum = ReportUtils.isNumeric(bValue) 
            ? num.tryParse(bValue.toString().replaceAll(',', '')) 
            : null;

        if (aNum != null && bNum != null) {
          final comparison = aNum.compareTo(bNum);
          return sortAscending ? comparison : -comparison;
        }

        // 날짜 비교
        if (sortColumn == 'fecha') {
          try {
            final aDate = DateTime.parse(aValue.toString());
            final bDate = DateTime.parse(bValue.toString());
            final comparison = aDate.compareTo(bDate);
            return sortAscending ? comparison : -comparison;
          } catch (e) {
            // 파싱 실패 시 문자열 비교
          }
        }

        // 문자열 비교
        final aStr = aValue.toString().toLowerCase();
        final bStr = bValue.toString().toLowerCase();
        final comparison = aStr.compareTo(bStr);
        return sortAscending ? comparison : -comparison;
      });
    }

    // 첫 번째 항목에서 키 가져오기
    final firstItem = sortedList.first as Map<String, dynamic>;
    final keys = firstItem.keys.toList();
    
    // 칼럼 순서 정의
    final columnOrder = [
      'fecha',
      'hora',
      'tema',
      'rubro',
      'codigo',
      'costo',
      'sucursal',
    ];
    
    // 정의된 순서대로 정렬하고, 없는 키는 뒤에 추가
    final orderedKeys = <String>[];
    for (var key in columnOrder) {
      if (keys.contains(key)) {
        orderedKeys.add(key);
      }
    }
    for (var key in keys) {
      if (!orderedKeys.contains(key)) {
        orderedKeys.add(key);
      }
    }

    final reportColor = Colors.red;

    // 칼럼 정의 (buildColumnDefs() 기준) 및 너비 병합
    final colDefs = buildColumnDefs();
    // orderedKeys에 실제 존재하는 컬럼만 colDefs에서 필터링
    final activeColDefs = colDefs.where((c) => orderedKeys.contains(c.key)).toList();
    // orderedKeys에 있지만 colDefs에 없는 추가 키도 포함
    for (final key in orderedKeys) {
      if (!activeColDefs.any((c) => c.key == key)) {
        activeColDefs.add(TableColumnDef(key: key, label: _getColumnLabel(key), defaultWidth: 150));
      }
    }

    final defaults = {for (final c in activeColDefs) c.key: c.defaultWidth};
    final mergedWidths = Map<String, double>.from(defaults)
      ..addAll(columnWidths ?? {});

    final rows = buildRows(sortedList);

    // 합계 행 빌드 (footer)
    final footerRow = _buildFixedTotalRow(
      activeColDefs.map((c) => c.key).toList(),
      sortedList,
      reportColor,
    );

    return ResizableDataTable(
      columns: activeColDefs,
      rows: rows,
      columnWidths: mergedWidths,
      onColumnResize: onColumnResize ?? (_, __) {},
      sortColumn: sortColumn,
      sortAscending: sortAscending,
      onSort: (column, ascending) => onSort(column, ascending),
      headerColor: reportColor,
      scrollController: scrollController,
      footerWidget: footerRow,
    );
  }

  /// 칼럼 라벨 가져오기
  static String _getColumnLabel(String key) {
    final labels = {
      'fecha': 'Fecha',
      'hora': 'Hora',
      'tema': 'Tema',
      'rubro': 'Rubro',
      'codigo': 'Código',
      'costo': 'Costo',
      'sucursal': 'Sucursal',
    };
    return labels[key] ?? key;
  }

  /// 고정된 합계 행 빌드 (화면 하단에 고정, 현재 보이는 항목들의 합계)
  static Widget _buildFixedTotalRow(List<String> keys, List<dynamic> displayedList, Color reportColor) {
    // 각 칼럼별 합계 계산 (현재 화면에 보이는 항목들만)
    final totals = <String, num>{};
    
    for (var key in keys) {
      // 날짜, 시간, 문자열 칼럼은 합계 계산 제외
      final isExcludedColumn = key == 'fecha' || key == 'hora' || 
                                key == 'tema' || key == 'rubro' || 
                                key == 'codigo' || key == 'sucursal';
      if (isExcludedColumn) continue;
      
      num sum = 0;
      for (var item in displayedList) {
        if (item is Map<String, dynamic> && item.containsKey(key)) {
          final value = item[key];
          if (ReportUtils.isNumeric(value)) {
            final numValue = num.tryParse(value.toString().replaceAll(',', '').replaceAll('\$', '').trim());
            if (numValue != null) {
              sum += numValue;
            }
          }
        }
      }
      totals[key] = sum;
    }
    
    // 컬럼별 고정 너비 설정 (DataTable과 일치)
    final columnWidths = <String, double>{
      'fecha': 120,
      'hora': 100,
      'tema': 200,
      'rubro': 150,
      'codigo': 120,
      'costo': 150,
      'sucursal': 120,
    };
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: reportColor.withOpacity(0.1),
        border: Border(
          top: BorderSide(
            color: reportColor.withOpacity(0.3),
            width: 2,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: keys.asMap().entries.map((entry) {
          final index = entry.key;
          final key = entry.value;
          final isExcludedColumn = key == 'fecha' || key == 'hora' || 
                                    key == 'tema' || key == 'rubro' || 
                                    key == 'codigo' || key == 'sucursal';
          final columnWidth = columnWidths[key] ?? 150.0;
          
          if (isExcludedColumn) {
            return SizedBox(
              width: columnWidth + (index < keys.length - 1 ? 12 : 0), // DataTable의 columnSpacing(12)과 일치
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // items 보고서와 동일하게 vertical: 8
                height: 37, // items 보고서와 동일하게 37
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Total',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          }
          
          final total = totals[key] ?? 0;
          // showTpago false면 합계 행 금액 칸도 **** 표시
          final String formattedTotal = ReportUtils.formatValueForTotalRow(total, key);
          
          return SizedBox(
            width: columnWidth + (index < keys.length - 1 ? 12 : 0), // DataTable의 columnSpacing(12)과 일치
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // items 보고서와 동일하게 vertical: 8
              height: 37, // items 보고서와 동일하게 37
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  formattedTotal,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// 크기 조정 가능한 분할 뷰 위젯 (Gastos용)
class _ResizableSplitView extends StatefulWidget {
  final Widget leftChild;
  final Widget rightChild;

  const _ResizableSplitView({
    required this.leftChild,
    required this.rightChild,
  });

  @override
  State<_ResizableSplitView> createState() => _ResizableSplitViewState();
}

class _ResizableSplitViewState extends State<_ResizableSplitView> {
  static const String _prefsKey = 'gastos_report_left_panel_width';
  static const double _defaultLeftWidth = 350.0;
  static const double _minLeftWidth = 200.0;
  static const double _maxLeftWidth = 800.0;
  static const double _dividerWidth = 4.0;

  double _leftWidth = _defaultLeftWidth;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _loadSavedWidth();
  }

  Future<void> _loadSavedWidth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedWidth = prefs.getDouble(_prefsKey);
      if (savedWidth != null && savedWidth >= _minLeftWidth && savedWidth <= _maxLeftWidth) {
        setState(() {
          _leftWidth = savedWidth;
        });
      }
    } catch (e) {
      debugPrint('⚠️ 왼쪽 패널 폭 로드 실패: $e');
    }
  }

  Future<void> _saveWidth(double width) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_prefsKey, width);
    } catch (e) {
      debugPrint('⚠️ 왼쪽 패널 폭 저장 실패: $e');
    }
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
    });
  }

  void _onPanUpdate(DragUpdateDetails details, double maxWidth) {
    final newWidth = _leftWidth + details.delta.dx;
    final clampedWidth = newWidth.clamp(_minLeftWidth, _maxLeftWidth);
    
    if (clampedWidth != _leftWidth) {
      setState(() {
        _leftWidth = clampedWidth;
      });
    }
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });
    _saveWidth(_leftWidth);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 왼쪽 패널
            SizedBox(
              width: _leftWidth,
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: SingleChildScrollView(
                  child: widget.leftChild,
                ),
              ),
            ),
            // 구분선 (드래그 가능)
            GestureDetector(
              onPanStart: _onPanStart,
              onPanUpdate: (details) => _onPanUpdate(details, constraints.maxWidth),
              onPanEnd: _onPanEnd,
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeColumn,
                child: Container(
                  width: _dividerWidth,
                  color: _isDragging 
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.5)
                      : Colors.grey[300],
                  child: Center(
                    child: Container(
                      width: 2,
                      height: double.infinity,
                      color: Colors.grey[400],
                    ),
                  ),
                ),
              ),
            ),
            // 오른쪽 패널
            Expanded(
              child: widget.rightChild,
            ),
          ],
        );
      },
    );
  }
}
