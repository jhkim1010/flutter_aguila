import 'package:flutter/material.dart';
import 'report_utils.dart';

/// Stocks 보고서 UI 빌더
class StocksBuilder {
  /// Stocks 콘텐츠 빌드
  static Widget buildContent({
    required Map<String, dynamic> data,
    required BuildContext context,
    required ScrollController scrollController,
    required bool isLoadingMore,
    required Color reportColor,
  }) {
    // 새로운 응답 형식 지원: data 배열이 최상위에 있음
    final dataList = data['data'] as List? ?? [];
    
    // 디버깅 로그
    print('🔍 StocksBuilder.buildContent:');
    print('   - data 키 존재: ${data.containsKey('data')}');
    print('   - dataList 길이: ${dataList.length}');
    if (dataList.isNotEmpty && dataList.first is Map) {
      print('   - 첫 번째 항목 키: ${(dataList.first as Map).keys.toList()}');
    }
    
    if (dataList.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'No data available',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }
    
    final filteredDataList = dataList;

    return Column(
      children: [
        // 백그라운드 로딩 인디케이터
        if (isLoadingMore)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: Colors.blue.withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: reportColor,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '추가 데이터 로딩 중...',
                  style: TextStyle(
                    fontSize: 12,
                    color: reportColor,
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 3, // 더 많은 컬럼을 위해 너비 증가
              child: Column(
                children: [
                  // 헤더는 외부에서 관리되므로 여기서는 제거
                  // 데이터 리스트만 표시
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      scrollDirection: Axis.vertical,
                      shrinkWrap: false,
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: filteredDataList.length,
                      itemBuilder: (context, index) {
                        final stock = filteredDataList[index] as Map<String, dynamic>;
                        
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Codigo
                              SizedBox(
                                width: 120,
                                child: Text(
                                  stock['codigo']?.toString() ?? 
                                  stock['tcode']?.toString() ?? 
                                  'N/A',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Descripción
                              SizedBox(
                                width: 250,
                                child: Text(
                                  stock['descripcion']?.toString() ?? 
                                  stock['tdesc']?.toString() ?? 
                                  'N/A',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Totaling
                              SizedBox(
                                width: 90,
                                child: Text(
                                  stock['totaling']?.toString() ?? 'N/A',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[700],
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Total Venta
                              SizedBox(
                                width: 100,
                                child: Text(
                                  stock['totalventa']?.toString() ?? 'N/A',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[700],
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Today Ingreso
                              SizedBox(
                                width: 110,
                                child: Text(
                                  stock['todayingreso']?.toString() ?? 'N/A',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[700],
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Today Venta
                              SizedBox(
                                width: 100,
                                child: Text(
                                  stock['todayventa']?.toString() ?? 'N/A',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[700],
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Total Reservado
                              SizedBox(
                                width: 120,
                                child: Text(
                                  stock['totalreservado']?.toString() ?? 'N/A',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[700],
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Cnt Offset
                              SizedBox(
                                width: 100,
                                child: Text(
                                  stock['cntoffset']?.toString() ?? 'N/A',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[700],
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Stock Real
                              SizedBox(
                                width: 100,
                                child: Text(
                                  stock['stockreal']?.toString() ?? 
                                  stock['stockreal3']?.toString() ?? 
                                  'N/A',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Porcentaje
                              SizedBox(
                                width: 100,
                                child: Text(
                                  stock['porcentaje']?.toString() ?? 'N/A',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[700],
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // First Date
                              SizedBox(
                                width: 100,
                                child: Text(
                                  stock['first_date']?.toString() ?? 'N/A',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Last Date
                              SizedBox(
                                width: 100,
                                child: Text(
                                  stock['last_date']?.toString() ?? 'N/A',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Precio 1-5
                              SizedBox(
                                width: 90,
                                child: Text(
                                  stock['pre1']?.toString() ?? 'N/A',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[700],
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 90,
                                child: Text(
                                  stock['pre2']?.toString() ?? 'N/A',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[700],
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 90,
                                child: Text(
                                  stock['pre3']?.toString() ?? 'N/A',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[700],
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 90,
                                child: Text(
                                  stock['pre4']?.toString() ?? 'N/A',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[700],
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 90,
                                child: Text(
                                  stock['pre5']?.toString() ?? 'N/A',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[700],
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Sucursal
                              SizedBox(
                                width: 90,
                                child: Text(
                                  stock['sucursal']?.toString() ?? 'N/A',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[700],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // ID Codigo1
                              SizedBox(
                                width: 100,
                                child: Text(
                                  stock['id_codigo1']?.toString() ?? 'N/A',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[700],
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Stocks 칼럼 헤더 빌드
  static Widget buildHeader({
    required ReportType reportType,
    required String? sortColumn,
    required bool sortAscending,
    required Function(String, bool) onSort,
    required Color reportColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: reportColor.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[400]!,
            width: 2,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildSortableHeader('codigo', 'Codigo', 120, sortColumn, sortAscending, onSort, reportColor),
            const SizedBox(width: 8),
            _buildSortableHeader('descripcion', 'Descripción', 250, sortColumn, sortAscending, onSort, reportColor),
            const SizedBox(width: 8),
            _buildSortableHeader('totaling', 'Totaling', 90, sortColumn, sortAscending, onSort, reportColor),
            const SizedBox(width: 8),
            _buildSortableHeader('totalventa', 'Total Venta', 100, sortColumn, sortAscending, onSort, reportColor),
            const SizedBox(width: 8),
            _buildSortableHeader('todayingreso', 'Today Ingreso', 110, sortColumn, sortAscending, onSort, reportColor),
            const SizedBox(width: 8),
            _buildSortableHeader('todayventa', 'Today Venta', 100, sortColumn, sortAscending, onSort, reportColor),
            const SizedBox(width: 8),
            _buildSortableHeader('totalreservado', 'Total Reservado', 120, sortColumn, sortAscending, onSort, reportColor),
            const SizedBox(width: 8),
            _buildSortableHeader('cntoffset', 'Cnt Offset', 100, sortColumn, sortAscending, onSort, reportColor),
            const SizedBox(width: 8),
            _buildSortableHeader('stockreal', 'Stock Real', 100, sortColumn, sortAscending, onSort, reportColor),
            const SizedBox(width: 8),
            _buildSortableHeader('porcentaje', 'Porcentaje', 100, sortColumn, sortAscending, onSort, reportColor),
            const SizedBox(width: 8),
            _buildSortableHeader('first_date', 'First Date', 100, sortColumn, sortAscending, onSort, reportColor),
            const SizedBox(width: 8),
            _buildSortableHeader('last_date', 'Last Date', 100, sortColumn, sortAscending, onSort, reportColor),
            const SizedBox(width: 8),
            _buildSortableHeader('pre1', 'Precio 1', 90, sortColumn, sortAscending, onSort, reportColor),
            const SizedBox(width: 8),
            _buildSortableHeader('pre2', 'Precio 2', 90, sortColumn, sortAscending, onSort, reportColor),
            const SizedBox(width: 8),
            _buildSortableHeader('pre3', 'Precio 3', 90, sortColumn, sortAscending, onSort, reportColor),
            const SizedBox(width: 8),
            _buildSortableHeader('pre4', 'Precio 4', 90, sortColumn, sortAscending, onSort, reportColor),
            const SizedBox(width: 8),
            _buildSortableHeader('pre5', 'Precio 5', 90, sortColumn, sortAscending, onSort, reportColor),
            const SizedBox(width: 8),
            _buildSortableHeader('sucursal', 'Sucursal', 90, sortColumn, sortAscending, onSort, reportColor),
            const SizedBox(width: 8),
            _buildSortableHeader('id_codigo1', 'ID Codigo1', 100, sortColumn, sortAscending, onSort, reportColor),
          ],
        ),
      ),
    );
  }

  static Widget _buildSortableHeader(
    String columnKey,
    String displayName,
    double width,
    String? sortColumn,
    bool sortAscending,
    Function(String, bool) onSort,
    Color reportColor,
  ) {
    final isSorted = sortColumn == columnKey;
    
    return InkWell(
      onTap: () {
        if (isSorted) {
          onSort(columnKey, !sortAscending);
        } else {
          onSort(columnKey, true);
        }
      },
      child: SizedBox(
        width: width,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              displayName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isSorted ? reportColor : Colors.black87,
              ),
            ),
            if (isSorted)
              Icon(
                sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 16,
                color: reportColor,
              ),
          ],
        ),
      ),
    );
  }

  /// Stocks Vista 타입 표시
  static Widget buildViewType({
    required Map<String, dynamic>? data,
    required String? selectedSucursal,
    required Function(String?) onSucursalChanged,
    required Color reportColor,
  }) {
    if (data == null) {
      return const SizedBox.shrink();
    }
    
    // 새로운 응답 형식: filters 객체가 최상위에 있음
    // 기존 형식 지원: data['filters'] 또는 최상위 bcolorview
    Map<String, dynamic>? filters;
    if (data.containsKey('filters') && data['filters'] is Map) {
      filters = data['filters'] as Map<String, dynamic>;
    }
    
    // bcolorview 확인 (filters 객체 안 또는 최상위)
    dynamic bcolorview;
    if (filters != null && filters.containsKey('bcolorview')) {
      bcolorview = filters['bcolorview'];
    } else if (data.containsKey('bcolorview')) {
      bcolorview = data['bcolorview'];
    } else {
      return const SizedBox.shrink();
    }
    final viewType = (bcolorview == true) ? 'Vista Resumida' : 'VistaD';
    
    // Vista Detallada일 때만 sucursal 필터 표시
    final bool showSucursalFilter = (bcolorview == false);
    List<String>? sucursales;
    
    if (showSucursalFilter && data.containsKey('data') && data['data'] is List) {
      final dataList = data['data'] as List;
      final sucursalSet = <String>{};
      
      for (var item in dataList) {
        if (item is Map<String, dynamic> && item.containsKey('sucursal')) {
          final sucursal = item['sucursal']?.toString();
          if (sucursal != null && sucursal.isNotEmpty) {
            sucursalSet.add(sucursal);
          }
        }
      }
      
      sucursales = sucursalSet.toList()..sort((a, b) {
        final aNum = int.tryParse(a) ?? 0;
        final bNum = int.tryParse(b) ?? 0;
        return aNum.compareTo(bNum);
      });
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      decoration: BoxDecoration(
        color: reportColor.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            bcolorview == true ? Icons.view_compact : Icons.view_list,
            color: reportColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            viewType,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: reportColor,
            ),
          ),
          // Sucursal이 2개 이상일 때만 콤보박스 표시
          if (showSucursalFilter && sucursales != null && sucursales.length > 1)
            ...[
              const SizedBox(width: 16),
              Container(
                constraints: const BoxConstraints(minWidth: 100),
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: DropdownButton<String?>(
                  value: selectedSucursal,
                  hint: const Text('모두', style: TextStyle(fontSize: 12)),
                  underline: const SizedBox(),
                  isDense: true,
                  icon: Icon(Icons.arrow_drop_down, color: reportColor, size: 20),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('모두', style: TextStyle(fontSize: 12)),
                    ),
                    ...sucursales.map((sucursal) {
                      return DropdownMenuItem<String?>(
                        value: sucursal,
                        child: Text(sucursal, style: const TextStyle(fontSize: 12)),
                      );
                    }).toList(),
                  ],
                  onChanged: onSucursalChanged,
                ),
              ),
            ],
          // summary 정보 표시 (새로운 응답 형식: summary 객체 또는 최상위 total_items)
          if (data.containsKey('summary') || data.containsKey('total_items'))
            const Spacer(),
          if (data.containsKey('summary') && data['summary'] is Map)
            Text(
              'Total: ${(data['summary'] as Map)['total_items'] ?? 0}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            )
          else if (data.containsKey('total_items'))
            Text(
              'Total: ${data['total_items'] ?? 0}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
        ],
      ),
    );
  }
}

